// lib/screens/urge_surfing_screen.dart
// Urge Surfing & Impulse Management Screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/urge_surfing_provider.dart';
import '../models/urge_surfing.dart';
import '../theme/app_spacing.dart';

class UrgeSurfingScreen extends StatefulWidget {
  const UrgeSurfingScreen({super.key});

  @override
  State<UrgeSurfingScreen> createState() => _UrgeSurfingScreenState();
}

class _UrgeSurfingScreenState extends State<UrgeSurfingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UrgeSurfingProvider>().loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urge Surfing'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Consumer<UrgeSurfingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = provider.sortedSessions;
          final stats = provider.stats;

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 100,
            ),
            children: [
              // Clinical disclaimer
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Evidence-based impulse management (MBRP/MB-EAT/DBT) - Not a substitute for professional mental health care',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats card
              if (stats.totalSessions > 0) ...[
                _buildStatsCard(context, stats),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Main header
              Text(
                'Manage Urges & Cravings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose a technique when you feel an urge',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick techniques section
              Text(
                'Quick Interventions (1-3 min)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTechniqueCard(
                context,
                technique: UrgeTechnique.stopTechnique,
                color: Colors.red,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTechniqueCard(
                context,
                technique: UrgeTechnique.threeMinuteBreathing,
                color: Colors.blue,
              ),
              const SizedBox(height: AppSpacing.md),

              // Deeper techniques section
              Text(
                'Deeper Practices (5+ min)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTechniqueCard(
                context,
                technique: UrgeTechnique.urgeSurfing,
                color: Colors.teal,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTechniqueCard(
                context,
                technique: UrgeTechnique.rain,
                color: Colors.purple,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTechniqueCard(
                context,
                technique: UrgeTechnique.urgeDelay,
                color: Colors.orange,
              ),

              // Recent sessions
              if (sessions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Recent Sessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ...sessions.take(10).map((session) => _SessionCard(session: session)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, UrgeSurfingStats stats) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Your Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  value: stats.totalSessions.toString(),
                  label: 'Sessions',
                ),
                _buildStatItem(
                  context,
                  value: '${stats.successRate.round()}%',
                  label: 'Success Rate',
                ),
                _buildStatItem(
                  context,
                  value: stats.averageReduction.toStringAsFixed(1),
                  label: 'Avg Reduction',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context,
      {required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildTechniqueCard(
    BuildContext context, {
    required UrgeTechnique technique,
    required Color color,
  }) {
    return Card(
      child: InkWell(
        onTap: () => _startTechnique(technique),
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
                child: Center(
                  child: Text(
                    technique.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technique.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      technique.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '~${(technique.defaultDurationSeconds / 60).round()} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_outline, color: color, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _startTechnique(UrgeTechnique technique) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrgeSurfingSessionScreen(technique: technique),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.waves, color: Colors.teal),
            SizedBox(width: AppSpacing.sm),
            Text('Urge Surfing'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Urges are like waves - they rise, peak, and fall. You can ride them out without acting.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.md),
              Text('Evidence-based for:'),
              SizedBox(height: AppSpacing.sm),
              Text('- Binge eating (MB-EAT)'),
              Text('- Substance cravings (MBRP)'),
              Text('- Impulse purchases'),
              Text('- Anger outbursts'),
              Text('- Digital addiction'),
              SizedBox(height: AppSpacing.md),
              Text(
                'Research: Bowen et al. (2014) JAMA Psychiatry, Kristeller & Wolever (2011), DBT distress tolerance skills.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final UrgeSurfingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final wasSuccessful = !session.didActOnUrge;
    final intensityChange = session.intensityChange;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: wasSuccessful
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
              ),
              child: Icon(
                wasSuccessful ? Icons.check : Icons.replay,
                color: wasSuccessful ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.technique.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (session.urgeCategory != null)
                    Text(
                      session.urgeCategory!.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM d').format(session.completedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (intensityChange != null && intensityChange > 0)
                  Text(
                    '-$intensityChange intensity',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Guided session screen
class UrgeSurfingSessionScreen extends StatefulWidget {
  final UrgeTechnique technique;

  const UrgeSurfingSessionScreen({super.key, required this.technique});

  @override
  State<UrgeSurfingSessionScreen> createState() => _UrgeSurfingSessionScreenState();
}

class _UrgeSurfingSessionScreenState extends State<UrgeSurfingSessionScreen> {
  int _urgeIntensityBefore = 5;
  int? _urgeIntensityAfter;
  UrgeCategory? _urgeCategory;
  UrgeTrigger? _trigger;
  bool _isInSession = false;
  bool _isComplete = false;
  int _currentStepIndex = 0;
  int _stepSecondsRemaining = 0;
  int _totalElapsedSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    final steps = widget.technique.steps;
    setState(() {
      _isInSession = true;
      _currentStepIndex = 0;
      _stepSecondsRemaining = steps.first.durationSeconds;
      _totalElapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalElapsedSeconds++;
        _stepSecondsRemaining--;

        if (_stepSecondsRemaining <= 0) {
          // Move to next step
          if (_currentStepIndex < steps.length - 1) {
            _currentStepIndex++;
            _stepSecondsRemaining = steps[_currentStepIndex].durationSeconds;
          } else {
            // Session complete
            _completeSession();
          }
        }
      });
    });
  }

  void _completeSession() {
    _timer?.cancel();
    setState(() {
      _isInSession = false;
      _isComplete = true;
    });
  }

  void _skipStep() {
    final steps = widget.technique.steps;
    if (_currentStepIndex < steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _stepSecondsRemaining = steps[_currentStepIndex].durationSeconds;
      });
    } else {
      _completeSession();
    }
  }

  void _endEarly() {
    _timer?.cancel();
    setState(() {
      _isInSession = false;
      _isComplete = true;
    });
  }

  Future<void> _saveSession(bool didActOnUrge) async {
    final session = UrgeSurfingSession(
      technique: widget.technique,
      urgeCategory: _urgeCategory,
      trigger: _trigger,
      urgeIntensityBefore: _urgeIntensityBefore,
      urgeIntensityAfter: _urgeIntensityAfter,
      didActOnUrge: didActOnUrge,
      durationSeconds: _totalElapsedSeconds,
    );

    await context.read<UrgeSurfingProvider>().addSession(session);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(didActOnUrge
              ? 'Session saved. Keep practicing - it gets easier!'
              : 'Great job! You rode out the urge.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.technique.displayName),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isInSession
            ? _buildSessionView()
            : _isComplete
                ? _buildCompletionView()
                : _buildSetupView(),
      ),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technique info
          Center(
            child: Column(
              children: [
                Text(
                  widget.technique.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.technique.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    widget.technique.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Urge intensity
          Text(
            'How strong is the urge? (1-10)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildIntensitySlider(_urgeIntensityBefore, (value) {
            setState(() => _urgeIntensityBefore = value);
          }),
          const SizedBox(height: AppSpacing.lg),

          // Urge category (optional)
          Text(
            'What type of urge? (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: UrgeCategory.values
                .where((c) => c != UrgeCategory.other)
                .map((category) => ChoiceChip(
                      label: Text('${category.emoji} ${category.displayName}'),
                      selected: _urgeCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _urgeCategory = selected ? category : null;
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Trigger (optional)
          Text(
            'What triggered it? (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: UrgeTrigger.values
                .where((t) => t != UrgeTrigger.other)
                .map((trigger) => ChoiceChip(
                      label: Text('${trigger.emoji} ${trigger.displayName}'),
                      selected: _trigger == trigger,
                      onSelected: (selected) {
                        setState(() {
                          _trigger = selected ? trigger : null;
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Start button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Technique'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildIntensitySlider(int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: value.toString(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mild', style: Theme.of(context).textTheme.bodySmall),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getIntensityColor(value),
                  ),
            ),
            Text('Overwhelming', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Color _getIntensityColor(int value) {
    if (value <= 3) return Colors.green;
    if (value <= 6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSessionView() {
    final steps = widget.technique.steps;
    final currentStep = steps[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / steps.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Step indicator
                  Text(
                    'Step ${_currentStepIndex + 1} of ${steps.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Step title
                  Text(
                    currentStep.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Timer
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Center(
                      child: Text(
                        '$_stepSecondsRemaining',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Instruction
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      key: ValueKey(_currentStepIndex),
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        currentStep.instruction,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _endEarly,
                    child: const Text('End Early'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _skipStep,
                    child: Text(_currentStepIndex < steps.length - 1
                        ? 'Next Step'
                        : 'Finish'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(
            Icons.waves,
            size: 80,
            color: Colors.teal,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You Rode the Wave',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The urge has passed or weakened',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Post-session intensity
          Text(
            'How strong is the urge now? (1-10)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildIntensitySlider(_urgeIntensityAfter ?? _urgeIntensityBefore, (value) {
            setState(() => _urgeIntensityAfter = value);
          }),

          if (_urgeIntensityAfter != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildIntensityChangeIndicator(),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Outcome buttons
          Text(
            'Did you act on the urge?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _saveSession(true),
                  icon: const Icon(Icons.replay),
                  label: const Text('Yes, I gave in'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _saveSession(false),
                  icon: const Icon(Icons.check),
                  label: const Text('No, I resisted'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Discard session'),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityChangeIndicator() {
    final change = _urgeIntensityBefore - _urgeIntensityAfter!;
    final color = change > 0
        ? Colors.green
        : change < 0
            ? Colors.red
            : Colors.grey;
    final text = change > 0
        ? 'Intensity decreased by $change'
        : change < 0
            ? 'Intensity increased by ${-change}'
            : 'Intensity stayed the same';
    final icon = change > 0
        ? Icons.trending_down
        : change < 0
            ? Icons.trending_up
            : Icons.trending_flat;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
