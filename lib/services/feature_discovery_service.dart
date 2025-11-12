// lib/services/feature_discovery_service.dart
// Tracks which features the user has discovered and used
// Used by MentorIntelligenceService to provide contextual feature discovery guidance

import 'storage_service.dart';

class FeatureDiscoveryState {
  // Feature usage flags
  bool hasOpenedChatScreen;
  bool hasCompletedGuidedReflection;
  bool hasCheckedOffReflectionHabit;
  bool hasTriedPulseCheck;
  bool hasCreatedMilestone;
  bool hasViewedCoachingCard;
  bool hasLinkedHabitToGoal;
  bool hasExportedData;
  bool hasUsedAIAnalysis;

  // Timestamps for analytics (optional)
  DateTime? firstChatAt;
  DateTime? firstReflectionAt;
  DateTime? firstHabitCheckAt;
  DateTime? firstPulseCheckAt;
  DateTime? firstMilestoneAt;

  FeatureDiscoveryState({
    this.hasOpenedChatScreen = false,
    this.hasCompletedGuidedReflection = false,
    this.hasCheckedOffReflectionHabit = false,
    this.hasTriedPulseCheck = false,
    this.hasCreatedMilestone = false,
    this.hasViewedCoachingCard = false,
    this.hasLinkedHabitToGoal = false,
    this.hasExportedData = false,
    this.hasUsedAIAnalysis = false,
    this.firstChatAt,
    this.firstReflectionAt,
    this.firstHabitCheckAt,
    this.firstPulseCheckAt,
    this.firstMilestoneAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasOpenedChatScreen': hasOpenedChatScreen,
      'hasCompletedGuidedReflection': hasCompletedGuidedReflection,
      'hasCheckedOffReflectionHabit': hasCheckedOffReflectionHabit,
      'hasTriedPulseCheck': hasTriedPulseCheck,
      'hasCreatedMilestone': hasCreatedMilestone,
      'hasViewedCoachingCard': hasViewedCoachingCard,
      'hasLinkedHabitToGoal': hasLinkedHabitToGoal,
      'hasExportedData': hasExportedData,
      'hasUsedAIAnalysis': hasUsedAIAnalysis,
      'firstChatAt': firstChatAt?.toIso8601String(),
      'firstReflectionAt': firstReflectionAt?.toIso8601String(),
      'firstHabitCheckAt': firstHabitCheckAt?.toIso8601String(),
      'firstPulseCheckAt': firstPulseCheckAt?.toIso8601String(),
      'firstMilestoneAt': firstMilestoneAt?.toIso8601String(),
    };
  }

  factory FeatureDiscoveryState.fromJson(Map<String, dynamic> json) {
    return FeatureDiscoveryState(
      hasOpenedChatScreen: json['hasOpenedChatScreen'] as bool? ?? false,
      hasCompletedGuidedReflection: json['hasCompletedGuidedReflection'] as bool? ?? false,
      hasCheckedOffReflectionHabit: json['hasCheckedOffReflectionHabit'] as bool? ?? false,
      hasTriedPulseCheck: json['hasTriedPulseCheck'] as bool? ?? false,
      hasCreatedMilestone: json['hasCreatedMilestone'] as bool? ?? false,
      hasViewedCoachingCard: json['hasViewedCoachingCard'] as bool? ?? false,
      hasLinkedHabitToGoal: json['hasLinkedHabitToGoal'] as bool? ?? false,
      hasExportedData: json['hasExportedData'] as bool? ?? false,
      hasUsedAIAnalysis: json['hasUsedAIAnalysis'] as bool? ?? false,
      firstChatAt: json['firstChatAt'] != null
          ? DateTime.parse(json['firstChatAt'] as String)
          : null,
      firstReflectionAt: json['firstReflectionAt'] != null
          ? DateTime.parse(json['firstReflectionAt'] as String)
          : null,
      firstHabitCheckAt: json['firstHabitCheckAt'] != null
          ? DateTime.parse(json['firstHabitCheckAt'] as String)
          : null,
      firstPulseCheckAt: json['firstPulseCheckAt'] != null
          ? DateTime.parse(json['firstPulseCheckAt'] as String)
          : null,
      firstMilestoneAt: json['firstMilestoneAt'] != null
          ? DateTime.parse(json['firstMilestoneAt'] as String)
          : null,
    );
  }

