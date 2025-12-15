// lib/screens/experiment_results_screen.dart
// Displays detailed experiment results with visualizations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/experiment.dart';
import '../models/experiment_entry.dart';
import '../providers/experiment_provider.dart';
import '../theme/app_spacing.dart';

class ExperimentResultsScreen extends StatelessWidget {
  final String experimentId;

  const ExperimentResultsScreen({
    super.key,
    required this.experimentId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExperimentProvider>(
      builder: (context, provider, child) {
        final experiment = provider.getExperimentById(experimentId);

        if (experiment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Results')),
            body: const Center(child: Text('Experiment not found')),
          );
        }

        final entries = provider.getEntriesForExperiment(experimentId);
        final results = experiment.results;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Experiment Results'),
          ),
          body: results == null
              ? const Center(child: Text('No results available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCard(experiment: experiment, results: results),
                      const SizedBox(height: AppSpacing.lg),
                      _TimelineChart(
                        entries: entries,
                        experiment: experiment,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ComparisonChart(results: results),
                      const SizedBox(height: AppSpacing.lg),
                      _StatisticsCard(results: results),
                      const SizedBox(height: AppSpacing.lg),
                      _CaveatsCard(results: results),
                      const SizedBox(height: AppSpacing.lg),
                      _SuggestionsCard(results: results),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Experiment experiment;
  final ExperimentResults results;

  const _SummaryCard({
    required this.experiment,
    required this.results,
  });

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

    return Card(
      color: directionColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(directionIcon, color: directionColor, size: 48),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      results.direction.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: directionColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      results.significance.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${results.percentChange >= 0 ? '+' : ''}${results.percentChange.toStringAsFixed(1)}%',
              style: theme.textTheme.displaySmall?.copyWith(
                color: directionColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              results.summaryStatement,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineChart extends StatelessWidget {
  final List<ExperimentEntry> entries;
  final Experiment experiment;

  const _TimelineChart({
    required this.entries,
    required this.experiment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get entries with outcome values
    final validEntries = entries
        .where((e) => e.outcomeValue != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (validEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${experiment.outcomeName} Over Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _LegendItem(
                  color: Colors.blue,
                  label: 'Baseline',
                ),
                const SizedBox(width: AppSpacing.md),
                _LegendItem(
                  color: Colors.green,
                  label: 'Intervention',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 6,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == value.toInt() && value >= 1 && value <= 5) {
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < validEntries.length) {
                            final entry = validEntries[index];
                            // Show every few labels to avoid crowding
                            if (index % (validEntries.length ~/ 5 + 1) == 0) {
                              return Text(
                                '${entry.date.month}/${entry.date.day}',
                                style: theme.textTheme.labelSmall,
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLineData(validEntries, ExperimentPhase.baseline, Colors.blue),
                    _buildLineData(validEntries, ExperimentPhase.intervention, Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(
    List<ExperimentEntry> entries,
    ExperimentPhase phase,
    Color color,
  ) {
    final spots = <FlSpot>[];

    for (int i = 0; i < entries.length; i++) {
      if (entries[i].phase == phase && entries[i].outcomeValue != null) {
        spots.add(FlSpot(i.toDouble(), entries[i].outcomeValue!.toDouble()));
      }
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 0,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _ComparisonChart extends StatelessWidget {
  final ExperimentResults results;

  const _ComparisonChart({required this.results});

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
              'Phase Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: 5.5,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == value.toInt() && value >= 1 && value <= 5) {
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Baseline',
                                  style: theme.textTheme.labelMedium,
                                ),
                              );
                            case 1:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Intervention',
                                  style: theme.textTheme.labelMedium,
                                ),
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _buildBarGroup(0, results.baselineMean, Colors.blue),
                    _buildBarGroup(1, results.interventionMean, Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  label: 'Baseline',
                  value: results.baselineMean.toStringAsFixed(2),
                  subValue: '±${results.baselineStdDev.toStringAsFixed(2)}',
                  color: Colors.blue,
                ),
                _StatColumn(
                  label: 'Intervention',
                  value: results.interventionMean.toStringAsFixed(2),
                  subValue: '±${results.interventionStdDev.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subValue,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final ExperimentResults results;

  const _StatisticsCard({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String effectSizeInterpretation;
    if (results.effectSize.abs() >= 0.8) {
      effectSizeInterpretation = 'Large effect';
    } else if (results.effectSize.abs() >= 0.5) {
      effectSizeInterpretation = 'Medium effect';
    } else if (results.effectSize.abs() >= 0.2) {
      effectSizeInterpretation = 'Small effect';
    } else {
      effectSizeInterpretation = 'Negligible effect';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistical Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StatRow(
              label: 'Effect Size (Cohen\'s d)',
              value: results.effectSize.toStringAsFixed(3),
              subtitle: effectSizeInterpretation,
            ),
            const Divider(),
            _StatRow(
              label: 'Percent Change',
              value: '${results.percentChange >= 0 ? '+' : ''}${results.percentChange.toStringAsFixed(1)}%',
            ),
            const Divider(),
            _StatRow(
              label: 'Confidence Level',
              value: '${(results.confidenceLevel * 100).toInt()}%',
              subtitle: results.significance.description,
            ),
            const Divider(),
            _StatRow(
              label: 'Sample Size',
              value: '${results.baselineN + results.interventionN} entries',
              subtitle: '${results.baselineN} baseline, ${results.interventionN} intervention',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _StatRow({
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaveatsCard extends StatelessWidget {
  final ExperimentResults results;

  const _CaveatsCard({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (results.caveats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Things to Consider',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...results.caveats.map((caveat) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(caveat)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  final ExperimentResults results;

  const _SuggestionsCard({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (results.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'What\'s Next?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...results.suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(suggestion)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
