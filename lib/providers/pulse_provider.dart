// lib/providers/pulse_provider.dart
// Manages pulse/wellness check-in entries

import 'package:flutter/foundation.dart';
import '../models/pulse_entry.dart';
import '../services/storage_service.dart';

class PulseProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PulseEntry> _entries = [];
  bool _isLoading = false;

  List<PulseEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  PulseProvider() {
    _loadEntries();
  }

  /// Reload entries from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadPulseEntries();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(PulseEntry entry) async {
    _entries.insert(0, entry); // Most recent first
    await _storage.savePulseEntries(_entries);
    notifyListeners();
  }

  Future<void> updateEntry(PulseEntry updatedEntry) async {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      await _storage.savePulseEntries(_entries);
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await _storage.savePulseEntries(_entries);
    notifyListeners();
  }

  /// Get pulse entries for a specific date
  List<PulseEntry> getEntriesForDate(DateTime date) {
    return _entries.where((e) {
      return e.timestamp.year == date.year &&
          e.timestamp.month == date.month &&
          e.timestamp.day == date.day;
    }).toList();
  }

  /// Get pulse entries within a date range (inclusive)
  List<PulseEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      return !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end);
    }).toList();
  }

  /// Get the most recent pulse entry
  PulseEntry? getLatestEntry() {
    return _entries.isNotEmpty ? _entries.first : null;
  }

  /// Get pulse entry for today (most recent)
  PulseEntry? getTodayEntry() {
    final today = DateTime.now();
    try {
      return _entries.firstWhere((e) {
        return e.timestamp.year == today.year &&
            e.timestamp.month == today.month &&
            e.timestamp.day == today.day;
      });
    } catch (e) {
      return null;
    }
  }

  /// Get pulse entries linked to a specific journal entry
  List<PulseEntry> getEntriesByJournalId(String journalEntryId) {
    return _entries.where((e) => e.journalEntryId == journalEntryId).toList();
  }

  /// Get average value for a specific metric within a date range (returns 0-5 scale)
  double getAverageMetric(String metricName, DateTime start, DateTime end) {
    final rangeEntries = getEntriesByDateRange(start, end)
        .where((e) => e.customMetrics.containsKey(metricName))
        .toList();

    if (rangeEntries.isEmpty) return 0;

    final sum = rangeEntries.fold<int>(
      0,
      (sum, e) => sum + (e.customMetrics[metricName] ?? 0),
    );

    return sum / rangeEntries.length;
  }

  /// Get all unique metric names from entries
  Set<String> getAllMetricNames() {
    final names = <String>{};
    for (final entry in _entries) {
      names.addAll(entry.customMetrics.keys);
    }
    return names;
  }

  /// Get metric statistics for a date range
  Map<String, double> getMetricAverages(DateTime start, DateTime end) {
    final metricNames = getAllMetricNames();
    final averages = <String, double>{};

    for (final name in metricNames) {
      averages[name] = getAverageMetric(name, start, end);
    }

    return averages;
  }
}
