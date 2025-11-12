import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../widgets/add_goal_dialog.dart';
import '../widgets/goal_detail_sheet.dart';
import '../constants/app_strings.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final allGoals = goalProvider.goals;

    // Separate goals by status
    final activeGoals = allGoals.where((g) => g.status == GoalStatus.active).toList();
    final backlogGoals = allGoals.where((g) => g.status == GoalStatus.backlog).toList();
    final completedGoals = allGoals.where((g) => g.status == GoalStatus.completed).toList();

    // Calculate stats
    final avgProgress = activeGoals.isNotEmpty
        ? activeGoals.map((g) => g.currentProgress).reduce((a, b) => a + b) ~/ activeGoals.length
        : 0;
    final onTrack = activeGoals.where((g) => g.currentProgress >= 25).length;

    return Scaffold(
      body: goalProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : allGoals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noActiveGoalsYet,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.startByCreatingYourFirstGoal,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary card (for active goals only)
                    if (activeGoals.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(
                                context,
                                Icons.track_changes,
                                '$onTrack',
                                AppStrings.onTrack,
                                Colors.green,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.trending_up,
                                '$avgProgress%',
                                AppStrings.avgProgress,
                                Theme.of(context).colorScheme.primary,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.flag,
                                '${activeGoals.length}',
                                AppStrings.active,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Active Goals section (max 2)
                    Row(
                      children: [
                        Text(
                          AppStrings.activeGoals,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${activeGoals.length}/2',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.focusOnActiveGoals,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (activeGoals.isEmpty)
                      Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppStrings.noActiveGoalsAddOrMove,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      )
                    else
                      ...activeGoals.map((goal) => _buildGoalCard(context, goal)),

                    const SizedBox(height: 24),

                    // Backlog section
                    if (backlogGoals.isNotEmpty) ...[
                      Text(
                        AppStrings.backlog,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.goalsYourePlanningLater,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...backlogGoals.map((goal) => _buildGoalCard(context, goal)),
                      const SizedBox(height: 24),
                    ],

                    // Completed section (collapsible)
                    if (completedGoals.isNotEmpty) ...[
                      ExpansionTile(
                        title: Text(
                          AppStrings.completedCount(completedGoals.length),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        initiallyExpanded: false,
                        children: completedGoals.map((goal) => _buildGoalCard(context, goal)).toList(),
                      ),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddGoalDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(AppStrings.add + ' ' + AppStrings.goal),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final daysUntilDeadline = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : null;
    final isUrgent = daysUntilDeadline != null && daysUntilDeadline <= 7 && daysUntilDeadline >= 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => GoalDetailSheet(goal: goal),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getCategoryIcon(goal.category),
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              goal.category.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getProgressColor(goal.currentProgress).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getProgressColor(goal.currentProgress).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${goal.currentProgress}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getProgressColor(goal.currentProgress),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.currentProgress / 100,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(goal.currentProgress)),
                ),
              ),

              if (goal.targetDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? Colors.red.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: isUrgent ? Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isUrgent ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${AppStrings.targetDate}: ${_formatDate(goal.targetDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isUrgent ? Colors.red : Colors.grey,
                              fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                            ),
                      ),
                      if (isUrgent) ...[
                        const SizedBox(width: 6),
                        Text(
                          '($daysUntilDeadline ${daysUntilDeadline == 1 ? AppStrings.dayRemaining : AppStrings.daysRemaining})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(GoalCategory category) {
    switch (category) {
      case GoalCategory.personal:
        return Icons.person;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.health:
        return Icons.favorite;
      case GoalCategory.fitness:
        return Icons.fitness_center;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.learning:
        return Icons.school;
      case GoalCategory.relationships:
        return Icons.people;
      case GoalCategory.other:
        return Icons.star;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress < 25) return Colors.red;
    if (progress < 50) return Colors.orange;
    if (progress < 75) return Colors.blue;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
