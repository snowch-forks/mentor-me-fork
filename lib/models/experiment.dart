import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'experiment.g.dart';

/// Status of an experiment through its lifecycle
enum ExperimentStatus {
  draft,      // Created but not yet started
  baseline,   // Collecting baseline data (no intervention)
  active,     // Running intervention phase
  completed,  // Finished with results
  abandoned,  // User stopped early
}

extension ExperimentStatusExtension on ExperimentStatus {
  String get displayName {
    switch (this) {
      case ExperimentStatus.draft:
        return 'Draft';
      case ExperimentStatus.baseline:
        return 'Baseline';
      case ExperimentStatus.active:
        return 'Active';
      case ExperimentStatus.completed:
        return 'Completed';
      case ExperimentStatus.abandoned:
        return 'Abandoned';
    }
  }

  String get description {
    switch (this) {
      case ExperimentStatus.draft:
        return 'Ready to start';
      case ExperimentStatus.baseline:
        return 'Collecting baseline data';
      case ExperimentStatus.active:
        return 'Testing intervention';
      case ExperimentStatus.completed:
        return 'Results available';
      case ExperimentStatus.abandoned:
        return 'Stopped early';
    }
  }

  bool get isRunning => this == ExperimentStatus.baseline || this == ExperimentStatus.active;
  bool get isFinished => this == ExperimentStatus.completed || this == ExperimentStatus.abandoned;
}

/// Design type for the experiment
enum ExperimentDesign {
  baselineIntervention, // First baseline, then intervention (most common)
  abTest,               // Alternating days (future)
  reversal,             // A-B-A design (future)
}

extension ExperimentDesignExtension on ExperimentDesign {
  String get displayName {
    switch (this) {
      case ExperimentDesign.baselineIntervention:
        return 'Baseline → Intervention';
      case ExperimentDesign.abTest:
        return 'A/B Test';
      case ExperimentDesign.reversal:
        return 'A-B-A Reversal';
    }
  }

  String get description {
    switch (this) {
      case ExperimentDesign.baselineIntervention:
        return 'Measure without intervention first, then with intervention';
      case ExperimentDesign.abTest:
        return 'Randomly alternate between intervention and control days';
      case ExperimentDesign.reversal:
        return 'Baseline, then intervention, then return to baseline';
    }
  }
}

/// Custom converter for ExperimentStatus enum
class ExperimentStatusConverter implements JsonConverter<ExperimentStatus, String> {
  const ExperimentStatusConverter();

  @override
  ExperimentStatus fromJson(String json) {
    final value = json.contains('.') ? json.split('.').last : json;
    return ExperimentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExperimentStatus.draft,
    );
  }

  @override
  String toJson(ExperimentStatus status) => status.name;
}

/// Custom converter for ExperimentDesign enum
class ExperimentDesignConverter implements JsonConverter<ExperimentDesign, String> {
  const ExperimentDesignConverter();

  @override
  ExperimentDesign fromJson(String json) {
    final value = json.contains('.') ? json.split('.').last : json;
    return ExperimentDesign.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExperimentDesign.baselineIntervention,
    );
  }

  @override
  String toJson(ExperimentDesign design) => design.name;
}

/// Represents a personal N-of-1 experiment to test a hypothesis.
///
/// Users can scientifically test whether an intervention (like morning exercise)
/// affects an outcome (like focus levels) by collecting baseline data first,
/// then measuring during the intervention period.
///
/// **JSON Schema:** lib/schemas/v3.json (experiments field)
/// **Export Format:** lib/services/backup_service.dart (experiments field)
@JsonSerializable()
class Experiment {
  final String id;
  final String title;
  final String hypothesis;

  @ExperimentStatusConverter()
  final ExperimentStatus status;

  @ExperimentDesignConverter()
  final ExperimentDesign design;

  // Intervention (what we're testing)
  final String interventionName;
  final String? interventionDescription;
  final String? linkedHabitId; // Track via existing habit

  // Outcome (what we're measuring)
  final String outcomeName;
  final String? pulseTypeName; // Link to PulseType for measurement

  // Configuration
  @JsonKey(defaultValue: 7)
  final int baselineDays;
  @JsonKey(defaultValue: 14)
  final int interventionDays;
  @JsonKey(defaultValue: 5)
  final int minimumDataPoints; // Minimum entries per phase for valid analysis

  // Timeline
  final DateTime createdAt;
  final DateTime? startedAt;           // When baseline started
  final DateTime? interventionStartedAt; // When intervention phase started
  final DateTime? completedAt;

  // Optional links
  final String? linkedGoalId; // Goal this experiment supports

  // Results (populated when complete)
  final ExperimentResults? results;

  // Notes
  @JsonKey(defaultValue: [])
  final List<ExperimentNote> notes;

