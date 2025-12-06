// lib/screens/profile_settings_screen.dart
// Screen for managing user profile settings

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/nutrition_goal_service.dart';
import '../providers/weight_provider.dart';
import '../providers/food_log_provider.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _storage = StorageService();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _userName = '';

  // Height fields
  bool _useMetricHeight = true;
  final _heightCmController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();

  // Gender
  String? _selectedGender;

  // Nutrition goals
  String? _activityLevel;
  final _healthConcernsController = TextEditingController();
  bool _isGeneratingNutritionGoals = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightCmController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _healthConcernsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    // Load user name from dedicated storage key
    final name = await _storage.loadUserName();

    if (name != null) {
      _userName = name;
      _nameController.text = name;
    }

    // Load height and gender from weight provider
    if (!mounted) return;
    final weightProvider = context.read<WeightProvider>();
    final heightCm = weightProvider.height;
    final gender = weightProvider.gender;

    if (heightCm != null) {
      _heightCmController.text = heightCm.toStringAsFixed(0);
      // Also populate imperial fields
      final totalInches = heightCm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      _heightFeetController.text = feet.toString();
      _heightInchesController.text = inches.toString();
    }

    _selectedGender = gender;

    // Load nutrition goal settings
    final foodLogProvider = context.read<FoodLogProvider>();
    final goal = foodLogProvider.goal;
    if (goal != null) {
      _activityLevel = goal.activityLevel;
      if (goal.healthConcerns != null) {
        _healthConcernsController.text = goal.healthConcerns!;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pleaseEnterYourName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newName == _userName) {
      // No change
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to dedicated storage key (consistent with height/gender)
      await _storage.saveUserName(newName);

      setState(() {
        _userName = newName;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.nameUpdatedSuccessfully),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveHeight() async {
    double? heightCm;

    if (_useMetricHeight) {
      heightCm = double.tryParse(_heightCmController.text);
    } else {
      final feet = int.tryParse(_heightFeetController.text) ?? 0;
      final inches = int.tryParse(_heightInchesController.text) ?? 0;
      if (feet > 0 || inches > 0) {
        heightCm = (feet * 12 + inches) * 2.54;
      }
    }

    if (heightCm != null && heightCm > 50 && heightCm < 300) {
      final weightProvider = context.read<WeightProvider>();
      await weightProvider.setHeight(heightCm);

      // Update the other unit's fields
      if (_useMetricHeight) {
        final totalInches = heightCm / 2.54;
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();
        _heightFeetController.text = feet.toString();
        _heightInchesController.text = inches.toString();
      } else {
        _heightCmController.text = heightCm.toStringAsFixed(0);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Height saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (heightCm != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid height'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGender(String? gender) async {
    final weightProvider = context.read<WeightProvider>();
    await weightProvider.setGender(gender);
    setState(() {
      _selectedGender = gender;
    });
  }

  Future<void> _generateNutritionGoals() async {
    setState(() => _isGeneratingNutritionGoals = true);

    try {
      final weightProvider = context.read<WeightProvider>();
      final foodLogProvider = context.read<FoodLogProvider>();
      final nutritionService = NutritionGoalService();

      // Build profile from available data
      final profile = NutritionProfile(
        weightKg: weightProvider.latestEntry?.weightInKg,
        heightCm: weightProvider.height,
        gender: weightProvider.gender,
        activityLevel: _activityLevel,
        weightGoal: weightProvider.goal,
        healthConcerns: _healthConcernsController.text.trim().isNotEmpty
            ? _healthConcernsController.text.trim()
            : null,
      );

      final result = await nutritionService.generateNutritionGoals(profile);

      if (!mounted) return;

      if (result.success) {
        await foodLogProvider.setGoal(result.goal);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nutrition goals generated! ${result.reasoning}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to generate goals'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingNutritionGoals = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Header info
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Profile',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          'Manage your personal information and preferences.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapXl,

          // Name Section
          Text(
            AppStrings.yourName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'This name is used throughout the app to personalize your experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Name input field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: AppStrings.yourName,
              hintText: 'Enter your first name',
              prefixIcon: Icon(Icons.badge),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              // Auto-save on change with debounce could be added here
            },
          ),

          AppSpacing.gapLg,

          // Save button
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveName,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? '${AppStrings.save}...' : AppStrings.saveChanges),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Gender Section
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'Used for more accurate health calculations (BMR, calorie needs)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Gender selection
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment<String?>(
                value: 'male',
                label: Text('Male'),
                icon: Icon(Icons.male),
              ),
              ButtonSegment<String?>(
                value: 'female',
                label: Text('Female'),
                icon: Icon(Icons.female),
              ),
              ButtonSegment<String?>(
                value: null,
                label: Text('Prefer not to say'),
              ),
            ],
            selected: {_selectedGender},
            onSelectionChanged: (Set<String?> selection) {
              _saveGender(selection.first);
            },
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Height Section
          Text(
            'Height',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'Used for BMI calculation and health metrics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Unit toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('cm'),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('ft/in'),
              ),
            ],
            selected: {_useMetricHeight},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _useMetricHeight = selection.first;
              });
            },
          ),

          AppSpacing.gapLg,

          // Height input
          if (_useMetricHeight)
            TextField(
              controller: _heightCmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Height (cm)',
                hintText: 'e.g., 175',
                prefixIcon: Icon(Icons.height),
                suffixText: 'cm',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _saveHeight(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightFeetController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Feet',
                      hintText: '5',
                      suffixText: 'ft',
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _saveHeight(),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: TextField(
                    controller: _heightInchesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Inches',
                      hintText: '10',
                      suffixText: 'in',
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _saveHeight(),
                  ),
                ),
              ],
            ),

          AppSpacing.gapLg,

          // Save height button
          OutlinedButton.icon(
            onPressed: _saveHeight,
            icon: const Icon(Icons.save),
            label: const Text('Save Height'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Nutrition Goals Section
          Text(
            'Nutrition Goals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'Set personalized nutrition targets with AI assistance based on your profile and health concerns.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Activity Level
          Text(
            'Activity Level',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          AppSpacing.gapSm,
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select your activity level',
              prefixIcon: Icon(Icons.directions_run),
            ),
            items: const [
              DropdownMenuItem(
                value: 'sedentary',
                child: Text('Sedentary (little or no exercise)'),
              ),
              DropdownMenuItem(
                value: 'light',
                child: Text('Light (1-3 days/week)'),
              ),
              DropdownMenuItem(
                value: 'moderate',
                child: Text('Moderate (3-5 days/week)'),
              ),
              DropdownMenuItem(
                value: 'active',
                child: Text('Active (6-7 days/week)'),
              ),
              DropdownMenuItem(
                value: 'very_active',
                child: Text('Very Active (physical job)'),
              ),
            ],
            onChanged: (value) {
              setState(() => _activityLevel = value);
            },
          ),

          AppSpacing.gapLg,

          // Health Concerns
          Text(
            'Health Concerns (Optional)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          AppSpacing.gapSm,
          Text(
            'Tell us about any health goals or concerns, and we\'ll adjust your nutrition targets accordingly.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapSm,
          TextField(
            controller: _healthConcernsController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g., "I want to lower triglycerides" or "managing blood pressure"',
              prefixIcon: Icon(Icons.health_and_safety),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),

          AppSpacing.gapLg,

          // Generate Goals Button
          FilledButton.icon(
            onPressed: _isGeneratingNutritionGoals ? null : _generateNutritionGoals,
            icon: _isGeneratingNutritionGoals
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGeneratingNutritionGoals
                ? 'Generating...'
                : 'Generate AI Nutrition Goals'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapLg,

          // Current Goals Display
          Consumer<FoodLogProvider>(
            builder: (context, foodLogProvider, child) {
              final goal = foodLogProvider.goal;
              if (goal == null) {
                return Card(
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        AppSpacing.gapMd,
                        Text(
                          'No nutrition goals set',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        AppSpacing.gapSm,
                        Text(
                          'Use the button above to generate personalized goals based on your profile.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          AppSpacing.gapHorizontalSm,
                          Text(
                            'Current Nutrition Goals',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (goal.isAiGenerated) ...[
                            AppSpacing.gapHorizontalSm,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'AI',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      AppSpacing.gapMd,

                      // Macros
                      _buildGoalRow('Calories', '${goal.targetCalories} kcal'),
                      if (goal.targetProteinGrams != null)
                        _buildGoalRow('Protein', '${goal.targetProteinGrams}g'),
                      if (goal.targetCarbsGrams != null)
                        _buildGoalRow('Carbs', '${goal.targetCarbsGrams}g'),
                      if (goal.targetFatGrams != null)
                        _buildGoalRow('Fat', '${goal.targetFatGrams}g'),

                      // Micronutrients (if set)
                      if (goal.hasMicronutrientTargets) ...[
                        AppSpacing.gapMd,
                        Text(
                          'Micronutrients',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        AppSpacing.gapSm,
                        if (goal.maxSodiumMg != null)
                          _buildGoalRow('Sodium (max)', '${goal.maxSodiumMg}mg'),
                        if (goal.maxSugarGrams != null)
                          _buildGoalRow('Sugar (max)', '${goal.maxSugarGrams}g'),
                        if (goal.minFiberGrams != null)
                          _buildGoalRow('Fiber (min)', '${goal.minFiberGrams}g'),
                        if (goal.maxCholesterolMg != null)
                          _buildGoalRow('Cholesterol (max)', '${goal.maxCholesterolMg}mg'),
                        if (goal.minPotassiumMg != null)
                          _buildGoalRow('Potassium (min)', '${goal.minPotassiumMg}mg'),
                      ],

                      // AI Reasoning
                      if (goal.aiReasoning != null && goal.aiReasoning!.isNotEmpty) ...[
                        AppSpacing.gapMd,
                        Container(
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              AppSpacing.gapHorizontalSm,
                              Expanded(
                                child: Text(
                                  goal.aiReasoning!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // Extra bottom padding for nav bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGoalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
