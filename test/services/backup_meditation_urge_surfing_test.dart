import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/services/storage_service.dart';
import '../helpers/backup_test_helper.dart';

/// Tests for backup/restore of meditation and urge surfing sessions
///
/// Ensures that meditation and urge surfing data (which is stored as raw JSON,
/// not model objects) is properly exported and imported during backup/restore.
///
/// This test was added after discovering a bug where BackupService was calling
/// .toJson() on data that was already JSON Maps, causing:
/// "NoSuchMethodError: Class '_Map<String, dynamic>' has no instance method 'toJson'"
///
/// REGRESSION TEST: Prevents future breakage of backup export for these data types.
void main() {
  group('Backup/Restore - Meditation & Urge Surfing Sessions', () {
    late BackupService backupService;
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      backupService = BackupService();
      storage = StorageService();
    });

    group('Meditation Sessions', () {
      test('meditation sessions should survive backup/restore round-trip', () async {
        // Arrange: Save meditation sessions (as raw JSON, how the provider stores them)
        final meditationSessions = [
          {
            'id': 'med-1',
            'type': 'breathAwareness',
            'durationSeconds': 300,
            'plannedDurationSeconds': 300,
            'moodBefore': 3,
            'moodAfter': 4,
            'wasInterrupted': false,
            'timestamp': '2025-11-25T10:00:00Z',
          },
          {
            'id': 'med-2',
            'type': 'bodyScans',
            'durationSeconds': 600,
            'plannedDurationSeconds': 600,
            'moodBefore': 2,
            'moodAfter': 4,
            'wasInterrupted': false,
            'timestamp': '2025-11-25T11:00:00Z',
          },
        ];
        await storage.saveMeditationSessions(meditationSessions);

        // Act: Export backup (this is where the bug occurred - calling .toJson() on Maps)
        final backupJson = await backupService.createBackupJson();

        // Clear storage (simulate restore to new device)
        await storage.clearAll();
        expect(await storage.getMeditationSessions(), isNull);

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: Meditation sessions restored
        expect(importResult.success, isTrue, reason: importResult.message);
        final restoredSessions = await storage.getMeditationSessions();
        expect(restoredSessions, isNotNull);
        expect(restoredSessions!.length, equals(2));
        expect(restoredSessions[0]['id'], equals('med-1'));
        expect(restoredSessions[1]['id'], equals('med-2'));
      });

      test('export should not fail when meditation data is already JSON Maps', () async {
        // This specifically tests the regression: data is stored as Maps, not model objects
        final rawJsonMaps = [
          {'id': 'test-1', 'type': 'breathAwareness', 'durationSeconds': 60},
        ];
        await storage.saveMeditationSessions(rawJsonMaps);

        // This should NOT throw "NoSuchMethodError: has no instance method 'toJson'"
        expect(
          () async => await backupService.createBackupJson(),
          returnsNormally,
        );
      });

      test('empty meditation sessions should not break backup/restore', () async {
        // Arrange: No meditation data
        await storage.saveMeditationSessions([]);

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: Import succeeds
        expect(importResult.success, isTrue, reason: importResult.message);
      });

      test('backup statistics should include meditation session count', () async {
        // Arrange: Save meditation sessions
        await storage.saveMeditationSessions([
          {'id': 'med-1', 'type': 'breathAwareness'},
          {'id': 'med-2', 'type': 'bodyScans'},
          {'id': 'med-3', 'type': 'lovingKindness'},
        ]);

        // Act: Create backup
        final backupJson = await backupService.createBackupJson();

        // Parse and verify statistics
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
        final stats = backupData['statistics'] as Map<String, dynamic>;

        // Assert: Statistics include meditation count
        expect(stats['totalMeditationSessions'], equals(3));
      });
    });

    group('Urge Surfing Sessions', () {
      test('urge surfing sessions should survive backup/restore round-trip', () async {
        // Arrange: Save urge surfing sessions (as raw JSON)
        final urgeSurfingSessions = [
          {
            'id': 'urge-1',
            'technique': 'urgeSurfing',
            'urgeCategory': 'eating',
            'triggers': ['hungry', 'stressed'],
            'intensityBefore': 8,
            'intensityAfter': 3,
            'didActOnUrge': false,
            'timestamp': '2025-11-25T14:00:00Z',
          },
          {
            'id': 'urge-2',
            'technique': 'stopTechnique',
            'urgeCategory': 'digital',
            'triggers': ['bored'],
            'intensityBefore': 6,
            'intensityAfter': 2,
            'didActOnUrge': false,
            'timestamp': '2025-11-25T15:00:00Z',
          },
        ];
        await storage.saveUrgeSurfingSessions(urgeSurfingSessions);

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Clear storage
        await storage.clearAll();
        expect(await storage.getUrgeSurfingSessions(), isNull);

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: Urge surfing sessions restored
        expect(importResult.success, isTrue, reason: importResult.message);
        final restoredSessions = await storage.getUrgeSurfingSessions();
        expect(restoredSessions, isNotNull);
        expect(restoredSessions!.length, equals(2));
        expect(restoredSessions[0]['id'], equals('urge-1'));
        expect(restoredSessions[0]['didActOnUrge'], equals(false));
        expect(restoredSessions[1]['id'], equals('urge-2'));
      });

      test('export should not fail when urge surfing data is already JSON Maps', () async {
        // This specifically tests the regression
        final rawJsonMaps = [
          {'id': 'test-1', 'technique': 'urgeSurfing', 'intensityBefore': 5},
        ];
        await storage.saveUrgeSurfingSessions(rawJsonMaps);

        // This should NOT throw "NoSuchMethodError: has no instance method 'toJson'"
        expect(
          () async => await backupService.createBackupJson(),
          returnsNormally,
        );
      });

      test('empty urge surfing sessions should not break backup/restore', () async {
        // Arrange: No urge surfing data
        await storage.saveUrgeSurfingSessions([]);

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: Import succeeds
        expect(importResult.success, isTrue, reason: importResult.message);
      });

      test('backup statistics should include urge surfing session count', () async {
        // Arrange: Save urge surfing sessions
        await storage.saveUrgeSurfingSessions([
          {'id': 'urge-1', 'technique': 'urgeSurfing'},
          {'id': 'urge-2', 'technique': 'rain'},
        ]);

        // Act: Create backup
        final backupJson = await backupService.createBackupJson();

        // Parse and verify statistics
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
        final stats = backupData['statistics'] as Map<String, dynamic>;

        // Assert: Statistics include urge surfing count
        expect(stats['totalUrgeSurfingSessions'], equals(2));
      });
    });

    group('Combined Backup/Restore', () {
      test('all meditation and urge surfing data should survive backup/restore together', () async {
        // Arrange: Save both types of data
        final meditationSessions = [
          {'id': 'med-1', 'type': 'breathAwareness', 'durationSeconds': 300},
        ];
        final urgeSurfingSessions = [
          {'id': 'urge-1', 'technique': 'urgeSurfing', 'intensityBefore': 7},
        ];

        await storage.saveMeditationSessions(meditationSessions);
        await storage.saveUrgeSurfingSessions(urgeSurfingSessions);

        // Act: Export backup
        final backupJson = await backupService.createBackupJson();

        // Clear storage
        await storage.clearAll();

        // Restore from backup
        final importResult = await backupService.importBackupFromJson(backupJson);

        // Assert: All data restored
        expect(importResult.success, isTrue, reason: importResult.message);

        final restoredMeditation = await storage.getMeditationSessions();
        final restoredUrgeSurfing = await storage.getUrgeSurfingSessions();

        expect(restoredMeditation, isNotNull);
        expect(restoredMeditation!.length, equals(1));
        expect(restoredMeditation[0]['id'], equals('med-1'));

        expect(restoredUrgeSurfing, isNotNull);
        expect(restoredUrgeSurfing!.length, equals(1));
        expect(restoredUrgeSurfing[0]['id'], equals('urge-1'));
      });

      test('backup JSON should contain meditation and urge surfing data fields', () async {
        // Arrange
        await storage.saveMeditationSessions([{'id': 'med-1'}]);
        await storage.saveUrgeSurfingSessions([{'id': 'urge-1'}]);

        // Act
        final backupJson = await backupService.createBackupJson();
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

        // Assert: Backup contains the data fields
        expect(backupData.containsKey('meditation_sessions'), isTrue);
        expect(backupData.containsKey('urge_surfing_sessions'), isTrue);

        // Verify data is properly encoded (as JSON strings, not raw objects)
        final meditationData = jsonDecode(backupData['meditation_sessions'] as String);
        final urgeSurfingData = jsonDecode(backupData['urge_surfing_sessions'] as String);

        expect(meditationData, isList);
        expect(urgeSurfingData, isList);
        expect((meditationData as List).first['id'], equals('med-1'));
        expect((urgeSurfingData as List).first['id'], equals('urge-1'));
      });
    });

    group('Regression Tests', () {
      test('REGRESSION: createBackupJson should not call toJson on raw Map data', () async {
        // This is the exact scenario that caused the bug:
        // StorageService.getMeditationSessions() returns List<dynamic> of Maps
        // BackupService was incorrectly calling .map((m) => m.toJson())

        // Save data as the provider does (raw Maps)
        await storage.saveMeditationSessions([
          {
            'id': 'session-1',
            'type': 'breathAwareness',
            'durationSeconds': 300,
            'plannedDurationSeconds': 300,
            'moodBefore': 3,
            'moodAfter': 4,
            'wasInterrupted': false,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]);

        await storage.saveUrgeSurfingSessions([
          {
            'id': 'urge-session-1',
            'technique': 'urgeSurfing',
            'urgeCategory': 'eating',
            'triggers': ['hungry'],
            'intensityBefore': 7,
            'intensityAfter': 3,
            'didActOnUrge': false,
            'durationSeconds': 180,
            'notes': 'Test session',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]);

        // This call would previously throw:
        // "NoSuchMethodError: Class '_Map<String, dynamic>' has no instance method 'toJson'"
        String? backupJson;
        Object? error;

        try {
          backupJson = await backupService.createBackupJson();
        } catch (e) {
          error = e;
        }

        // Assert: No error, backup created successfully
        expect(error, isNull, reason: 'createBackupJson should not throw');
        expect(backupJson, isNotNull);
        expect(backupJson, isNotEmpty);

        // Verify the backup contains valid data
        final backupData = jsonDecode(backupJson!) as Map<String, dynamic>;
        expect(backupData['meditation_sessions'], isNotNull);
        expect(backupData['urge_surfing_sessions'], isNotNull);
      });
    });
  });
}
