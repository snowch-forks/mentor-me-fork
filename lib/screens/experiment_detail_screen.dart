// lib/screens/experiment_detail_screen.dart
// Detailed view of an experiment with progress, data entry, and results

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/experiment.dart';
import '../models/experiment_entry.dart';
import '../providers/experiment_provider.dart';
import '../services/experiment_analysis_service.dart';
import '../theme/app_spacing.dart';
import 'daily_experiment_entry_screen.dart';
import 'experiment_results_screen.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final String experimentId;

  const ExperimentDetailScreen({
    super.key,
    required this.experimentId,
  });

  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  final _analysisService = ExperimentAnalysisService();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExperimentProvider>(
      builder: (context, provider, child) {
        final experiment = provider.getExperimentById(widget.experimentId);

        if (experiment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Experiment')),
            body: const Center(
              child: Text('Experiment not found'),
            ),
          );
        }

        final entries = provider.getEntriesForExperiment(widget.experimentId);
        final dataQuality = _analysisService.getDataQuality(experiment, entries);

        return Scaffold(
          appBar: AppBar(
            title: Text(experiment.title),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, experiment),
                itemBuilder: (context) => [
                  if (experiment.status == ExperimentStatus.draft)
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (experiment.status.isRunning)
                    const PopupMenuItem(
                      value: 'abandon',
                      child: ListTile(
                        leading: Icon(Icons.cancel_outlined),
                        title: Text('Abandon Experiment'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'notes',
                    child: ListTile(
                      leading: Icon(Icons.note_add_outlined),
                      title: Text('Add Note'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusHeader(experiment: experiment),
                const SizedBox(height: AppSpacing.lg),
                _HypothesisCard(experiment: experiment),
                const SizedBox(height: AppSpacing.md),
                _DesignCard(experiment: experiment),
                const SizedBox(height: AppSpacing.md),
                _ProgressCard(
                  experiment: experiment,
                  dataQuality: dataQuality,
                ),
                if (entries.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RecentEntriesCard(
                    entries: entries.take(5).toList(),
                    experiment: experiment,
                  ),
                ],
                if (experiment.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _NotesCard(experiment: experiment),
                ],
                if (experiment.status == ExperimentStatus.completed &&
                    experiment.results != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ResultsSummaryCard(
                    experiment: experiment,
                    onViewDetails: () => _navigateToResults(context, experiment),
                  ),
                ],
              ],
            ),
          ),
          floatingActionButton: _buildFAB(context, experiment, dataQuality),
        );
      },
    );
  }

  Widget? _buildFAB(
    BuildContext context,
    Experiment experiment,
    DataQualityMetrics dataQuality,
  ) {
    final theme = Theme.of(context);

    switch (experiment.status) {
      case ExperimentStatus.draft:
        return FloatingActionButton.extended(
          onPressed: () => _startBaseline(context, experiment),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Baseline'),
        );

      case ExperimentStatus.baseline:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'log',
              onPressed: () => _navigateToEntry(context, experiment),
              icon: const Icon(Icons.add),
              label: const Text('Log Today'),
            ),
            if (experiment.canStartIntervention && dataQuality.baselineComplete) ...[
              const SizedBox(height: AppSpacing.sm),
              FloatingActionButton.extended(
                heroTag: 'start',
                onPressed: () => _startIntervention(context, experiment),
                icon: const Icon(Icons.science),
                label: const Text('Start Intervention'),
                backgroundColor: theme.colorScheme.secondary,
              ),
            ],
          ],
        );

      case ExperimentStatus.active:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'log',
              onPressed: () => _navigateToEntry(context, experiment),
              icon: const Icon(Icons.add),
              label: const Text('Log Today'),
            ),
            if (experiment.canComplete && dataQuality.isReadyForAnalysis) ...[
              const SizedBox(height: AppSpacing.sm),
              FloatingActionButton.extended(
                heroTag: 'complete',
                onPressed: () => _completeExperiment(context, experiment),
                icon: const Icon(Icons.check),
                label: const Text('Complete & Analyze'),
                backgroundColor: theme.colorScheme.secondary,
              ),
            ],
          ],
        );

      case ExperimentStatus.completed:
        return FloatingActionButton.extended(
          onPressed: () => _navigateToResults(context, experiment),
          icon: const Icon(Icons.analytics),
          label: const Text('View Results'),
        );

      case ExperimentStatus.abandoned:
        return null;
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Experiment experiment,
  ) {
    switch (action) {
      case 'delete':
        _confirmDelete(context, experiment);
        break;
      case 'abandon':
        _confirmAbandon(context, experiment);
        break;
      case 'notes':
        _addNote(context, experiment);
        break;
    }
  }

  void _confirmDelete(BuildContext context, Experiment experiment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Experiment?'),
        content: Text(
          'Are you sure you want to delete "${experiment.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<ExperimentProvider>().deleteExperiment(experiment.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmAbandon(BuildContext context, Experiment experiment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Experiment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You can always review the data you\'ve collected, but the experiment will be marked as incomplete.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Experiment'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<ExperimentProvider>().abandonExperiment(
                    experiment.id,
                    reason: reasonController.text.isEmpty ? null : reasonController.text,
                  );
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  void _addNote(BuildContext context, Experiment experiment) {
    final noteController = TextEditingController();
    ExperimentNoteType selectedType = ExperimentNoteType.observation;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<ExperimentNoteType>(
                segments: ExperimentNoteType.values.map((type) {
                  return ButtonSegment(
                    value: type,
                    label: Text(type.displayName),
                  );
                }).toList(),
                selected: {selectedType},
                onSelectionChanged: (value) {
                  setState(() => selectedType = value.first);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (noteController.text.trim().isNotEmpty) {
                  final note = ExperimentNote(
                    content: noteController.text.trim(),
                    type: selectedType,
                  );
                  await context.read<ExperimentProvider>().addNote(
                        experiment.id,
                        note,
                      );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _startBaseline(BuildContext context, Experiment experiment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Baseline?'),
        content: Text(
          'You\'ll collect ${experiment.baselineDays} days of data WITHOUT doing the intervention. '
          'This establishes your normal baseline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<ExperimentProvider>().startBaseline(experiment.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Baseline phase started!')),
                );
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _startIntervention(BuildContext context, Experiment experiment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Intervention?'),
        content: Text(
          'Now you\'ll do "${experiment.interventionName}" for ${experiment.interventionDays} days '
          'while continuing to track ${experiment.outcomeName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<ExperimentProvider>().startIntervention(experiment.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Intervention phase started!')),
                );
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeExperiment(BuildContext context, Experiment experiment) async {
    final provider = context.read<ExperimentProvider>();
    final entries = provider.getEntriesForExperiment(experiment.id);

    // Run analysis
    final results = await _analysisService.analyzeExperiment(
      experiment: experiment,
      entries: entries,
    );

    if (results == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough data for analysis. Please add more entries.'),
          ),
        );
      }
      return;
    }

    // Save results and mark complete
    await provider.completeExperiment(experiment.id, results);

    if (context.mounted) {
      // Navigate to results
      _navigateToResults(context, experiment);
    }
  }

  void _navigateToEntry(BuildContext context, Experiment experiment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyExperimentEntryScreen(experimentId: experiment.id),
      ),
    );
  }

  void _navigateToResults(BuildContext context, Experiment experiment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperimentResultsScreen(experimentId: experiment.id),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final Experiment experiment;

  const _StatusHeader({required this.experiment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    String statusMessage;

    switch (experiment.status) {
      case ExperimentStatus.draft:
        statusColor = theme.colorScheme.outline;
        statusMessage = 'Ready to start when you are';
        break;
      case ExperimentStatus.baseline:
        statusColor = Colors.blue;
        final days = experiment.daysRemainingInPhase ?? 0;
        statusMessage = 'Collecting baseline data ($days days remaining)';
        break;
      case ExperimentStatus.active:
        statusColor = Colors.green;
        final days = experiment.daysRemainingInPhase ?? 0;
        statusMessage = 'Testing intervention ($days days remaining)';
        break;
      case ExperimentStatus.completed:
        statusColor = theme.colorScheme.primary;
        statusMessage = 'Experiment complete - results available';
        break;
      case ExperimentStatus.abandoned:
        statusColor = Colors.grey;
        statusMessage = 'Experiment was abandoned';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experiment.status.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  statusMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (experiment.status.isRunning)
            Text(
              '${(experiment.progress * 100).toInt()}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _HypothesisCard extends StatelessWidget {
  final Experiment experiment;

  const _HypothesisCard({required this.experiment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Hypothesis',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              experiment.hypothesis,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final Experiment experiment;

  const _DesignCard({required this.experiment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experiment Design',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DesignRow(
              icon: Icons.play_arrow,
              label: 'Intervention',
              value: experiment.interventionName,
              subtitle: experiment.interventionDescription,
            ),
            const Divider(height: AppSpacing.lg),
            _DesignRow(
              icon: Icons.bar_chart,
              label: 'Outcome',
              value: experiment.outcomeName,
              subtitle: experiment.pulseTypeName != null
                  ? 'Linked to Pulse: ${experiment.pulseTypeName}'
                  : '1-5 manual rating',
            ),
            const Divider(height: AppSpacing.lg),
            _DesignRow(
              icon: Icons.calendar_today,
              label: 'Duration',
              value: '${experiment.totalDays} days total',
              subtitle:
                  '${experiment.baselineDays} baseline + ${experiment.interventionDays} intervention',
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _DesignRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Experiment experiment;
  final DataQualityMetrics dataQuality;

  const _ProgressCard({
    required this.experiment,
    required this.dataQuality,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dataQuality.qualityRating,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProgressRow(
              label: 'Baseline entries',
              current: dataQuality.baselineEntries,
              target: dataQuality.minimumRequired,
              progress: dataQuality.baselineProgress,
              color: Colors.blue,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProgressRow(
              label: 'Intervention entries',
              current: dataQuality.interventionEntries,
              target: dataQuality.minimumRequired,
              progress: dataQuality.interventionProgress,
              color: Colors.green,
            ),
            if (!dataQuality.isReadyForAnalysis) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Need at least ${dataQuality.minimumRequired} entries in each phase for analysis',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final double progress;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              '$current / $target',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: current >= target ? color : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _RecentEntriesCard extends StatelessWidget {
  final List<ExperimentEntry> entries;
  final Experiment experiment;

  const _RecentEntriesCard({
    required this.entries,
    required this.experiment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Entries',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...entries.map((entry) => _EntryRow(entry: entry)),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final ExperimentEntry entry;

  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: entry.phase == ExperimentPhase.baseline
                  ? Colors.blue
                  : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.dateDisplay,
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (entry.outcomeValue != null) ...[
            Icon(
              Icons.star,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.outcomeValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (entry.hasConfoundingFactors)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(
                Icons.warning_amber,
                size: 16,
                color: Colors.orange,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final Experiment experiment;

  const _NotesCard({required this.experiment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...experiment.notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.type.emoji),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.content,
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              _formatDate(note.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _ResultsSummaryCard extends StatelessWidget {
  final Experiment experiment;
  final VoidCallback onViewDetails;

  const _ResultsSummaryCard({
    required this.experiment,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = experiment.results!;

    Color directionColor;
    IconData directionIcon;

    switch (results.direction) {
      case EffectDirection.improved:
        directionColor = Colors.green;
        directionIcon = Icons.trending_up;
        break;
      case EffectDirection.declined:
        directionColor = Colors.red;
        directionIcon = Icons.trending_down;
        break;
      case EffectDirection.noChange:
        directionColor = Colors.grey;
        directionIcon = Icons.trending_flat;
        break;
    }

    return Card(
      color: directionColor.withOpacity(0.1),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(directionIcon, color: directionColor, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      results.direction.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: directionColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${results.percentChange >= 0 ? '+' : ''}${results.percentChange.toStringAsFixed(1)}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: directionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                results.summaryStatement,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Full Analysis'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