  Experiment({
    String? id,
    required this.title,
    required this.hypothesis,
    this.status = ExperimentStatus.draft,
    this.design = ExperimentDesign.baselineIntervention,
    required this.interventionName,
    this.interventionDescription,
    this.linkedHabitId,
    required this.outcomeName,
    this.pulseTypeName,
    this.baselineDays = 7,
    this.interventionDays = 14,
    this.minimumDataPoints = 5,
    DateTime? createdAt,
    this.startedAt,
    this.interventionStartedAt,
    this.completedAt,
    this.linkedGoalId,
    this.results,
    List<ExperimentNote>? notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        notes = notes ?? [];

  factory Experiment.fromJson(Map<String, dynamic> json) => _$ExperimentFromJson(json);
  Map<String, dynamic> toJson() => _$ExperimentToJson(this);

  Experiment copyWith({
    String? title,
    String? hypothesis,
    ExperimentStatus? status,
    ExperimentDesign? design,
    String? interventionName,
    String? interventionDescription,
    String? linkedHabitId,
    String? outcomeName,
    String? pulseTypeName,
    int? baselineDays,
    int? interventionDays,
    int? minimumDataPoints,
    DateTime? startedAt,
    DateTime? interventionStartedAt,
    DateTime? completedAt,
    String? linkedGoalId,
    ExperimentResults? results,
    List<ExperimentNote>? notes,
  }) {
    return Experiment(
      id: id,
      title: title ?? this.title,
      hypothesis: hypothesis ?? this.hypothesis,
      status: status ?? this.status,
      design: design ?? this.design,
      interventionName: interventionName ?? this.interventionName,
      interventionDescription: interventionDescription ?? this.interventionDescription,
      linkedHabitId: linkedHabitId ?? this.linkedHabitId,
      outcomeName: outcomeName ?? this.outcomeName,
      pulseTypeName: pulseTypeName ?? this.pulseTypeName,
      baselineDays: baselineDays ?? this.baselineDays,
      interventionDays: interventionDays ?? this.interventionDays,
      minimumDataPoints: minimumDataPoints ?? this.minimumDataPoints,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      interventionStartedAt: interventionStartedAt ?? this.interventionStartedAt,
      completedAt: completedAt ?? this.completedAt,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      results: results ?? this.results,
      notes: notes ?? this.notes,
    );
  }

  /// Total duration of the experiment in days
  int get totalDays => baselineDays + interventionDays;

  /// Calculate current day of the experiment (1-indexed)
  int? get currentDay {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!).inDays + 1;
  }

  /// Calculate days remaining in current phase
  int? get daysRemainingInPhase {
    if (startedAt == null) return null;
    final day = currentDay!;

    if (status == ExperimentStatus.baseline) {
      return baselineDays - day + 1;
    } else if (status == ExperimentStatus.active) {
      final interventionDay = interventionStartedAt != null
          ? DateTime.now().difference(interventionStartedAt!).inDays + 1
          : day - baselineDays;
      return interventionDays - interventionDay + 1;
    }
    return null;
  }

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    if (status == ExperimentStatus.draft) return 0.0;
    if (status == ExperimentStatus.completed) return 1.0;
    if (startedAt == null) return 0.0;

    final day = currentDay!;
    return (day / totalDays).clamp(0.0, 1.0);
  }

  /// Check if ready to transition to intervention phase
  bool get canStartIntervention {
    if (status != ExperimentStatus.baseline) return false;
    if (startedAt == null) return false;
    return currentDay! > baselineDays;
  }

  /// Check if ready to complete
  bool get canComplete {
    if (status != ExperimentStatus.active) return false;
    if (interventionStartedAt == null) return false;
    final interventionDay = DateTime.now().difference(interventionStartedAt!).inDays + 1;
    return interventionDay > interventionDays;
  }
}

/// Results from analyzing an experiment
@JsonSerializable()
class ExperimentResults {
  final String experimentId;
  final DateTime analyzedAt;

  // Baseline statistics
  final double baselineMean;
  final double baselineStdDev;
  final int baselineN;

  // Intervention statistics
  final double interventionMean;
  final double interventionStdDev;
  final int interventionN;

  // Effect measures
  final double effectSize;      // Cohen's d
  final double percentChange;   // ((intervention - baseline) / baseline) * 100

  @EffectDirectionConverter()
  final EffectDirection direction;

  // Confidence
  final double confidenceLevel; // 0.0 to 1.0

  @SignificanceLevelConverter()
  final SignificanceLevel significance;

  // Interpretation
  final String summaryStatement;
  @JsonKey(defaultValue: [])
  final List<String> caveats;
  @JsonKey(defaultValue: [])
  final List<String> suggestions;

