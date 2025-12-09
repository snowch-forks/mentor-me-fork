import 'package:flutter/foundation.dart';
import '../models/mindful_eating_entry.dart';
import '../models/food_entry.dart';
import '../services/storage_service.dart';

/// Manages standalone mindful eating entries
class MindfulEatingProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<MindfulEatingEntry> _entries = [];
  bool _isLoading = false;

  // Mindful eating settings (reuse from FoodLogProvider pattern)
  bool _showHungerBefore = true;
  bool _showMoodBefore = true;
  bool _showFullnessAfter = true;
  bool _showMoodAfter = true;

  // User's custom moods (shared with food log)
  List<String> _customMoodsBefore = [];
  List<String> _customMoodsAfter = [];

  List<MindfulEatingEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  // Settings getters
  bool get showHungerBefore => _showHungerBefore;
  bool get showMoodBefore => _showMoodBefore;
  bool get showFullnessAfter => _showFullnessAfter;
  bool get showMoodAfter => _showMoodAfter;

  // Custom moods getters
  List<String> get customMoodsBefore => List.unmodifiable(_customMoodsBefore);
  List<String> get customMoodsAfter => List.unmodifiable(_customMoodsAfter);

  /// Get all moods available before eating (presets + custom)
  List<MoodOption> get allMoodsBefore {
    final presets = MealMoodPresets.beforeMeal.toList();
    for (final custom in _customMoodsBefore) {
      presets.add(MoodOption(id: custom, label: custom, emoji: ''));
    }
    return presets;
  }

  /// Get all moods available after eating (presets + custom)
  List<MoodOption> get allMoodsAfter {
    final presets = MealMoodPresets.afterMeal.toList();
    for (final custom in _customMoodsAfter) {
      presets.add(MoodOption(id: custom, label: custom, emoji: ''));
    }
    return presets;
  }

  MindfulEatingProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _storage.loadMindfulEatingEntries();

    // Load settings (reuse food log settings keys for consistency)
    final settings = await _storage.loadSettings();
    _showHungerBefore = settings['foodLogShowHungerBefore'] as bool? ?? true;
    _showMoodBefore = settings['foodLogShowMoodBefore'] as bool? ?? true;
    _showFullnessAfter = settings['foodLogShowFullnessAfter'] as bool? ?? true;
    _showMoodAfter = settings['foodLogShowMoodAfter'] as bool? ?? true;

    // Load custom moods (shared with food log)
    final customBefore = settings['foodLogCustomMoodsBefore'] as List<dynamic>?;
    final customAfter = settings['foodLogCustomMoodsAfter'] as List<dynamic>?;
    _customMoodsBefore = customBefore?.cast<String>() ?? [];
    _customMoodsAfter = customAfter?.cast<String>() ?? [];

    // Sort by timestamp (most recent first)
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new mindful eating entry
  Future<void> addEntry(MindfulEatingEntry entry) async {
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _storage.saveMindfulEatingEntries(_entries);
    notifyListeners();
  }

  /// Update an existing entry
  Future<void> updateEntry(MindfulEatingEntry updated) async {
    final index = _entries.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _entries[index] = updated;
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.saveMindfulEatingEntries(_entries);
      notifyListeners();
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storage.saveMindfulEatingEntries(_entries);
    notifyListeners();
  }

  /// Get entries for a specific date
  List<MindfulEatingEntry> entriesForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _entries.where((e) {
      final entryDate = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return entryDate == dateOnly;
    }).toList();
  }

  /// Get entries for today
  List<MindfulEatingEntry> get todayEntries => entriesForDate(DateTime.now());

  /// Check if user has logged mindful eating today
  bool get hasLoggedToday => todayEntries.isNotEmpty;

  /// Get the most recent entry
  MindfulEatingEntry? get mostRecentEntry => _entries.isNotEmpty ? _entries.first : null;

  /// Get entries for a date range
  List<MindfulEatingEntry> entriesInRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get entries for the last N days
  List<MindfulEatingEntry> entriesForLastDays(int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.timestamp.isAfter(start)).toList();
  }

  /// Calculate average hunger level before eating (for trends)
  double? averageHungerBefore(int days) {
    final recent = entriesForLastDays(days)
        .where((e) => e.hungerBefore != null)
        .toList();
    if (recent.isEmpty) return null;
    final sum = recent.fold<int>(0, (sum, e) => sum + e.hungerBefore!);
    return sum / recent.length;
  }

  /// Calculate average fullness after eating (for trends)
  double? averageFullnessAfter(int days) {
    final recent = entriesForLastDays(days)
        .where((e) => e.fullnessAfter != null)
        .toList();
    if (recent.isEmpty) return null;
    final sum = recent.fold<int>(0, (sum, e) => sum + e.fullnessAfter!);
    return sum / recent.length;
  }

  /// Get most common moods before eating (for insights)
  Map<String, int> moodFrequencyBefore(int days) {
    final counts = <String, int>{};
    for (final entry in entriesForLastDays(days)) {
      if (entry.moodBefore != null) {
        for (final mood in entry.moodBefore!) {
          counts[mood] = (counts[mood] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// Get most common moods after eating (for insights)
  Map<String, int> moodFrequencyAfter(int days) {
    final counts = <String, int>{};
    for (final entry in entriesForLastDays(days)) {
      if (entry.moodAfter != null) {
        for (final mood in entry.moodAfter!) {
          counts[mood] = (counts[mood] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
