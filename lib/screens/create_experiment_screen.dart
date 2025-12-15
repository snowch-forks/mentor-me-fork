// lib/screens/create_experiment_screen.dart
// Wizard for creating new experiments in the Lab

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/experiment.dart';
import '../models/habit.dart';
import '../providers/experiment_provider.dart';
import '../providers/pulse_type_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/goal_provider.dart';
import '../theme/app_spacing.dart';

class CreateExperimentScreen extends StatefulWidget {
  const CreateExperimentScreen({super.key});

  @override
  State<CreateExperimentScreen> createState() => _CreateExperimentScreenState();
}

class _CreateExperimentScreenState extends State<CreateExperimentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final _titleController = TextEditingController();
  final _hypothesisController = TextEditingController();
  final _interventionNameController = TextEditingController();
  final _interventionDescController = TextEditingController();
  final _outcomeNameController = TextEditingController();

  String? _selectedPulseTypeName;
  String? _linkedHabitId;
  String? _linkedGoalId;
  int _baselineDays = 7;
  int _interventionDays = 14;

  // Example experiments for inspiration
  static const List<Map<String, String>> _examples = [
    {
      'title': 'Morning Exercise & Focus',
      'hypothesis': 'Morning exercise improves my focus throughout the day',
      'intervention': '30 minutes of exercise before 9am',
      'outcome': 'Focus',
    },
    {
      'title': 'Sleep & Energy',
      'hypothesis': 'Going to bed by 10pm increases my energy levels',
      'intervention': 'In bed by 10pm',
      'outcome': 'Energy',
    },
    {
      'title': 'Meditation & Stress',
      'hypothesis': '10 minutes of daily meditation reduces my stress',
      'intervention': '10-minute morning meditation',
      'outcome': 'Stress',
    },
    {
      'title': 'No Caffeine After Noon',
      'hypothesis': 'Avoiding caffeine after noon improves my sleep quality',
      'intervention': 'No caffeine after 12pm',
      'outcome': 'Sleep Quality',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _hypothesisController.dispose();
    _interventionNameController.dispose();
    _interventionDescController.dispose();
    _outcomeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildHypothesisPage(context),
                  _buildInterventionPage(context),
                  _buildOutcomePage(context),
                  _buildReviewPage(context),
                ],
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Your Hypothesis';
      case 1:
        return 'The Intervention';
      case 2:
        return 'What to Measure';
      case 3:
        return 'Review & Create';
      default:
        return 'New Experiment';
    }
  }

  Widget _buildHypothesisPage(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to test?',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A good hypothesis is specific and testable.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Experiment Title',
              hintText: 'e.g., Morning Exercise & Focus',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _hypothesisController,
            decoration: const InputDecoration(
              labelText: 'Your Hypothesis',
              hintText: 'e.g., Morning exercise improves my focus throughout the day',
              border: OutlineInputBorder(),
              helperText: 'What do you believe will happen?',
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your hypothesis';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Need inspiration?',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _examples.map((example) {
              return ActionChip(
                label: Text(example['title']!),
                onPressed: () {
                  setState(() {
                    _titleController.text = example['title']!;
                    _hypothesisController.text = example['hypothesis']!;
                    _interventionNameController.text = example['intervention']!;
                    _outcomeNameController.text = example['outcome']!;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionPage(BuildContext context) {
    final theme = Theme.of(context);
    final habitProvider = context.watch<HabitProvider>();
    final activeHabits = habitProvider.habits
        .where((h) => h.status == HabitStatus.active)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What will you do?',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The intervention is the action you\'ll take during the experiment phase.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _interventionNameController,
            decoration: const InputDecoration(
              labelText: 'Intervention Name',
              hintText: 'e.g., 30 minutes of morning exercise',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe your intervention';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _interventionDescController,
            decoration: const InputDecoration(
              labelText: 'Details (Optional)',
              hintText: 'Add any specific details about how you\'ll do this...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          if (activeHabits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Link to existing habit?',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Track your intervention using an existing habit for easier logging.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              value: _linkedHabitId,
              decoration: const InputDecoration(
                labelText: 'Linked Habit',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None (I\'ll track manually)'),
                ),
                ...activeHabits.map((habit) => DropdownMenuItem(
                      value: habit.id,
                      child: Text(habit.title),
                    )),
              ],
              onChanged: (value) => setState(() => _linkedHabitId = value),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Experiment Duration',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DurationSelector(
            label: 'Baseline (no intervention)',
            value: _baselineDays,
            onChanged: (value) => setState(() => _baselineDays = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DurationSelector(
            label: 'Intervention phase',
            value: _interventionDays,
            onChanged: (value) => setState(() => _interventionDays = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total duration: ${_baselineDays + _interventionDays} days',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomePage(BuildContext context) {
    final theme = Theme.of(context);
    final pulseTypeProvider = context.watch<PulseTypeProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final activeGoals = goalProvider.activeGoals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What will you measure?',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose what you\'ll track to see if the intervention works.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _outcomeNameController,
            decoration: const InputDecoration(
              labelText: 'Outcome Name',
              hintText: 'e.g., Focus, Energy, Mood',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please name your outcome measure';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Link to Pulse metric?',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Use an existing Pulse metric for automatic data collection.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('Manual Entry'),
                selected: _selectedPulseTypeName == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPulseTypeName = null);
                  }
                },
              ),
              ...pulseTypeProvider.activeTypes.map((type) => ChoiceChip(
                    label: Text(type.name),
                    selected: _selectedPulseTypeName == type.name,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPulseTypeName = selected ? type.name : null;
                        if (selected) {
                          _outcomeNameController.text = type.name;
                        }
                      });
                    },
                  )),
            ],
          ),
          if (activeGoals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Link to goal? (Optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Connect this experiment to a goal you\'re working on.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              value: _linkedGoalId,
              decoration: const InputDecoration(
                labelText: 'Linked Goal',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                ...activeGoals.map((goal) => DropdownMenuItem(
                      value: goal.id,
                      child: Text(goal.title, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) => setState(() => _linkedGoalId = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewPage(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Experiment',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReviewCard(
            title: 'Hypothesis',
            content: _hypothesisController.text,
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewCard(
            title: 'Intervention',
            content: _interventionNameController.text,
            subtitle: _interventionDescController.text.isEmpty
                ? null
                : _interventionDescController.text,
            icon: Icons.play_arrow,
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewCard(
            title: 'Outcome',
            content: _outcomeNameController.text,
            subtitle: _selectedPulseTypeName != null
                ? 'Linked to Pulse: $_selectedPulseTypeName'
                : 'Manual tracking (1-5 scale)',
            icon: Icons.bar_chart,
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewCard(
            title: 'Duration',
            content: '${_baselineDays + _interventionDays} days total',
            subtitle: '$_baselineDays days baseline, $_interventionDays days intervention',
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Your experiment will start in draft mode. You can begin the baseline phase whenever you\'re ready.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentPage > 0)
              TextButton.icon(
                onPressed: _goToPreviousPage,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              )
            else
              const SizedBox(width: 100),
            const Spacer(),
            if (_currentPage < 3)
              FilledButton.icon(
                onPressed: _goToNextPage,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              )
            else
              FilledButton.icon(
                onPressed: _createExperiment,
                icon: const Icon(Icons.science),
                label: const Text('Create'),
              ),
          ],
        ),
      ),
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextPage() {
    // Validate current page before moving
    if (_currentPage == 0) {
      if (_titleController.text.trim().isEmpty ||
          _hypothesisController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
          ),
        );
        return;
      }
    } else if (_currentPage == 1) {
      if (_interventionNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please describe your intervention'),
          ),
        );
        return;
      }
    } else if (_currentPage == 2) {
      if (_outcomeNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please name what you\'ll measure'),
          ),
        );
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createExperiment() async {
    if (!_formKey.currentState!.validate()) return;

    final experiment = Experiment(
      title: _titleController.text.trim(),
      hypothesis: _hypothesisController.text.trim(),
      interventionName: _interventionNameController.text.trim(),
      interventionDescription: _interventionDescController.text.trim().isEmpty
          ? null
          : _interventionDescController.text.trim(),
      linkedHabitId: _linkedHabitId,
      outcomeName: _outcomeNameController.text.trim(),
      pulseTypeName: _selectedPulseTypeName,
      baselineDays: _baselineDays,
      interventionDays: _interventionDays,
      linkedGoalId: _linkedGoalId,
      status: ExperimentStatus.draft,
    );

    await context.read<ExperimentProvider>().addExperiment(experiment);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created experiment: ${experiment.title}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigation to detail would go here
            },
          ),
        ),
      );
    }
  }

  void _confirmExit(BuildContext context) {
    if (_titleController.text.isEmpty &&
        _hypothesisController.text.isEmpty &&
        _interventionNameController.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard experiment?'),
        content: const Text('Your changes will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 3 ? () => onChanged(value - 1) : null,
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$value days',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < 30 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final String content;
  final String? subtitle;
  final IconData icon;

  const _ReviewCard({
    required this.title,
    required this.content,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
