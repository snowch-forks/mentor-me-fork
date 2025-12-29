// lib/widgets/wellness_menu_widget.dart
// Reusable wellness menu with collapsible sections
// Can be embedded in the home screen or any other screen

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../services/storage_service.dart';
import '../screens/gratitude_journal_screen.dart';
import '../screens/worry_time_screen.dart';
import '../screens/self_compassion_screen.dart';
import '../screens/values_clarification_screen.dart';
import '../screens/implementation_intentions_screen.dart';
import '../screens/behavioral_activation_screen.dart';
import '../screens/assessment_dashboard_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/safety_plan_screen.dart';
import '../screens/crisis_resources_screen.dart';
import '../screens/meditation_screen.dart';
import '../screens/urge_surfing_screen.dart';
import '../screens/digital_wellness_screen.dart';
import '../screens/cognitive_reframing_screen.dart';
import '../screens/grounding_exercise_screen.dart';
import '../screens/worry_decision_tree_screen.dart';
import '../screens/exposure_ladder_screen.dart';
import '../screens/weight_tracking_screen.dart';
import '../screens/food_log_screen.dart';
import '../screens/fasting_screen.dart';
import '../screens/exercise_plans_screen.dart';
import '../screens/medication_screen.dart';
import '../screens/symptom_tracker_screen.dart';
import '../screens/lab_home_screen.dart';

/// Reusable wellness menu widget with collapsible sections
/// Shows the same content as the wellness dashboard, but in a compact format
/// Suitable for embedding in the home screen or other locations
class WellnessMenuWidget extends StatefulWidget {
  /// Whether to show the header and description
  final bool showHeader;

  /// Whether to show the "Help me choose" card
  final bool showHelpMeChoose;

  /// Custom title (default: "Wellness Tools")
  final String? title;

  /// Custom description
  final String? description;

  const WellnessMenuWidget({
    super.key,
    this.showHeader = true,
    this.showHelpMeChoose = false,
    this.title,
    this.description,
  });

  @override
  State<WellnessMenuWidget> createState() => _WellnessMenuWidgetState();
}

class _WellnessMenuWidgetState extends State<WellnessMenuWidget> {
  final _storage = StorageService();