  ExperimentResults({
    required this.experimentId,
    DateTime? analyzedAt,
    required this.baselineMean,
    required this.baselineStdDev,
    required this.baselineN,
    required this.interventionMean,
    required this.interventionStdDev,
    required this.interventionN,
    required this.effectSize,
    required this.percentChange,
    required this.direction,
    required this.confidenceLevel,
    required this.significance,
    required this.summaryStatement,
    List<String>? caveats,
    List<String>? suggestions,
  })  : analyzedAt = analyzedAt ?? DateTime.now(),
        caveats = caveats ?? [],
        suggestions = suggestions ?? [];

  factory ExperimentResults.fromJson(Map<String, dynamic> json) =>
      _$ExperimentResultsFromJson(json);
  Map<String, dynamic> toJson() => _$ExperimentResultsToJson(this);
}

/// Direction of the effect observed
enum EffectDirection {
  improved,   // Outcome increased (positive change)
  declined,   // Outcome decreased (negative change)
  noChange,   // No meaningful change
}

extension EffectDirectionExtension on EffectDirection {
  String get displayName {
    switch (this) {
      case EffectDirection.improved:
        return 'Improved';
      case EffectDirection.declined:
        return 'Declined';
      case EffectDirection.noChange:
        return 'No Change';
    }
  }

  String get emoji {
    switch (this) {
      case EffectDirection.improved:
        return '📈';
      case EffectDirection.declined:
        return '📉';
      case EffectDirection.noChange:
        return '➡️';
    }
  }
}

class EffectDirectionConverter implements JsonConverter<EffectDirection, String> {
  const EffectDirectionConverter();

  @override
  EffectDirection fromJson(String json) {
    final value = json.contains('.') ? json.split('.').last : json;
    return EffectDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EffectDirection.noChange,
    );
  }

  @override
  String toJson(EffectDirection direction) => direction.name;
}

/// Statistical significance level
enum SignificanceLevel {
  high,         // Strong evidence (effect size > 0.8, confidence > 80%)
  moderate,     // Moderate evidence (effect size 0.5-0.8)
  low,          // Weak evidence (effect size 0.2-0.5)
  insufficient, // Not enough data or negligible effect
}

extension SignificanceLevelExtension on SignificanceLevel {
  String get displayName {
    switch (this) {
      case SignificanceLevel.high:
        return 'Strong Evidence';
      case SignificanceLevel.moderate:
        return 'Moderate Evidence';
      case SignificanceLevel.low:
        return 'Weak Evidence';
      case SignificanceLevel.insufficient:
        return 'Insufficient Data';
    }
  }

  String get description {
    switch (this) {
      case SignificanceLevel.high:
        return 'The intervention likely has a meaningful effect';
      case SignificanceLevel.moderate:
        return 'The intervention may have an effect, consider extending';
      case SignificanceLevel.low:
        return 'Small effect detected, more data needed';
      case SignificanceLevel.insufficient:
        return 'Cannot draw conclusions from available data';
    }
  }
}

class SignificanceLevelConverter implements JsonConverter<SignificanceLevel, String> {
  const SignificanceLevelConverter();

  @override
  SignificanceLevel fromJson(String json) {
    final value = json.contains('.') ? json.split('.').last : json;
    return SignificanceLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SignificanceLevel.insufficient,
    );
  }

  @override
  String toJson(SignificanceLevel level) => level.name;
}

/// Note attached to an experiment
@JsonSerializable()
class ExperimentNote {
  final String id;
  final DateTime createdAt;
  final String content;

  @ExperimentNoteTypeConverter()
  final ExperimentNoteType type;

  ExperimentNote({
    String? id,
    DateTime? createdAt,
    required this.content,
    this.type = ExperimentNoteType.observation,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory ExperimentNote.fromJson(Map<String, dynamic> json) =>
      _$ExperimentNoteFromJson(json);
  Map<String, dynamic> toJson() => _$ExperimentNoteToJson(this);
}

enum ExperimentNoteType {
  observation,       // General observation
  confoundingFactor, // Something that might affect results
  adjustment,        // Change made to experiment
}

extension ExperimentNoteTypeExtension on ExperimentNoteType {
  String get displayName {
    switch (this) {
      case ExperimentNoteType.observation:
        return 'Observation';
      case ExperimentNoteType.confoundingFactor:
        return 'Confounding Factor';
      case ExperimentNoteType.adjustment:
        return 'Adjustment';
    }
  }

  String get emoji {
    switch (this) {
      case ExperimentNoteType.observation:
        return '👁️';
      case ExperimentNoteType.confoundingFactor:
        return '⚠️';
      case ExperimentNoteType.adjustment:
        return '🔧';
    }
  }
}

class ExperimentNoteTypeConverter implements JsonConverter<ExperimentNoteType, String> {
  const ExperimentNoteTypeConverter();

  @override
  ExperimentNoteType fromJson(String json) {
    final value = json.contains('.') ? json.split('.').last : json;
    return ExperimentNoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExperimentNoteType.observation,
    );
  }

  @override
  String toJson(ExperimentNoteType type) => type.name;
}
