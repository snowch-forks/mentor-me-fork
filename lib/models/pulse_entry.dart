import 'package:uuid/uuid.dart';

/// Represents a pulse/wellness check-in with extensible metrics
/// All metrics are stored in customMetrics map with 1-5 scale
class PulseEntry {
  final String id;
  final DateTime timestamp;

  /// Custom metrics for pulse check-ins (e.g., {'Mood': 3, 'Energy': 4, 'Focus': 5})
  /// All values use a 1-5 scale
  final Map<String, int> customMetrics;

  // Optional associations
  final String? journalEntryId;  // Link to a specific journal entry
  final String? notes;            // Optional text note about this pulse check-in

  // Deprecated: Legacy fields kept for data migration only
  @Deprecated('Use customMetrics instead')
  final MoodRating mood;
  @Deprecated('Use customMetrics instead')
  final int energyLevel;

  PulseEntry({
    String? id,
    DateTime? timestamp,
    Map<String, int>? customMetrics,
    this.journalEntryId,
    this.notes,
    @Deprecated('Use customMetrics instead') this.mood = MoodRating.notSet,
    @Deprecated('Use customMetrics instead') this.energyLevel = 0,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        customMetrics = customMetrics ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'customMetrics': customMetrics,
      'journalEntryId': journalEntryId,
      'notes': notes,
      // Legacy fields no longer saved
    };
  }

  factory PulseEntry.fromJson(Map<String, dynamic> json) {
    // Load customMetrics from JSON
    Map<String, int> metrics = {};

    if (json['customMetrics'] != null) {
      // New format: customMetrics exists
      metrics = Map<String, int>.from(json['customMetrics']);
    } else {
      // Legacy format: migrate mood and energyLevel to customMetrics
      final mood = MoodRating.values.firstWhere(
        (e) => e.toString() == json['mood'],
        orElse: () => MoodRating.notSet,
      );
      final energyLevel = json['energyLevel'] ?? 0;

      if (mood.isSet) {
        // Convert mood enum to 1-5 scale
        metrics['Mood'] = mood.index; // veryBad=1, bad=2, neutral=3, good=4, excellent=5
      }
      if (energyLevel > 0) {
        metrics['Energy'] = energyLevel;
      }
    }

    return PulseEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      customMetrics: metrics,
      journalEntryId: json['journalEntryId'],
      notes: json['notes'],
    );
  }

  PulseEntry copyWith({
    String? id,
    DateTime? timestamp,
    Map<String, int>? customMetrics,
    String? journalEntryId,
    String? notes,
  }) {
    return PulseEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      customMetrics: customMetrics ?? this.customMetrics,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      notes: notes ?? this.notes,
    );
  }

  /// Helper to check if any metrics are set
  bool get hasValidData => customMetrics.isNotEmpty;

  /// Get a display-friendly date string
  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  /// Get a display-friendly time string
  String get timeDisplay {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Get display name for this check-in based on metrics
  String get checkInTypeName {
    if (customMetrics.isEmpty) return 'Pulse Check';
    if (customMetrics.length == 1) {
      return '${customMetrics.keys.first} Check';
    }
    return 'Wellness Check';
  }

  /// Get a specific metric value (1-5) or null if not set
  int? getMetric(String name) => customMetrics[name];

  /// Check if a specific metric is set
  bool hasMetric(String name) => customMetrics.containsKey(name);
}

/// Mood rating enum for pulse entries
enum MoodRating {
  notSet,
  veryBad,
  bad,
  neutral,
  good,
  excellent,
}

extension MoodRatingExtension on MoodRating {
  String get emoji {
    switch (this) {
      case MoodRating.notSet:
        return '—';
      case MoodRating.veryBad:
        return '😞';
      case MoodRating.bad:
        return '😕';
      case MoodRating.neutral:
        return '😐';
      case MoodRating.good:
        return '🙂';
      case MoodRating.excellent:
        return '😄';
    }
  }

  String get displayName {
    switch (this) {
      case MoodRating.notSet:
        return 'Not Set';
      case MoodRating.veryBad:
        return 'Very Bad';
      case MoodRating.bad:
        return 'Bad';
      case MoodRating.neutral:
        return 'Neutral';
      case MoodRating.good:
        return 'Good';
      case MoodRating.excellent:
        return 'Excellent';
    }
  }

  bool get isSet => this != MoodRating.notSet;
}
