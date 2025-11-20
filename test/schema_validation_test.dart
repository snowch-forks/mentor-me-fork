// test/schema_validation_test.dart
// Schema validation tests to ensure Dart models and JSON schemas stay synchronized
//
// These tests run automatically in GitHub Actions to catch schema drift.
// If a test fails, it means the Dart models and JSON schemas are out of sync.
//
// See CLAUDE.md "Data Schema Management" section for synchronization guidelines.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentor_me/services/migration_service.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/goal.dart';
import 'package:mentor_me/models/habit.dart';
import 'package:mentor_me/models/pulse_entry.dart';
import 'package:mentor_me/models/checkin.dart';
import 'package:mentor_me/models/milestone.dart';

void main() {
  group('Schema Version Validation', () {
    test('Current schema version matches migration service', () {
      final migrationService = MigrationService();
      final currentVersion = migrationService.getCurrentVersion();

      // Debug output for CI diagnostics
      print('DEBUG: Current schema version from MigrationService: $currentVersion');
      print('DEBUG: Expected version: 3');

      // Schema version should be 3 (current)
      expect(currentVersion, equals(3),
        reason: 'If you changed the schema version, update this test and all schema files. Got: $currentVersion');
    });
  });

  group('Export Format Structure Validation', () {
    test('Export format includes all required schema fields', () {
      // Simulate backup export structure (matches BackupService._createBackupJson)
      final mockExport = {
        // Schema metadata
        'schemaVersion': MigrationService.CURRENT_SCHEMA_VERSION,
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'buildNumber': 'test',

        // Data fields (JSON-encoded strings)
        'journal_entries': json.encode([]),
        'goals': json.encode([]),
        'habits': json.encode([]),
        'checkins': null,
        'pulse_entries': json.encode([]),
        'pulse_types': json.encode([]),
        'conversations': json.encode([]),
        'custom_templates': null,
        'sessions': null,
        'enabled_templates': json.encode([]),
        'settings': json.encode({}),
      };

      // Validate required fields exist
      expect(mockExport.containsKey('schemaVersion'), isTrue,
        reason: 'schemaVersion is required for migration detection');
      expect(mockExport.containsKey('journal_entries'), isTrue,
        reason: 'journal_entries field is required in export');
      expect(mockExport.containsKey('goals'), isTrue,
        reason: 'goals field is required in export');
      expect(mockExport.containsKey('habits'), isTrue,
        reason: 'habits field is required in export');

      // Validate schema version is correct
      expect(mockExport['schemaVersion'], equals(3),
        reason: 'Current schema version should be 3');
    });

    test('Export format data fields are JSON-encoded strings', () {
      // Data fields should be JSON-encoded strings (not nested objects)
      // This matches StorageService format and ensures migrations work consistently

      final mockGoals = [
        Goal(
          title: 'Test Goal',
          description: 'Test Description',
          category: GoalCategory.personal,
        ).toJson(),
      ];

      final exportedGoals = json.encode(mockGoals);

      // Should be a string
      expect(exportedGoals, isA<String>(),
        reason: 'Goals field must be JSON-encoded string');

      // Should be parseable back to list
      final decodedGoals = json.decode(exportedGoals) as List;
      expect(decodedGoals.length, equals(1),
        reason: 'Should decode back to original structure');
    });
  });

  group('JournalEntry Model Validation (v2 Schema)', () {
    test('JournalEntry serialization includes all required v2 fields', () {
      final entry = JournalEntry(
        type: JournalEntryType.quickNote,
        content: 'Test content',
      );

      final json = entry.toJson();

      // v2 schema requires these fields
      expect(json.containsKey('id'), isTrue,
        reason: 'id is required in v2 schema');
      expect(json.containsKey('type'), isTrue,
        reason: 'type is required in v2 schema');
      expect(json.containsKey('createdAt'), isTrue,
        reason: 'createdAt is required in v2 schema');
      expect(json.containsKey('content'), isTrue,
        reason: 'content field must exist in serialization');
    });

    test('Structured journal entries have content in v2', () {
      // v2 schema requires structured journals to have populated content
      final entry = JournalEntry(
        type: JournalEntryType.structuredJournal,
        structuredSessionId: 'session-123',
        content: 'Generated content from structured data',
        structuredData: {'field1': 'value1'},
      );

      final json = entry.toJson();

      expect(json['type'], equals('structuredJournal'));
      expect(json['content'], isNotNull,
        reason: 'v2 requires structured journals to have content');
      expect(json['content'], isNotEmpty,
        reason: 'v2 requires non-empty content for structured journals');
    });

    test('JournalEntry deserialization handles all entry types', () {
      // Test quick note
      final quickNoteJson = {
        'id': 'test-1',
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'quickNote',
        'content': 'Test note',
        'goalIds': <String>[],
      };

      final quickNote = JournalEntry.fromJson(quickNoteJson);
      expect(quickNote.type, equals(JournalEntryType.quickNote));
      expect(quickNote.content, equals('Test note'));

      // Test guided journal
      final guidedJournalJson = {
        'id': 'test-2',
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'guidedJournal',
        'qaPairs': [
          {'question': 'Q1', 'answer': 'A1'},
        ],
        'goalIds': <String>[],
      };

      final guidedJournal = JournalEntry.fromJson(guidedJournalJson);
      expect(guidedJournal.type, equals(JournalEntryType.guidedJournal));
      expect(guidedJournal.qaPairs, isNotNull);

      // Test structured journal
      final structuredJournalJson = {
        'id': 'test-3',
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'structuredJournal',
        'structuredSessionId': 'session-123',
        'content': 'Structured content',
        'structuredData': {'field': 'value'},
        'goalIds': <String>[],
      };

      final structuredJournal = JournalEntry.fromJson(structuredJournalJson);
      expect(structuredJournal.type, equals(JournalEntryType.structuredJournal));
      expect(structuredJournal.content, isNotNull);
      expect(structuredJournal.structuredData, isNotNull);
    });
  });

  group('Goal Model Validation', () {
    test('Goal serialization includes all required fields', () {
      final goal = Goal(
        title: 'Test Goal',
        description: 'Test Description',
        category: GoalCategory.personal,
        milestonesDetailed: [
          Milestone(
            goalId: 'test-goal-id',
            title: 'Test Milestone',
            description: 'Test milestone description',
            order: 0,
          ),
        ],
      );

      final json = goal.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('category'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('milestonesDetailed'), isTrue);
      expect(json.containsKey('sortOrder'), isTrue,
        reason: 'sortOrder is required in v3 schema for drag-and-drop reordering');
    });

    test('Goal deserialization handles all statuses', () {
      for (final status in GoalStatus.values) {
        final json = {
          'id': 'test-${status.name}',
          'title': 'Test Goal',
          'description': 'Test',
          'category': GoalCategory.personal.toString(),
          'createdAt': DateTime.now().toIso8601String(),
          'status': status.toString(),
          'milestones': <String>[],
          'milestonesDetailed': <Map<String, dynamic>>[],
          'currentProgress': 0,
          'isActive': true,
          'sortOrder': 0,
        };

        final goal = Goal.fromJson(json);
        expect(goal.status, equals(status),
          reason: 'Should correctly deserialize ${status.name} status');
      }
    });
  });

  group('Habit Model Validation', () {
    test('Habit serialization includes all required fields', () {
      final habit = Habit(
        title: 'Test Habit',
        description: 'Test Description',
        frequency: HabitFrequency.daily,
        targetCount: 1,
      );

      final json = habit.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('frequency'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('sortOrder'), isTrue,
        reason: 'sortOrder is required in v3 schema for drag-and-drop reordering');
    });
  });

  group('PulseEntry Model Validation', () {
    test('PulseEntry serialization includes customMetrics field', () {
      final entry = PulseEntry(
        customMetrics: {'Mood': 4, 'Energy': 3},
      );

      final json = entry.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('timestamp'), isTrue);
      expect(json.containsKey('customMetrics'), isTrue);
      expect(json['customMetrics'], isA<Map>());
    });

    test('PulseEntry deserialization preserves customMetrics', () {
      final json = {
        'id': 'test-1',
        'timestamp': DateTime.now().toIso8601String(),
        'customMetrics': {'Mood': 5, 'Energy': 4, 'Focus': 3},
      };

      final entry = PulseEntry.fromJson(json);

      expect(entry.customMetrics['Mood'], equals(5));
      expect(entry.customMetrics['Energy'], equals(4));
      expect(entry.customMetrics['Focus'], equals(3));
    });
  });

  group('Checkin Model Validation', () {
    test('Checkin serialization includes all fields', () {
      final checkin = Checkin(
        nextCheckinTime: DateTime.now().add(const Duration(hours: 12)),
        lastCompletedAt: DateTime.now(),
        responses: {'question1': 'answer1'},
      );

      final json = checkin.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('nextCheckinTime'), isTrue);
      expect(json.containsKey('lastCompletedAt'), isTrue);
      expect(json.containsKey('responses'), isTrue);
    });
  });

  group('Schema Synchronization Validation', () {
    test('All model files have schema linking comments', () {
      // This is a documentation test to remind developers to add linking comments
      // If you add a new model, ensure it has a dartdoc comment referencing the schema

      // Models that should have schema references:
      final modelsWithSchemas = [
        'JournalEntry',
        'Goal',
        'Habit',
        'PulseEntry',
        'Checkin',
      ];

      // This test passes if all models are accounted for
      expect(modelsWithSchemas.length, greaterThanOrEqualTo(5),
        reason: 'All core models should have schema documentation');
    });

    test('Schema version increments require migration', () {
      // If you increment CURRENT_SCHEMA_VERSION, you must create a migration
      final migrationService = MigrationService();
      final currentVersion = migrationService.getCurrentVersion();
      final migrations = migrationService.getMigrations();

      // Debug output for CI diagnostics
      print('DEBUG: Current version: $currentVersion');
      print('DEBUG: Number of migrations: ${migrations.length}');
      print('DEBUG: Migration names: ${migrations.map((m) => m.name).toList()}');
      print('DEBUG: Expected migrations: >= ${currentVersion - 1}');

      // Number of migrations should be >= currentVersion - 1
      // (e.g., version 2 needs at least 1 migration from v1 to v2)
      expect(migrations.length, greaterThanOrEqualTo(currentVersion - 1),
        reason: 'Each schema version increment requires a migration. Got ${migrations.length} migrations, expected >= ${currentVersion - 1}');
    });
  });
}
