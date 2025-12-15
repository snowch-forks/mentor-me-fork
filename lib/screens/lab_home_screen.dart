// lib/screens/lab_home_screen.dart
// Main screen for the Lab feature - hypothesis testing

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/experiment.dart';
import '../providers/experiment_provider.dart';
import '../theme/app_spacing.dart';
import 'create_experiment_screen.dart';
import 'experiment_detail_screen.dart';

class LabHomeScreen extends StatefulWidget {
  const LabHomeScreen({super.key});

  @override
  State<LabHomeScreen> createState() => _LabHomeScreenState();
}

class _LabHomeScreenState extends State<LabHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Drafts'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showLabInfo(context),
            tooltip: 'About Lab',
          ),
        ],
      ),
      body: Consumer<ExperimentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildExperimentList(
                context,
                provider.activeExperiments,
                emptyMessage: 'No active experiments',
                emptySubtitle: 'Start a new experiment to test your hypothesis',
                showNewButton: true,
              ),
              _buildExperimentList(
                context,
                provider.completedExperiments,
                emptyMessage: 'No completed experiments',
                emptySubtitle: 'Complete an experiment to see results here',
              ),
              _buildExperimentList(
                context,
                provider.draftExperiments,
                emptyMessage: 'No draft experiments',
                emptySubtitle: 'Create a draft to plan your next experiment',
                showNewButton: true,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateExperiment(context),
        icon: const Icon(Icons.science),
        label: const Text('New Experiment'),
      ),
    );
  }

  Widget _buildExperimentList(
    BuildContext context,
    List<Experiment> experiments, {
    required String emptyMessage,
    required String emptySubtitle,
    bool showNewButton = false,
  }) {
    if (experiments.isEmpty) {
      return _buildEmptyState(
        context,
        emptyMessage,
        emptySubtitle,
        showNewButton,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: 100,
      ),
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        return _ExperimentCard(
          experiment: experiments[index],
          onTap: () => _navigateToExperimentDetail(context, experiments[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message,
    String subtitle,
    bool showNewButton,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (showNewButton) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => _navigateToCreateExperiment(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Experiment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToCreateExperiment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateExperimentScreen(),
      ),
    );
  }

  void _navigateToExperimentDetail(BuildContext context, Experiment experiment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperimentDetailScreen(experimentId: experiment.id),
      ),
    );
  }

  void _showLabInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science),
            SizedBox(width: AppSpacing.sm),
            Text('About Lab'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lab helps you scientifically test what works for you through personal experiments (N-of-1 trials).',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: AppSpacing.md),
              _InfoSection(
                title: 'How it works',
                items: [
                  '1. Create a hypothesis (e.g., "Morning exercise improves my focus")',
                  '2. Define your intervention (what you\'ll do) and outcome (what you\'ll measure)',
                  '3. Collect baseline data for 7 days (no intervention)',
                  '4. Apply the intervention for 14 days while tracking',
                  '5. See your personalized results and insights',
                ],
              ),
              SizedBox(height: AppSpacing.md),
              _InfoSection(
                title: 'Tips for good experiments',
                items: [
                  'Change only one thing at a time',
                  'Be consistent with timing and measurement',
                  'Note external factors that might affect results',
                  'Complete the full experiment before drawing conclusions',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(item, style: theme.textTheme.bodySmall),
            )),
      ],
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  final Experiment experiment;
  final VoidCallback onTap;

  const _ExperimentCard({
    required this.experiment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(status: experiment.status),
                  const Spacer(),
                  if (experiment.status.isRunning) ...[
                    _ProgressIndicator(experiment: experiment),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                experiment.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                experiment.hypothesis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.play_arrow,
                    label: experiment.interventionName,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _InfoChip(
                    icon: Icons.bar_chart,
                    label: experiment.outcomeName,
                  ),
                ],
              ),
              if (experiment.status == ExperimentStatus.completed &&
                  experiment.results != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _ResultsSummary(results: experiment.results!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ExperimentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ExperimentStatus.draft:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        break;
      case ExperimentStatus.baseline:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case ExperimentStatus.active:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case ExperimentStatus.completed:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case ExperimentStatus.abandoned:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final Experiment experiment;

  const _ProgressIndicator({required this.experiment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = experiment.progress;
    final daysRemaining = experiment.daysRemainingInPhase;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: progress,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (daysRemaining != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '($daysRemaining days left)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  final ExperimentResults results;

  const _ResultsSummary({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: directionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: directionColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(directionIcon, color: directionColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  results.direction.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: directionColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  results.significance.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${results.percentChange >= 0 ? '+' : ''}${results.percentChange.toStringAsFixed(1)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: directionColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
