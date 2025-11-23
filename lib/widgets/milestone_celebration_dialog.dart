import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/goal.dart';
import '../models/milestone.dart';

/// Celebration dialog shown when user completes a milestone
///
/// Provides dopamine hit through:
/// - Visual celebration (animated checkmark, gradient background)
/// - Progress summary (milestone completion status)
/// - Encouragement message
/// - Share functionality (optional)
class MilestoneCelebrationDialog extends StatefulWidget {
  final Goal goal;
  final Milestone completedMilestone;

  const MilestoneCelebrationDialog({
    super.key,
    required this.goal,
    required this.completedMilestone,
  });

  /// Show the celebration dialog
  static Future<void> show({
    required BuildContext context,
    required Goal goal,
    required Milestone completedMilestone,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneCelebrationDialog(
        goal: goal,
        completedMilestone: completedMilestone,
      ),
    );
  }

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState
    extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation for checkmark (bounce effect)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Fade animation for content
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Rotation animation for sparkles
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount =
        widget.goal.milestonesDetailed.where((m) => m.isCompleted).length;
    final totalCount = widget.goal.milestonesDetailed.length;
    final isGoalComplete = completedCount == totalCount;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.tertiaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            // Animated sparkles
            ..._buildSparkles(),

            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated checkmark
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Celebration message
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          '🎉 Milestone Achieved!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.completedMilestone.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEncouragementMessage(completedCount, totalCount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer
                                .withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress summary
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.goal.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                '$completedCount/$totalCount',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: completedCount / totalCount,
                              minHeight: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Milestone list (up to 5 most recent)
                          ...widget.goal.milestonesDetailed
                              .take(5)
                              .map((m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          m.isCompleted
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 20,
                                          color: m.isCompleted
                                              ? Colors.green
                                              : theme.colorScheme.onPrimaryContainer
                                                  .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            m.title,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: m.isCompleted
                                                  ? theme.colorScheme
                                                      .onPrimaryContainer
                                                  : theme.colorScheme
                                                      .onPrimaryContainer
                                                      .withValues(alpha: 0.7),
                                              decoration: m.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),),

                          if (widget.goal.milestonesDetailed.length > 5) ...[
                            Text(
                              '+ ${widget.goal.milestonesDetailed.length - 5} more',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        if (isGoalComplete) ...[
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.celebration),
                            label: const Text('Goal Complete!'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ] else ...[
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Keep Going!'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Implement share functionality
                            // Use screenshot package to capture dialog
                            // Share via share_plus
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Progress'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build animated sparkle decorations
  List<Widget> _buildSparkles() {
    final sparkles = <Widget>[];
    final positions = [
      const Offset(30, 50),
      const Offset(350, 80),
      const Offset(50, 450),
      const Offset(320, 420),
      const Offset(180, 30),
    ];

    for (int i = 0; i < positions.length; i++) {
      sparkles.add(
        Positioned(
          left: positions[i].dx,
          top: positions[i].dy,
          child: RotationTransition(
            turns: _rotationAnimation,
            child: Icon(
              Icons.auto_awesome,
              size: 24 + (i * 4).toDouble(),
              color: Colors.amber.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return sparkles;
  }

  /// Generate encouragement message based on progress
  String _getEncouragementMessage(int completed, int total) {
    if (completed == total) {
      return 'Amazing! You\'ve completed all milestones. Time to celebrate! 🎊';
    }

    final remaining = total - completed;
    final progressPercent = ((completed / total) * 100).round();

    if (progressPercent >= 75) {
      return 'You\'re so close! Only $remaining milestone${remaining > 1 ? 's' : ''} to go!';
    } else if (progressPercent >= 50) {
      return 'Great progress! You\'re over halfway there!';
    } else if (progressPercent >= 25) {
      return 'You\'re building momentum! Keep it up!';
    } else {
      return 'Fantastic start! Every step counts!';
    }
  }
}
