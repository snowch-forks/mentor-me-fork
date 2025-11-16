import 'dart:convert';
import 'package:mentor_me/migrations/migration.dart';
import 'package:mentor_me/services/debug_service.dart';
import 'package:mentor_me/services/structured_journaling_service.dart';

/// Migration: Backfill content field for structured journal entries
///
/// Version 1 stored structured journal entries with null content.
/// Version 2 requires content to be populated from structuredData.
///
/// This migration:
/// - Finds structured journal entries with null/empty content
/// - Generates content summary from structuredData
/// - Matches templates to add emoji and name as header
/// - Formats as "Field: Value" pairs
class V1ToV2JournalContentMigration extends Migration {
  final _debug = DebugService();
  final _structuredService = StructuredJournalingService();

  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get name => 'v1_to_v2_journal_content';

  @override
  String get description =>
      'Backfill content field for structured journal entries from structuredData';

  @override
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> data) async {
    try {
      await _debug.info(
        'Migration',
        'Starting $name migration',
      );

      // Get journal entries
      final entriesJson = data['journal_entries'] as String?;
      if (entriesJson == null || entriesJson.isEmpty) {
        await _debug.info('Migration', 'No journal entries to migrate');
        return data;
      }

      // Parse entries
      final List<dynamic> entries = jsonDecode(entriesJson);

      // Find entries that need migration
      final entriesToMigrate = entries.where((entry) {
        final type = entry['type'] as String?;
        final content = entry['content'] as String?;
        final structuredData = entry['structuredData'] as Map<String, dynamic>?;

        return type == 'structuredJournal' &&
            (content == null || content.isEmpty) &&
            structuredData != null &&
            structuredData.isNotEmpty;
      }).toList();

      if (entriesToMigrate.isEmpty) {
        await _debug.info(
          'Migration',
          'No structured journal entries need migration',
        );
        return data;
      }

      await _debug.info(
        'Migration',
        'Migrating ${entriesToMigrate.length} structured journal entries',
      );

      int migratedCount = 0;

      // Get all templates for lookup
      final allTemplates = _structuredService.getDefaultTemplates();

      // Migrate each entry
      for (final entry in entries) {
        final type = entry['type'] as String?;
        final content = entry['content'] as String?;
        final structuredData = entry['structuredData'] as Map<String, dynamic>?;

        // Skip if not a structured journal or already has content
        if (type != 'structuredJournal' ||
            (content != null && content.isNotEmpty) ||
            structuredData == null ||
            structuredData.isEmpty) {
          continue;
        }

        try {
          // Generate content from structured data
          final generatedContent = _generateContentFromStructuredData(
            structuredData,
            allTemplates,
          );

          if (generatedContent.isNotEmpty) {
            entry['content'] = generatedContent;
            migratedCount++;
          }
        } catch (e, stackTrace) {
          await _debug.error(
            'Migration',
            'Failed to migrate entry ${entry['id']}',
            stackTrace: stackTrace.toString(),
          );
          // Continue with other entries
        }
      }

      // Save migrated entries back
      data['journal_entries'] = jsonEncode(entries);

      await _debug.info(
        'Migration',
        'Successfully migrated $migratedCount structured journal entries',
      );

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

  /// Generate content summary from structured data
  String _generateContentFromStructuredData(
    Map<String, dynamic> structuredData,
    List<dynamic> templates,
  ) {
    // Try to find matching template based on field names
    dynamic matchingTemplate;

    // Get field names from structured data
    final fieldNames = structuredData.keys.toSet();

    // Try to match with a template
    for (final template in templates) {
      final templateFieldNames = (template.fields as List)
          .map((field) => field.label as String)
          .toSet();

      // Check if most fields match (at least 50% overlap)
      final overlap = fieldNames.intersection(templateFieldNames).length;
      final total = fieldNames.length;

      if (overlap >= (total * 0.5)) {
        matchingTemplate = template;
        break;
      }
    }

    final buffer = StringBuffer();

    // Add template header if found
    if (matchingTemplate != null) {
      final emoji = matchingTemplate.emoji ?? '';
      final name = matchingTemplate.name ?? '';
      buffer.writeln('$emoji $name'.trim());
      buffer.writeln();
    }

    // Add each field from structured data
    int fieldCount = 0;
    for (var entry in structuredData.entries) {
      final key = entry.key;
      final value = entry.value;

      // Skip null or empty values
      if (value == null || value.toString().isEmpty) {
        continue;
      }

      // Format the field
      buffer.writeln('$key: $value');
      fieldCount++;

      // Add blank line between fields (but not after the last one)
      if (fieldCount < structuredData.length) {
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }
}
