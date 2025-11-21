import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/services/backup_service.dart';
import 'package:mentor_me/services/storage_service.dart';
import '../helpers/backup_test_helper.dart';

/// Tests for backup/restore of templates and sessions
///
/// Ensures that custom templates, sessions, and enabled templates
/// are properly exported and imported during backup/restore operations.
///
/// This test was added after discovering a critical bug where these
/// fields were exported but NOT imported, causing data loss.
void main() {
  group('Backup/Restore - Templates & Sessions', () {
    late BackupService backupService;
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      backupService = BackupService();
      storage = StorageService();
    });

    test('custom templates should survive backup/restore round-trip', () async {
      // Arrange: Save custom templates
      const customTemplatesJson = '''
{
  "templates": [
    {
      "id": "custom-1",
      "name": "My Custom Template",
      "prompts": ["Prompt 1", "Prompt 2"]
    }
  ]
}
''';
      await storage.saveTemplates(customTemplatesJson);

      // Act: Export backup
      final backupJson = await backupService.createBackupJson();

      // Clear storage (simulate restore to new device)
      await storage.clearAll();
      expect(await storage.loadTemplates(), isNull);

      // Restore from backup
      final importResult = await backupService.importBackupFromJson(backupJson);

      // Assert: Custom templates restored
      expect(importResult.success, isTrue, reason: importResult.message);
      final restoredTemplates = await storage.loadTemplates();
      expect(restoredTemplates, isNotNull);
      expect(restoredTemplates, equals(customTemplatesJson));
    });

    test('sessions should survive backup/restore round-trip', () async {
      // Arrange: Save sessions
      const sessionsJson = '''
{
  "sessions": [
    {
      "id": "session-1",
      "templateId": "gratitude_journal",
      "createdAt": "2025-11-20T10:00:00Z",
      "responses": {"prompt1": "response1"}
    }
  ]
}
''';
      await storage.saveSessions(sessionsJson);

      // Act: Export backup
      final backupJson = await backupService.createBackupJson();

      // Clear storage
      await storage.clearAll();
      expect(await storage.loadSessions(), isNull);

      // Restore from backup
      final importResult = await backupService.importBackupFromJson(backupJson);

      // Assert: Sessions restored
      expect(importResult.success, isTrue, reason: importResult.message);
      final restoredSessions = await storage.loadSessions();
      expect(restoredSessions, isNotNull);
      expect(restoredSessions, equals(sessionsJson));
    });

    test('enabled templates should survive backup/restore round-trip', () async {
      // Arrange: Set enabled templates (custom selection)
      const enabledTemplateIds = [
        'cbt_thought_record',
        'goal_progress',
      ];
      await storage.setEnabledTemplates(enabledTemplateIds);

      // Act: Export backup
      final backupJson = await backupService.createBackupJson();

      // Clear storage
      await storage.clearAll();
      final defaultTemplates = await storage.getEnabledTemplates();
      expect(defaultTemplates, isNot(equals(enabledTemplateIds)),
          reason: 'Should have different defaults after clear');

      // Restore from backup
      final importResult = await backupService.importBackupFromJson(backupJson);

      // Assert: Enabled templates restored
      expect(importResult.success, isTrue, reason: importResult.message);
      final restoredEnabledTemplates = await storage.getEnabledTemplates();
      expect(restoredEnabledTemplates, equals(enabledTemplateIds));
    });

    test('all template data should survive backup/restore together', () async {
      // Arrange: Save all template-related data
      const customTemplates = '{"templates": [{"id": "custom-1"}]}';
      const sessions = '{"sessions": [{"id": "session-1"}]}';
      const enabledTemplates = ['cbt_thought_record', 'custom-1'];

      await storage.saveTemplates(customTemplates);
      await storage.saveSessions(sessions);
      await storage.setEnabledTemplates(enabledTemplates);

      // Act: Export backup
      final backupJson = await backupService.createBackupJson();

      // Clear storage
      await storage.clearAll();

      // Restore from backup
      final importResult = await backupService.importBackupFromJson(backupJson);

      // Assert: All data restored
      expect(importResult.success, isTrue, reason: importResult.message);
      expect(await storage.loadTemplates(), equals(customTemplates));
      expect(await storage.loadSessions(), equals(sessions));
      expect(await storage.getEnabledTemplates(), equals(enabledTemplates));

      // Verify import result details
      final detailedResults = importResult.detailedResults!;
      expect(
        detailedResults.any((r) => r.dataType == 'Custom Templates' && r.success),
        isTrue,
        reason: 'Custom Templates should be in import results',
      );
      expect(
        detailedResults.any((r) => r.dataType == 'Sessions' && r.success),
        isTrue,
        reason: 'Sessions should be in import results',
      );
      expect(
        detailedResults.any((r) => r.dataType == 'Enabled Templates' && r.success),
        isTrue,
        reason: 'Enabled Templates should be in import results',
      );
    });

    test('backup statistics should include template/session indicators', () async {
      // Arrange: Save template data
      await storage.saveTemplates('{"templates": []}');
      await storage.saveSessions('{"sessions": []}');
      await storage.setEnabledTemplates(['cbt_thought_record', 'gratitude_journal']);

      // Act: Create backup
      final backupJson = await backupService.createBackupJson();

      // Parse and verify statistics
      final backupData = parseBackupJson(backupJson);
      final stats = backupData['statistics'] as Map<String, dynamic>;

      // Assert: Statistics include template data
      expect(stats['hasCustomTemplates'], isTrue);
      expect(stats['hasSessions'], isTrue);
      expect(stats['totalEnabledTemplates'], equals(2));
    });

    test('empty template data should not break backup/restore', () async {
      // Arrange: No template data (fresh install scenario)
      // (Don't save anything - test default state)

      // Act: Export backup
      final backupJson = await backupService.createBackupJson();

      // Restore from backup
      final importResult = await backupService.importBackupFromJson(backupJson);

      // Assert: Import succeeds even with no template data
      expect(importResult.success, isTrue, reason: importResult.message);

      // Verify statistics show no template data
      final backupData = parseBackupJson(backupJson);
      final stats = backupData['statistics'] as Map<String, dynamic>;
      expect(stats['hasCustomTemplates'], isFalse);
      expect(stats['hasSessions'], isFalse);
    });
  });
}

/// Helper to parse backup JSON string
Map<String, dynamic> parseBackupJson(String backupJson) {
  return jsonDecode(backupJson) as Map<String, dynamic>;
}
