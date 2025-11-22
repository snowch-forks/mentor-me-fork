// test/providers/pulse_provider_test.dart
// Unit tests for PulseProvider

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_me/providers/pulse_provider.dart';
import 'package:mentor_me/models/pulse_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PulseProvider', () {
    late PulseProvider provider;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      provider = PulseProvider();
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    group('Initialization', () {
      test('should start with empty entries list', () {
        expect(provider.entries, isEmpty);
      });

      test('should load entries from storage on init', () async {
        // Setup: Add entries to storage
        SharedPreferences.setMockInitialValues({
          'pulse_entries': '[{"id":"1","timestamp":"2025-01-15T10:00:00.000Z","customMetrics":{"Mood":4,"Energy":3}}]'
        });

        // Create new provider (loads from storage)
        final newProvider = PulseProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.entries.length, 1);
        expect(newProvider.entries.first.customMetrics['Mood'], 4);
        expect(newProvider.entries.first.customMetrics['Energy'], 3);
      });

      test('should handle corrupted storage data gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'pulse_entries': 'invalid json'
        });

        final newProvider = PulseProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.entries, isEmpty);
      });

      test('should not be loading after initialization', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        expect(provider.isLoading, isFalse);
      });
    });

    group('Add Entry', () {
      test('should add a new pulse entry', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 4, 'Energy': 5},
        );

        await provider.addEntry(entry);

        expect(provider.entries.length, 1);
        expect(provider.entries.first.customMetrics['Mood'], 4);
        expect(provider.entries.first.customMetrics['Energy'], 5);
      });

      test('should insert new entries at the beginning (most recent first)', () async {
        final entry1 = PulseEntry(
          timestamp: DateTime(2025, 1, 1),
          customMetrics: {'Mood': 3},
        );
        final entry2 = PulseEntry(
          timestamp: DateTime(2025, 1, 2),
          customMetrics: {'Mood': 5},
        );

        await provider.addEntry(entry1);
        await provider.addEntry(entry2);

        expect(provider.entries.first.timestamp, entry2.timestamp);
        expect(provider.entries.last.timestamp, entry1.timestamp);
      });

      test('should generate unique ID for each entry', () async {
        final entry1 = PulseEntry(
          customMetrics: {'Mood': 3},
        );
        final entry2 = PulseEntry(
          customMetrics: {'Mood': 4},
        );

        await provider.addEntry(entry1);
        await provider.addEntry(entry2);

        expect(provider.entries.length, 2);
        expect(provider.entries[0].id, isNot(provider.entries[1].id));
      });

      test('should notify listeners when entry added', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        final entry = PulseEntry(
          customMetrics: {'Mood': 4},
        );
        await provider.addEntry(entry);

        expect(notified, isTrue);
      });

      test('should persist entry to storage', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 4, 'Energy': 3},
        );

        await provider.addEntry(entry);

        // Create new provider to verify persistence
        final newProvider = PulseProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newProvider.entries.length, 1);
        expect(newProvider.entries.first.customMetrics['Mood'], 4);
      });

      test('should support entries with journal link', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 4},
          journalEntryId: 'journal-123',
        );

        await provider.addEntry(entry);

        expect(provider.entries.first.journalEntryId, 'journal-123');
      });

      test('should support entries with notes', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 4},
          notes: 'Feeling great today!',
        );

        await provider.addEntry(entry);

        expect(provider.entries.first.notes, 'Feeling great today!');
      });
    });

    group('Update Entry', () {
      test('should update existing entry', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 3},
        );
        await provider.addEntry(entry);

        final updatedEntry = entry.copyWith(
          customMetrics: {'Mood': 5, 'Energy': 4},
        );
        await provider.updateEntry(updatedEntry);

        expect(provider.entries.length, 1);
        expect(provider.entries.first.customMetrics['Mood'], 5);
        expect(provider.entries.first.customMetrics['Energy'], 4);
      });

      test('should not add new entry if ID does not exist', () async {
        final entry = PulseEntry(
          id: 'non-existent-id',
          customMetrics: {'Mood': 4},
        );

        await provider.updateEntry(entry);

        expect(provider.entries, isEmpty);
      });

      test('should notify listeners when entry updated', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 3},
        );
        await provider.addEntry(entry);

        var notifiedCount = 0;
        provider.addListener(() => notifiedCount++);

        final updatedEntry = entry.copyWith(
          customMetrics: {'Mood': 5},
        );
        await provider.updateEntry(updatedEntry);

        expect(notifiedCount, 1);
      });
    });

    group('Delete Entry', () {
      test('should delete entry by ID', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 4},
        );
        await provider.addEntry(entry);

        expect(provider.entries.length, 1);

        await provider.deleteEntry(entry.id);

        expect(provider.entries, isEmpty);
      });

      test('should handle deleting non-existent entry', () async {
        await provider.deleteEntry('non-existent-id');

        expect(provider.entries, isEmpty);
      });

      test('should notify listeners when entry deleted', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 4},
        );
        await provider.addEntry(entry);

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.deleteEntry(entry.id);

        expect(notified, isTrue);
      });
    });

    group('Get Entries For Date', () {
      test('should return entries for specific date', () async {
        final jan15 = DateTime(2025, 1, 15, 10, 0);
        final jan16 = DateTime(2025, 1, 16, 10, 0);

        await provider.addEntry(PulseEntry(
          timestamp: jan15,
          customMetrics: {'Mood': 3},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: jan16,
          customMetrics: {'Mood': 4},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: jan15.add(const Duration(hours: 2)),
          customMetrics: {'Mood': 5},
        ));

        final jan15Entries = provider.getEntriesForDate(jan15);

        expect(jan15Entries.length, 2);
        expect(jan15Entries.every((e) => e.timestamp.day == 15), isTrue);
      });

      test('should return empty list if no entries for date', () {
        final entries = provider.getEntriesForDate(DateTime(2025, 1, 1));

        expect(entries, isEmpty);
      });
    });

    group('Get Entries By Date Range', () {
      test('should return entries within inclusive date range', () async {
        final jan1 = DateTime(2025, 1, 1);
        final jan15 = DateTime(2025, 1, 15);
        final jan31 = DateTime(2025, 1, 31);
        final feb5 = DateTime(2025, 2, 5);

        await provider.addEntry(PulseEntry(
          timestamp: jan15,
          customMetrics: {'Mood': 3},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2024, 12, 25),
          customMetrics: {'Mood': 4},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: feb5,
          customMetrics: {'Mood': 5},
        ));

        final januaryEntries = provider.getEntriesByDateRange(jan1, jan31);

        expect(januaryEntries.length, 1);
        expect(januaryEntries.first.timestamp.month, 1);
      });

      test('should include entries at exact start boundary', () async {
        final start = DateTime(2025, 1, 1, 0, 0, 0);
        final end = DateTime(2025, 1, 31, 23, 59, 59);

        await provider.addEntry(PulseEntry(
          timestamp: start, // Exactly at start
          customMetrics: {'Mood': 3},
        ));

        final entries = provider.getEntriesByDateRange(start, end);

        expect(entries.length, 1);
      });

      test('should include entries at exact end boundary', () async {
        final start = DateTime(2025, 1, 1, 0, 0, 0);
        final end = DateTime(2025, 1, 31, 23, 59, 59);

        await provider.addEntry(PulseEntry(
          timestamp: end, // Exactly at end
          customMetrics: {'Mood': 3},
        ));

        final entries = provider.getEntriesByDateRange(start, end);

        expect(entries.length, 1);
      });

      test('should return empty list if no entries in range', () {
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);

        final entries = provider.getEntriesByDateRange(start, end);

        expect(entries, isEmpty);
      });
    });

    group('Get Latest Entry', () {
      test('should return most recent entry', () async {
        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 1),
          customMetrics: {'Mood': 3},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 15),
          customMetrics: {'Mood': 5},
        ));

        final latest = provider.getLatestEntry();

        expect(latest, isNotNull);
        expect(latest!.customMetrics['Mood'], 5);
      });

      test('should return null if no entries', () {
        final latest = provider.getLatestEntry();

        expect(latest, isNull);
      });
    });

    group('Get Today Entry', () {
      test('should return today\'s entry if it exists', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        await provider.addEntry(PulseEntry(
          timestamp: today,
          customMetrics: {'Mood': 5},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: yesterday,
          customMetrics: {'Mood': 3},
        ));

        final todayEntry = provider.getTodayEntry();

        expect(todayEntry, isNotNull);
        expect(todayEntry!.customMetrics['Mood'], 5);
      });

      test('should return null if no entry for today', () {
        final todayEntry = provider.getTodayEntry();

        expect(todayEntry, isNull);
      });
    });

    group('Get Entries By Journal ID', () {
      test('should return entries linked to specific journal', () async {
        await provider.addEntry(PulseEntry(
          customMetrics: {'Mood': 3},
          journalEntryId: 'journal-1',
        ));
        await provider.addEntry(PulseEntry(
          customMetrics: {'Mood': 4},
          journalEntryId: 'journal-2',
        ));
        await provider.addEntry(PulseEntry(
          customMetrics: {'Mood': 5},
          journalEntryId: 'journal-1',
        ));

        final journal1Entries = provider.getEntriesByJournalId('journal-1');

        expect(journal1Entries.length, 2);
        expect(journal1Entries.every((e) => e.journalEntryId == 'journal-1'), isTrue);
      });

      test('should return empty list if no entries for journal', () {
        final entries = provider.getEntriesByJournalId('non-existent');

        expect(entries, isEmpty);
      });
    });

    group('Metric Statistics', () {
      test('should calculate average metric value', () async {
        final jan1 = DateTime(2025, 1, 1);
        final jan31 = DateTime(2025, 1, 31);

        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 5),
          customMetrics: {'Mood': 3, 'Energy': 2},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 10),
          customMetrics: {'Mood': 5, 'Energy': 4},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 15),
          customMetrics: {'Mood': 4, 'Energy': 5},
        ));

        final avgMood = provider.getAverageMetric('Mood', jan1, jan31);
        final avgEnergy = provider.getAverageMetric('Energy', jan1, jan31);

        expect(avgMood, 4.0); // (3 + 5 + 4) / 3 = 4.0
        expect(avgEnergy, closeTo(3.67, 0.01)); // (2 + 4 + 5) / 3 ≈ 3.67
      });

      test('should return 0 if no entries have the metric', () async {
        final jan1 = DateTime(2025, 1, 1);
        final jan31 = DateTime(2025, 1, 31);

        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 5),
          customMetrics: {'Energy': 3},
        ));

        final avgMood = provider.getAverageMetric('Mood', jan1, jan31);

        expect(avgMood, 0);
      });

      test('should return 0 if no entries in range', () {
        final jan1 = DateTime(2025, 1, 1);
        final jan31 = DateTime(2025, 1, 31);

        final avgMood = provider.getAverageMetric('Mood', jan1, jan31);

        expect(avgMood, 0);
      });

      test('should get all unique metric names', () async {
        await provider.addEntry(PulseEntry(
          customMetrics: {'Mood': 3, 'Energy': 4},
        ));
        await provider.addEntry(PulseEntry(
          customMetrics: {'Mood': 5, 'Focus': 4},
        ));
        await provider.addEntry(PulseEntry(
          customMetrics: {'Stress': 2},
        ));

        final metricNames = provider.getAllMetricNames();

        expect(metricNames.length, 4);
        expect(metricNames, containsAll(['Mood', 'Energy', 'Focus', 'Stress']));
      });

      test('should return empty set if no entries', () {
        final metricNames = provider.getAllMetricNames();

        expect(metricNames, isEmpty);
      });

      test('should calculate averages for all metrics in range', () async {
        final jan1 = DateTime(2025, 1, 1);
        final jan31 = DateTime(2025, 1, 31);

        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 5),
          customMetrics: {'Mood': 3, 'Energy': 4},
        ));
        await provider.addEntry(PulseEntry(
          timestamp: DateTime(2025, 1, 10),
          customMetrics: {'Mood': 5, 'Energy': 2},
        ));

        final averages = provider.getMetricAverages(jan1, jan31);

        expect(averages['Mood'], 4.0); // (3 + 5) / 2 = 4.0
        expect(averages['Energy'], 3.0); // (4 + 2) / 2 = 3.0
      });
    });

    group('Reload', () {
      test('should reload entries from storage', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 3},
        );
        await provider.addEntry(entry);

        // Modify storage directly
        SharedPreferences.setMockInitialValues({
          'pulse_entries': '[{"id":"new-id","timestamp":"2025-01-15T10:00:00.000Z","customMetrics":{"Mood":5,"Energy":4}}]'
        });

        await provider.reload();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.entries.length, 1);
        expect(provider.entries.first.customMetrics['Mood'], 5);
        expect(provider.entries.first.customMetrics['Energy'], 4);
      });
    });

    group('Edge Cases', () {
      test('should handle multiple rapid adds', () async {
        final futures = List.generate(10, (i) {
          return provider.addEntry(PulseEntry(
            customMetrics: {'Mood': i % 5 + 1},
          ));
        });

        await Future.wait(futures);

        expect(provider.entries.length, 10);
      });

      test('should handle entry with multiple metrics', () async {
        final entry = PulseEntry(
          customMetrics: {
            'Mood': 4,
            'Energy': 3,
            'Focus': 5,
            'Stress': 2,
            'Sleep': 4,
          },
        );

        await provider.addEntry(entry);

        final retrieved = provider.entries.first;
        expect(retrieved.customMetrics.length, 5);
        expect(retrieved.customMetrics['Mood'], 4);
        expect(retrieved.customMetrics['Sleep'], 4);
      });

      test('should handle entry with empty metrics', () async {
        final entry = PulseEntry(
          customMetrics: {},
        );

        await provider.addEntry(entry);

        expect(provider.entries.first.customMetrics, isEmpty);
      });

      test('should preserve all entry fields during update', () async {
        final entry = PulseEntry(
          customMetrics: {'Mood': 3},
          journalEntryId: 'journal-123',
          notes: 'Original note',
        );
        await provider.addEntry(entry);

        final updatedEntry = entry.copyWith(
          customMetrics: {'Mood': 5},
        );
        await provider.updateEntry(updatedEntry);

        final retrieved = provider.entries.first;
        expect(retrieved.customMetrics['Mood'], 5);
        expect(retrieved.journalEntryId, 'journal-123');
        expect(retrieved.notes, 'Original note');
      });
    });
  });
}
