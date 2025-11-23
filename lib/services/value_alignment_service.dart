import '../models/goal.dart';
import '../models/values_and_smart_goals.dart';

/// Service for detecting alignment between goals and personal values
///
/// Uses keyword matching and goal category analysis to suggest
/// which values a goal might serve
class ValueAlignmentService {
  /// Detect which values align with a given goal
  ///
  /// Analyzes goal title, description, and category to find matching values
  /// Returns list of value IDs that likely align with this goal
  List<String> detectAlignment({
    required String goalTitle,
    required String goalDescription,
    required GoalCategory goalCategory,
    required List<PersonalValue> userValues,
  }) {
    if (userValues.isEmpty) return [];

    final matchingValueIds = <String>{};
    final searchText = '${goalTitle.toLowerCase()} ${goalDescription.toLowerCase()}';

    // Category-to-domain mapping
    final categoryDomainMap = {
      GoalCategory.health: ValueDomain.health,
      GoalCategory.fitness: ValueDomain.health,
      GoalCategory.career: ValueDomain.work,
      GoalCategory.learning: ValueDomain.work,
      GoalCategory.relationships: ValueDomain.relationships,
      GoalCategory.personal: ValueDomain.personalGrowth,
    };

    // First pass: Match by category
    final primaryDomain = categoryDomainMap[goalCategory];
    if (primaryDomain != null) {
      for (final value in userValues) {
        if (value.domain == primaryDomain) {
          matchingValueIds.add(value.id);
        }
      }
    }

    // Second pass: Keyword matching for more nuanced alignment
    final domainKeywords = {
      ValueDomain.relationships: [
        'family',
        'friend',
        'partner',
        'relationship',
        'connection',
        'parent',
        'child',
        'spouse',
        'social',
      ],
      ValueDomain.work: [
        'career',
        'job',
        'work',
        'business',
        'professional',
        'skill',
        'learn',
        'education',
        'study',
        'course',
      ],
      ValueDomain.health: [
        'health',
        'fitness',
        'exercise',
        'workout',
        'nutrition',
        'sleep',
        'wellbeing',
        'meditation',
        'yoga',
        'mental health',
        'therapy',
      ],
      ValueDomain.personalGrowth: [
        'growth',
        'develop',
        'improve',
        'creative',
        'art',
        'music',
        'writing',
        'spiritua',
        'mindful',
        'self-aware',
        'authentic',
      ],
      ValueDomain.leisure: [
        'hobby',
        'fun',
        'play',
        'recreation',
        'travel',
        'adventure',
        'explore',
        'enjoy',
        'relax',
      ],
      ValueDomain.community: [
        'community',
        'volunteer',
        'help',
        'contribute',
        'activism',
        'environment',
        'society',
        'citizen',
      ],
    };

    // Check each value against keywords
    for (final value in userValues) {
      final keywords = domainKeywords[value.domain] ?? [];

      // Check if any keyword appears in goal text
      for (final keyword in keywords) {
        if (searchText.contains(keyword.toLowerCase())) {
          matchingValueIds.add(value.id);
          break; // Found a match for this value, move to next value
        }
      }

      // Also check if value statement appears in goal text
      if (searchText.contains(value.statement.toLowerCase())) {
        matchingValueIds.add(value.id);
      }
    }

    return matchingValueIds.toList();
  }

  /// Get suggested message for value alignment
  ///
  /// Returns a user-friendly message explaining the alignment
  String getAlignmentMessage({
    required List<PersonalValue> alignedValues,
    required String goalTitle,
  }) {
    if (alignedValues.isEmpty) {
      return 'This goal is meaningful to you. Let\'s make it happen!';
    }

    if (alignedValues.length == 1) {
      final value = alignedValues.first;
      return '${value.domain.emoji} This goal aligns with your value: ${value.statement}\n\n'
          'Goals aligned with your values are 3x more likely to succeed.\n\n'
          'This feels meaningful to you. Let\'s make it happen!';
    }

    // Multiple values
    final valueList = alignedValues
        .map((v) => '${v.domain.emoji} ${v.statement}')
        .join('\n• ');

    return 'This goal aligns with multiple values:\n• $valueList\n\n'
        'Goals aligned with your values are 3x more likely to succeed.\n\n'
        'This feels meaningful to you. Let\'s make it happen!';
  }

  /// Detect values drift (values with no recent goal activity)
  ///
  /// Returns list of values that need attention
  List<ValueDriftAlert> detectValuesDrift({
    required List<PersonalValue> userValues,
    required List<Goal> allGoals,
    int daysSinceActivity = 14,
  }) {
    final alerts = <ValueDriftAlert>[];

    for (final value in userValues) {
      // Skip low-importance values (< 5)
      if (value.importanceRating < 5) continue;

      // Find goals linked to this value
      final linkedGoals = allGoals.where((goal) {
        return goal.linkedValueIds != null &&
            goal.linkedValueIds!.contains(value.id);
      }).toList();

      if (linkedGoals.isEmpty) {
        // No goals for this value at all
        alerts.add(ValueDriftAlert(
          value: value,
          type: DriftType.noGoals,
          message: 'You haven\'t set any goals for ${value.statement} yet.',
          severity: value.importanceRating >= 8 ? 'high' : 'medium',
        ));
      } else {
        // Check if any goals are active and have recent activity
        final activeGoals = linkedGoals.where((g) => g.status == GoalStatus.active).toList();

        if (activeGoals.isEmpty) {
          // All goals are backlog/completed/abandoned
          alerts.add(ValueDriftAlert(
            value: value,
            type: DriftType.noActiveGoals,
            message: 'You haven\'t worked on ${value.statement} in a while. Move a goal to active?',
            severity: 'medium',
          ));
        } else {
          // Check for recent progress (goal updated in last N days)
          // Note: This would require tracking lastUpdatedAt on goals
          // For now, skip this check
        }
      }
    }

    // Sort by importance rating (highest first)
    alerts.sort((a, b) => b.value.importanceRating.compareTo(a.value.importanceRating));

    return alerts;
  }
}

/// Represents a values drift alert
class ValueDriftAlert {
  final PersonalValue value;
  final DriftType type;
  final String message;
  final String severity; // 'low', 'medium', 'high'

  ValueDriftAlert({
    required this.value,
    required this.type,
    required this.message,
    required this.severity,
  });
}

enum DriftType {
  noGoals,        // Value has no goals at all
  noActiveGoals,  // Value has goals but none are active
  noRecentProgress, // Value has active goals but no recent updates
}
