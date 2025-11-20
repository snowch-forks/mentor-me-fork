import 'dart:convert';
import 'package:mentor_me/services/debug_service.dart';

/// Lightweight schema validator for data integrity checks
///
/// This provides runtime validation without requiring full JSON Schema parsing.
/// For debugging with users, see the JSON Schema files in lib/schemas/
class SchemaValidator {
  final _debug = DebugService();

  /// Validate the overall backup/storage structure
  ///
  /// This checks that required top-level fields exist and are valid.
  /// It does NOT validate the contents of each field (that's the job of
  /// the model classes during deserialization).
  Future<bool> validateStructure(Map<String, dynamic> data) async {
    try {
      // Check schema version exists and is valid
      if (!data.containsKey('schemaVersion')) {
        await _debug.error(
          'SchemaValidator',
          'Missing schemaVersion field',
        );
        return false;
      }

      final version = data['schemaVersion'] as int?;
      if (version == null || version < 1) {
        await _debug.error(
          'SchemaValidator',
          'Invalid schemaVersion: $version',
        );
        return false;
      }

      // Version-specific validation
      switch (version) {
        case 1:
          return await _validateV1Structure(data);
        case 2:
          return await _validateV2Structure(data);
        case 3:
          return await _validateV3Structure(data);
        default:
          await _debug.warning(
            'SchemaValidator',
            'Unknown schema version: $version (validation skipped)',
          );
          return true; // Unknown version, skip validation
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'SchemaValidator',
        'Schema validation failed',
        stackTrace: stackTrace.toString(),
      );
      return false;
    }
  }

  /// Validate v1 schema structure
  Future<bool> _validateV1Structure(Map<String, dynamic> data) async {
    // Required top-level keys for v1
    final requiredKeys = [
      'journal_entries',
      'goals',
      'habits',
      'checkins',
    ];

    for (final key in requiredKeys) {
      if (!data.containsKey(key)) {
        await _debug.warning(
          'SchemaValidator',
          'Missing expected key in v1: $key',
        );
        // Not fatal - key might not exist if user has no data
      }
    }

    // Validate journal_entries if present
    if (data['journal_entries'] != null) {
      if (!await _validateJournalEntries(data['journal_entries'] as String?)) {
        return false;
      }
    }

    return true;
  }

  /// Validate v2 schema structure
  Future<bool> _validateV2Structure(Map<String, dynamic> data) async {
    // v2 has same required keys as v1
    final requiredKeys = [
      'journal_entries',
      'goals',
      'habits',
      'checkins',
    ];

    for (final key in requiredKeys) {
      if (!data.containsKey(key)) {
        await _debug.warning(
          'SchemaValidator',
          'Missing expected key in v2: $key',
        );
      }
    }

    // Validate journal_entries if present
    if (data['journal_entries'] != null) {
      if (!await _validateJournalEntries(data['journal_entries'] as String?)) {
        return false;
      }

      // v2-specific: Check structured journals have content
      if (!await _validateV2JournalContent(
          data['journal_entries'] as String?)) {
        return false;
      }
    }

    return true;
  }

  /// Validate v3 schema structure
  Future<bool> _validateV3Structure(Map<String, dynamic> data) async {
    // v3 has same required keys as v2
    final requiredKeys = [
      'journal_entries',
      'goals',
      'habits',
      'checkins',
    ];

    for (final key in requiredKeys) {
      if (!data.containsKey(key)) {
        await _debug.warning(
          'SchemaValidator',
          'Missing expected key in v3: $key',
        );
      }
    }

    // Validate journal_entries if present (same as v2)
    if (data['journal_entries'] != null) {
      if (!await _validateJournalEntries(data['journal_entries'] as String?)) {
        return false;
      }

      // v2-specific: Check structured journals have content
      if (!await _validateV2JournalContent(
          data['journal_entries'] as String?)) {
        return false;
      }
    }

    // v3-specific: Validate goals have sortOrder
    if (data['goals'] != null) {
      if (!await _validateV3GoalsAndHabits(data['goals'] as String?, 'goals')) {
        return false;
      }
    }

    // v3-specific: Validate habits have sortOrder
    if (data['habits'] != null) {
      if (!await _validateV3GoalsAndHabits(data['habits'] as String?, 'habits')) {
        return false;
      }
    }

    return true;
  }

  /// Validate v3-specific requirement: goals and habits must have sortOrder
  Future<bool> _validateV3GoalsAndHabits(String? itemsJson, String itemType) async {
    if (itemsJson == null || itemsJson.isEmpty || itemsJson == '[]') {
      return true; // Empty is valid
    }

    try {
      final items = jsonDecode(itemsJson) as List;

      for (final item in items) {
        // v3: Goals and habits MUST have sortOrder field
        if (!item.containsKey('sortOrder')) {
          await _debug.error(
            'SchemaValidator',
            'v3 validation failed: $itemType entry ${item['id']} missing sortOrder',
          );
          return false;
        }

        final sortOrder = item['sortOrder'];
        if (sortOrder is! int || sortOrder < 0) {
          await _debug.error(
            'SchemaValidator',
            'v3 validation failed: $itemType entry ${item['id']} has invalid sortOrder: $sortOrder',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      await _debug.error(
        'SchemaValidator',
        'Failed to validate v3 $itemType: $e',
      );
      return false;
    }
  }

  /// Validate journal entries JSON structure
  Future<bool> _validateJournalEntries(String? entriesJson) async {
    if (entriesJson == null || entriesJson.isEmpty) {
      return true; // Empty is valid
    }

    try {
      final entries = jsonDecode(entriesJson) as List;

      for (final entry in entries) {
        if (!_isValidJournalEntry(entry as Map<String, dynamic>)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      await _debug.error(
        'SchemaValidator',
        'Invalid journal_entries JSON: $e',
      );
      return false;
    }
  }

  /// Check if a journal entry has required fields
  bool _isValidJournalEntry(Map<String, dynamic> entry) {
    // Required fields for all journal entries
    if (!entry.containsKey('id')) return false;
    if (!entry.containsKey('type')) return false;
    if (!entry.containsKey('createdAt')) return false;

    return true;
  }

  /// Validate v2-specific requirement: structured journals must have content
  Future<bool> _validateV2JournalContent(String? entriesJson) async {
    if (entriesJson == null || entriesJson.isEmpty) {
      return true;
    }

    try {
      final entries = jsonDecode(entriesJson) as List;

      for (final entry in entries) {
        final type = entry['type'] as String?;

        // v2: Structured journals MUST have content field populated
        if (type == 'structuredJournal') {
          final content = entry['content'] as String?;
          if (content == null || content.isEmpty) {
            await _debug.error(
              'SchemaValidator',
              'v2 validation failed: Structured journal entry ${entry['id']} missing content',
            );
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      await _debug.error(
        'SchemaValidator',
        'Failed to validate v2 journal content: $e',
      );
      return false;
    }
  }

  /// Validate import file structure before attempting to import
  ///
  /// This checks that the imported JSON has the expected shape.
  /// Call this BEFORE running migrations.
  Future<bool> validateImportFile(Map<String, dynamic> data) async {
    // Check that it looks like a backup file
    if (!data.containsKey('schemaVersion') && !data.containsKey('exportDate')) {
      await _debug.error(
        'SchemaValidator',
        'File does not appear to be a valid backup (missing schemaVersion and exportDate)',
      );
      return false;
    }

    return await validateStructure(data);
  }
}