  FeatureDiscoveryState copyWith({
    bool? hasOpenedChatScreen,
    bool? hasCompletedGuidedReflection,
    bool? hasCheckedOffReflectionHabit,
    bool? hasTriedPulseCheck,
    bool? hasCreatedMilestone,
    bool? hasViewedCoachingCard,
    bool? hasLinkedHabitToGoal,
    bool? hasExportedData,
    bool? hasUsedAIAnalysis,
    DateTime? firstChatAt,
    DateTime? firstReflectionAt,
    DateTime? firstHabitCheckAt,
    DateTime? firstPulseCheckAt,
    DateTime? firstMilestoneAt,
  }) {
    return FeatureDiscoveryState(
      hasOpenedChatScreen: hasOpenedChatScreen ?? this.hasOpenedChatScreen,
      hasCompletedGuidedReflection: hasCompletedGuidedReflection ?? this.hasCompletedGuidedReflection,
      hasCheckedOffReflectionHabit: hasCheckedOffReflectionHabit ?? this.hasCheckedOffReflectionHabit,
      hasTriedPulseCheck: hasTriedPulseCheck ?? this.hasTriedPulseCheck,
      hasCreatedMilestone: hasCreatedMilestone ?? this.hasCreatedMilestone,
      hasViewedCoachingCard: hasViewedCoachingCard ?? this.hasViewedCoachingCard,
      hasLinkedHabitToGoal: hasLinkedHabitToGoal ?? this.hasLinkedHabitToGoal,
      hasExportedData: hasExportedData ?? this.hasExportedData,
      hasUsedAIAnalysis: hasUsedAIAnalysis ?? this.hasUsedAIAnalysis,
      firstChatAt: firstChatAt ?? this.firstChatAt,
      firstReflectionAt: firstReflectionAt ?? this.firstReflectionAt,
      firstHabitCheckAt: firstHabitCheckAt ?? this.firstHabitCheckAt,
      firstPulseCheckAt: firstPulseCheckAt ?? this.firstPulseCheckAt,
      firstMilestoneAt: firstMilestoneAt ?? this.firstMilestoneAt,
    );
  }
}

/// Service that manages feature discovery state
/// Singleton pattern for global access throughout the app
class FeatureDiscoveryService {
  static final FeatureDiscoveryService _instance = FeatureDiscoveryService._internal();
  factory FeatureDiscoveryService() => _instance;
  FeatureDiscoveryService._internal();

  final StorageService _storage = StorageService();
  static const String _storageKey = 'featureDiscovery';

  FeatureDiscoveryState _state = FeatureDiscoveryState();

  /// Initialize from storage
  Future<void> initialize() async {
    final settings = await _storage.loadSettings();
    if (settings.containsKey(_storageKey)) {
      _state = FeatureDiscoveryState.fromJson(
        settings[_storageKey] as Map<String, dynamic>
      );
    }
  }

  /// Get current state
  FeatureDiscoveryState get state => _state;

  /// Save state to storage
  Future<void> _save() async {
    final settings = await _storage.loadSettings();
    settings[_storageKey] = _state.toJson();
    await _storage.saveSettings(settings);
  }

  /// Mark that user has opened chat screen
  Future<void> markChatOpened() async {
    if (!_state.hasOpenedChatScreen) {
      _state = _state.copyWith(
        hasOpenedChatScreen: true,
        firstChatAt: DateTime.now(),
      );
      await _save();
    }
  }

  /// Mark that user has completed a guided reflection
  Future<void> markGuidedReflectionCompleted() async {
    if (!_state.hasCompletedGuidedReflection) {
      _state = _state.copyWith(
        hasCompletedGuidedReflection: true,
        firstReflectionAt: DateTime.now(),
      );
      await _save();
    }
  }

  /// Mark that user has checked off the daily reflection habit
  Future<void> markReflectionHabitChecked() async {
    if (!_state.hasCheckedOffReflectionHabit) {
      _state = _state.copyWith(
        hasCheckedOffReflectionHabit: true,
        firstHabitCheckAt: DateTime.now(),
      );
      await _save();
    }
  }

  /// Mark that user has tried a pulse check
  Future<void> markPulseCheckTried() async {
    if (!_state.hasTriedPulseCheck) {
      _state = _state.copyWith(
        hasTriedPulseCheck: true,
        firstPulseCheckAt: DateTime.now(),
      );
      await _save();
    }
  }

  /// Mark that user has created a milestone
  Future<void> markMilestoneCreated() async {
    if (!_state.hasCreatedMilestone) {
      _state = _state.copyWith(
        hasCreatedMilestone: true,
        firstMilestoneAt: DateTime.now(),
      );
      await _save();
    }
  }

  /// Mark that user has viewed the coaching card
  Future<void> markCoachingCardViewed() async {
    if (!_state.hasViewedCoachingCard) {
      _state = _state.copyWith(
        hasViewedCoachingCard: true,
      );
      await _save();
    }
  }

  /// Mark that user has linked a habit to a goal
  Future<void> markHabitLinkedToGoal() async {
    if (!_state.hasLinkedHabitToGoal) {
      _state = _state.copyWith(
        hasLinkedHabitToGoal: true,
      );
      await _save();
    }
  }

  /// Mark that user has exported data
  Future<void> markDataExported() async {
    if (!_state.hasExportedData) {
      _state = _state.copyWith(
        hasExportedData: true,
      );
      await _save();
    }
  }

  /// Mark that user has used AI analysis
  Future<void> markAIAnalysisUsed() async {
    if (!_state.hasUsedAIAnalysis) {
      _state = _state.copyWith(
        hasUsedAIAnalysis: true,
      );
      await _save();
    }
  }

  /// Reset all feature discovery (useful for testing)
  Future<void> reset() async {
    _state = FeatureDiscoveryState();
    await _save();
  }
}
