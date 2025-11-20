import 'dart:convert';
import 'package:mentor_me/migrations/migration.dart';
import 'package:mentor_me/services/debug_service.dart';

/// Migration: Add sortOrder field to goals and habits
///
/// Version 2 did not have sortOrder field for goals and habits.
/// Version 3 requires sortOrder for drag-and-drop reordering.
///
/// This migration:
/// - Adds sortOrder field to all goals (grouped by status)
/// - Adds sortOrder field to all habits (grouped by status)
/// - sortOrder is assigned based on current order (0, 1, 2, etc.)
class V2ToV3AddSortOrderMigration extends Migration {
  final _debug = DebugService();

  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get name => 'v2_to_v3_add_sort_order';

  @override
  String get description =>
      'Add sortOrder field to goals and habits for drag-and-drop reordering';

  @override
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> data) async {
    try {
      await _debug.info(
        'Migration',
        'Starting $name migration',
      );

      bool anyChanges = false;

      // Migrate goals
      final goalsJson = data['goals'] as String?;
      if (goalsJson != null && goalsJson.isNotEmpty && goalsJson != '[]') {
        final List<dynamic> goals = jsonDecode(goalsJson);
        if (_addSortOrderToGoals(goals)) {
          data['goals'] = jsonEncode(goals);
          anyChanges = true;
          await _debug.info(
            'Migration',
            'Added sortOrder to ${goals.length} goals',
          );
        }
      }

      // Migrate habits
      final habitsJson = data['habits'] as String?;
      if (habitsJson != null && habitsJson.isNotEmpty && habitsJson != '[]') {
        final List<dynamic> habits = jsonDecode(habitsJson);
        if (_addSortOrderToHabits(habits)) {
          data['habits'] = jsonEncode(habits);
          anyChanges = true;
          await _debug.info(
            'Migration',
            'Added sortOrder to ${habits.length} habits',
          );
        }
      }

      // Update schema version
      data['schemaVersion'] = 3;

      if (anyChanges) {
        await _debug.info(
          'Migration',
          'Successfully completed $name migration',
        );
      } else {
        await _debug.info(
          'Migration',
          'No goals or habits to migrate',
        );
      }

      return data;
    } catch (e, stackTrace) {
      await _debug.error(
        'Migration',
        'Failed to run $name migration',
        stackTrace: stackTrace.toString(),
      );
      // Return original data on error
      return data;
    }
  }

  /// Add sortOrder to goals, grouped by status
  bool _addSortOrderToGoals(List<dynamic> goals) {
    if (goals.isEmpty) return false;

    // Group goals by status
    final Map<String, List<dynamic>> goalsByStatus = {};

    for (final goal in goals) {
      final status = goal['status'] as String? ?? 'GoalStatus.active';

      // Skip if already has sortOrder
      if (goal['sortOrder'] != null) continue;

      if (!goalsByStatus.containsKey(status)) {
        goalsByStatus[status] = [];
      }
      goalsByStatus[status]!.add(goal);
    }

    // Assign sortOrder within each status
    bool anyChanges = false;
    for (final statusGoals in goalsByStatus.values) {
      for (int i = 0; i < statusGoals.length; i++) {
        if (statusGoals[i]['sortOrder'] == null) {
          statusGoals[i]['sortOrder'] = i;
          anyChanges = true;
        }
      }
    }

    return anyChanges;
  }

  /// Add sortOrder to habits, grouped by status
  bool _addSortOrderToHabits(List<dynamic> habits) {
    if (habits.isEmpty) return false;

    // Group habits by status
    final Map<String, List<dynamic>> habitsByStatus = {};

    for (final habit in habits) {
      final status = habit['status'] as String? ?? 'HabitStatus.active';

      // Skip if already has sortOrder
      if (habit['sortOrder'] != null) continue;

      if (!habitsByStatus.containsKey(status)) {
        habitsByStatus[status] = [];
      }
      habitsByStatus[status]!.add(habit);
    }

    // Assign sortOrder within each status
    bool anyChanges = false;
    for (final statusHabits in habitsByStatus.values) {
      for (int i = 0; i < statusHabits.length; i++) {
        if (statusHabits[i]['sortOrder'] == null) {
          statusHabits[i]['sortOrder'] = i;
          anyChanges = true;
        }
      }
    }

    return anyChanges;
  }
}
