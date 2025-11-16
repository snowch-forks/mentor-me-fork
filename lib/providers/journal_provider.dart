// lib/providers/journal_provider.dart

import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/notification_analytics_service.dart';
import '../services/debug_service.dart';
import '../services/structured_journaling_service.dart';

class JournalProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();
  final NotificationAnalyticsService _analytics = NotificationAnalyticsService();
  final DebugService _debug = DebugService();
  final StructuredJournalingService _structuredService = StructuredJournalingService();
  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _lastCelebrationMessage;
  bool _hasMigrated = false;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get lastCelebrationMessage => _lastCelebrationMessage;

  JournalProvider() {
    _loadEntries();
  }

  /// Reload entries from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadJournalEntries();

    // Run migration once to backfill content for old structured journal entries
    if (!_hasMigrated) {
      await _migrateStructuredJournalContent();
      _hasMigrated = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(JournalEntry entry) async {
    _entries.insert(0, entry); // Most recent first
    await _storage.saveJournalEntries(_entries);

    // Track activity completion in analytics
    await _analytics.trackActivityCompleted(activityType: 'journal');

    // Get celebration message if user responded to a notification
    _lastCelebrationMessage = await _analytics.getCelebrationMessage('journal');

    // Notify adaptive reminder service that user journaled
    await _notificationService.onJournalCreated();
    notifyListeners();
  }

  /// Clear the last celebration message (call after showing it)
  void clearCelebrationMessage() {
    _lastCelebrationMessage = null;
    notifyListeners();
  }

  Future<void> updateEntry(JournalEntry updatedEntry) async {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      await _storage.saveJournalEntries(_entries);

      // Notify adaptive reminder service that user journaled
      await _notificationService.onJournalCreated();
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await _storage.saveJournalEntries(_entries);

    // Notify adaptive reminder service that user journaled
    await _notificationService.onJournalCreated();
    notifyListeners();
  }

  List<JournalEntry> getEntriesByGoal(String goalId) {
    return _entries.where((e) => e.goalIds.contains(goalId)).toList();
  }

  List<JournalEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      return e.createdAt.isAfter(start) && e.createdAt.isBefore(end);
    }).toList();
  }

  JournalEntry? getTodayEntry() {
    final today = DateTime.now();
    try {
      return _entries.firstWhere((e) {
        return e.createdAt.year == today.year &&
            e.createdAt.month == today.month &&
            e.createdAt.day == today.day;
      });
    } catch (e) {
      return null;
    }
  }

  /// Migrate old structured journal entries to have proper content summaries
  Future<void> _migrateStructuredJournalContent() async {
    try {
      // Find all structured journal entries with null content
      final entriesToMigrate = _entries.where(
        (entry) =>
            entry.type == JournalEntryType.structuredJournal &&
            (entry.content == null || entry.content!.isEmpty) &&
            entry.structuredData != null &&
            entry.structuredData!.isNotEmpty,
      ).toList();

      if (entriesToMigrate.isEmpty) {
        await _debug.info(
          'JournalProvider',
          'No structured journal entries need migration',
        );
        return;
      }

      await _debug.info(
        'JournalProvider',
        'Migrating ${entriesToMigrate.length} structured journal entries',
      );

      int migratedCount = 0;

      // Get all templates for lookup
      final allTemplates = _structuredService.getDefaultTemplates();

      for (final entry in entriesToMigrate) {
        try {
          // Generate content from structured data
          final content = _generateContentFromStructuredData(
            entry.structuredData!,
            allTemplates,
          );

          if (content.isNotEmpty) {
            // Update the entry with the generated content
            final updatedEntry = JournalEntry(
              id: entry.id,
              createdAt: entry.createdAt,
              type: entry.type,
              reflectionType: entry.reflectionType,
              content: content,
              qaPairs: entry.qaPairs,
              goalIds: entry.goalIds,
              aiInsights: entry.aiInsights,
              structuredSessionId: entry.structuredSessionId,
              structuredData: entry.structuredData,
            );

            // Replace in list
            final index = _entries.indexWhere((e) => e.id == entry.id);
            if (index != -1) {
              _entries[index] = updatedEntry;
              migratedCount++;
            }
          }
        } catch (e, stackTrace) {
          await _debug.error(
            'JournalProvider',
            'Failed to migrate entry ${entry.id}',
            stackTrace: stackTrace.toString(),
          );
        }
      }

      // Save all migrated entries
      if (migratedCount > 0) {
        await _storage.saveJournalEntries(_entries);
        await _debug.info(
          'JournalProvider',
          'Successfully migrated $migratedCount structured journal entries',
        );
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'JournalProvider',
        'Failed to run structured journal migration',
        stackTrace: stackTrace.toString(),
      );
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