  // Section expansion states - default to collapsed
  // Physical wellness expanded by default (most commonly used)
  bool _clinicalToolsExpanded = false;
  bool _cognitiveExpanded = false;
  bool _wellnessExpanded = false;
  bool _physicalExpanded = true; // Most commonly used
  bool _healthExpanded = false;
  bool _insightsExpanded = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSectionStates();
  }

  Future<void> _loadSectionStates() async {
    final settings = await _storage.loadSettings();

    if (mounted) {
      setState(() {
        // Load saved states, defaulting to collapsed (except physical wellness)
        _clinicalToolsExpanded = settings['home_wellness_clinical_expanded'] as bool? ?? false;
        _cognitiveExpanded = settings['home_wellness_cognitive_expanded'] as bool? ?? false;
        _wellnessExpanded = settings['home_wellness_practices_expanded'] as bool? ?? false;
        _physicalExpanded = settings['home_wellness_physical_expanded'] as bool? ?? true;
        _healthExpanded = settings['home_wellness_health_expanded'] as bool? ?? false;
        _insightsExpanded = settings['home_wellness_insights_expanded'] as bool? ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSectionState(String key, bool expanded) async {
    final settings = await _storage.loadSettings();
    settings[key] = expanded;
    await _storage.saveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional header
        if (widget.showHeader) ...[
          Text(
            widget.title ?? 'Wellness Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (widget.description != null)
            Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            Text(
              'Evidence-based practices for mental health and wellbeing',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          // User hint for collapsible sections
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tap sections below to expand and explore tools',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Crisis Support Section - Always visible, not collapsible
        _buildCrisisSupportSection(),
        const SizedBox(height: AppSpacing.sm),

        // Clinical Tools Section
        _buildCollapsibleSection(
          title: 'Clinical Tools',
          icon: Icons.medical_services_outlined,
          isExpanded: _clinicalToolsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _clinicalToolsExpanded = expanded);
            _saveSectionState('home_wellness_clinical_expanded', expanded);
          },
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.assessment_outlined,
              title: 'Clinical Assessments',
              description: 'Track depression, anxiety, and stress with validated tools',
              color: Colors.teal,
              onTap: () => _navigate(context, const AssessmentDashboardScreen()),
            ),
          ],
        ),

        // Cognitive Techniques Section
        _buildCollapsibleSection(
          title: 'Cognitive Techniques',
          icon: Icons.psychology_outlined,
          isExpanded: _cognitiveExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _cognitiveExpanded = expanded);
            _saveSectionState('home_wellness_cognitive_expanded', expanded);
          },
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.psychology,
              title: 'Cognitive Reframing',
              description: 'Challenge and reframe unhelpful thoughts',
              color: Colors.indigo,
              onTap: () => _navigate(context, const CognitiveReframingScreen()),
              evidenceBase: 'CBT (Cognitive Behavioral Therapy)',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.spa,
              title: '5-4-3-2-1 Grounding',
              description: 'Sensory awareness technique for anxiety and overwhelm',
              color: Colors.teal,
              onTap: () => _navigate(context, const GroundingExerciseScreen()),
              evidenceBase: 'DBT, Mindfulness',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.account_tree,
              title: 'Worry Decision Tree',
              description: 'Work through worries with a guided decision process',
              color: Colors.blue,
              onTap: () => _navigate(context, const WorryDecisionTreeScreen()),
              evidenceBase: 'CBT (Cognitive Behavioral Therapy)',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.stairs,
              title: 'Exposure Ladder',
              description: 'Gradually face fears step by step',
              color: Colors.orange,
              onTap: () => _navigate(context, const ExposureLadderScreen()),
              evidenceBase: 'Exposure Therapy, CBT',
            ),
          ],
        ),

        // Wellness Practices Section
        _buildCollapsibleSection(
          title: 'Wellness Practices',
          icon: Icons.self_improvement_outlined,
          isExpanded: _wellnessExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _wellnessExpanded = expanded);
            _saveSectionState('home_wellness_practices_expanded', expanded);
          },
          itemCount: 9,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.directions_run,
              title: 'Behavioral Activation',
              description: 'Schedule pleasant activities to improve mood',
              color: Colors.green,
              onTap: () => _navigate(context, const BehavioralActivationScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.self_improvement,
              title: 'Mindfulness & Meditation',
              description: 'Breathing exercises, body scan, and guided meditation',
              color: Colors.teal,
              onTap: () => _navigate(context, const MeditationScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.favorite,
              title: 'Gratitude Practice',
              description: 'Three good things journal for positive focus',
              color: Colors.pink,
              onTap: () => _navigate(context, const GratitudeJournalScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.schedule,
              title: 'Worry Time',
              description: 'Contain anxiety with designated worry practice',
              color: Colors.deepPurple,
              onTap: () => _navigate(context, const WorryTimeScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.waves,
              title: 'Urge Surfing',
              description: 'Manage cravings and impulses with mindfulness techniques',
              color: Colors.cyan,
              onTap: () => _navigate(context, const UrgeSurfingScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.phone_android,
              title: 'Digital Wellness',
              description: 'Mindful technology use with intentional unplugging',
              color: Colors.indigo,
              onTap: () => _navigate(context, const DigitalWellnessScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.self_improvement,
              title: 'Self-Compassion',
              description: 'Treat yourself with kindness and reduce self-criticism',
              color: Colors.purple,
              onTap: () => _navigate(context, const SelfCompassionScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.explore,
              title: 'Values Clarification',
              description: 'Identify what matters most and guide meaningful action',
              color: Colors.amber,
              onTap: () => _navigate(context, const ValuesClarificationScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.route,
              title: 'Implementation Intentions',
              description: 'If-then plans to achieve your goals',
              color: Colors.orange,
              onTap: () => _navigate(context, const ImplementationIntentionsScreen()),
            ),
          ],
        ),

        // Physical Wellness Section
        _buildCollapsibleSection(
          title: 'Physical Wellness',
          icon: Icons.fitness_center_outlined,
          isExpanded: _physicalExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _physicalExpanded = expanded);
            _saveSectionState('home_wellness_physical_expanded', expanded);
          },
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.monitor_weight,
              title: 'Weight Tracking',
              description: 'Log weight, set goals, and track your progress over time',
              color: Colors.blue,
              onTap: () => _navigate(context, const WeightTrackingScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.restaurant_menu,
              title: 'Food Log',
              description: 'Track meals with AI-powered nutrition estimation',
              color: Colors.orange,
              onTap: () => _navigate(context, const FoodLogScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.timer_outlined,
              title: 'Fasting Tracker',
              description: 'Track intermittent fasting with protocols and goals',
              color: Colors.deepOrange,
              onTap: () => _navigate(context, const FastingScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.fitness_center,
              title: 'Exercise Tracking',
              description: 'Create workout plans and track your exercise routines',
              color: Colors.orange,
              onTap: () => _navigate(context, const ExercisePlansScreen()),
            ),
          ],
        ),

        // Health Tracking Section
        _buildCollapsibleSection(
          title: 'Health Tracking',
          icon: Icons.healing_outlined,
          isExpanded: _healthExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _healthExpanded = expanded);
            _saveSectionState('home_wellness_health_expanded', expanded);
          },
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.medication,
              title: 'Medication Tracker',
              description: 'Log medications, track adherence, and manage your prescriptions',
              color: Colors.purple,
              onTap: () => _navigate(context, const MedicationScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.healing,
              title: 'Symptom Tracker',
              description: 'Track symptoms, identify triggers, and monitor patterns',
              color: Colors.deepOrange,
              onTap: () => _navigate(context, const SymptomTrackerScreen()),
            ),
          ],
        ),

        // Insights & Progress Section
        _buildCollapsibleSection(
          title: 'Insights & Progress',
          icon: Icons.analytics_outlined,
          isExpanded: _insightsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _insightsExpanded = expanded);
            _saveSectionState('home_wellness_insights_expanded', expanded);
          },
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.analytics_outlined,
              title: 'Analytics & Trends',
              description: 'View your progress, patterns, and wellness insights',
              color: Colors.blueGrey,
              onTap: () => _navigate(context, const AnalyticsScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.science_outlined,
              title: 'Lab',
              description: 'Run personal experiments to discover what works for you',
              color: Colors.deepPurple,
              onTap: () => _navigate(context, const LabHomeScreen()),
            ),
          ],
        ),
      ],
    );
  }

  /// Crisis Support section - always visible, not collapsible for safety
  Widget _buildCrisisSupportSection() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency_outlined,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Crisis Support',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.sos,
              title: 'Get Help Now',
              description: 'Emergency contacts and crisis support hotlines',
              color: Colors.red,
              onTap: () => _navigate(context, const CrisisResourcesScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureCard(
              context,
              icon: Icons.shield_outlined,
              title: 'Safety Plan',
              description: 'Create your personal crisis management plan',
              color: Colors.orange,
              onTap: () => _navigate(context, const SafetyPlanScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<Widget> children,
    int? itemCount,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove the default divider line from ExpansionTile
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (itemCount != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$itemCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    String? evidenceBase,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (evidenceBase != null)
                          Tooltip(
                            message: 'Based on $evidenceBase',
                            child: Icon(
                              Icons.science_outlined,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
