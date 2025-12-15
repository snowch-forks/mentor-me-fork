import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'experiment_entry.g.dart';

/// Phase of the experiment when an entry was recorded
enum ExperimentPhase {
  baseline,     // Before intervention
  intervention, // During intervention
}

extension ExperimentPhaseExtension on ExperimentPhase {
  String get displayName {
    switch (this) {
      case ExperimentPhase.baseline:
        return 'Baseline';
      case ExperimentPhase.intervention:
        return 'Intervention';
    }
  }

  String get emoji {
    switch (this) {
      case ExperimentPhase.baseline:
        return '📊';
      case ExperimentPhase.intervention:
        return '🧪';
    }
  }
}

class ExperimentPhaseConverter implements JsonConverter<ExperimentPhase, String> {
  const ExperimentPhaseConverter();

  @override
  ExperimentPhase fromJson(String json) {
    final value = json.contains('.') ? json.split('.').last : json;
    return ExperimentPhase.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExperimentPhase.baseline,
    );
  }

  @override
  String toJson(ExperimentPhase phase) => phase.name;
}

/// A single day's data entry for an experiment.
///
/// Records both:
/// - Whether the intervention was applied (for intervention phase)
/// - The outcome measurement value
///
/// **JSON Schema:** lib/schemas/v3.json (experiment_entries field)
/// **Export Format:** lib/services/backup_service.dart (experiment_entries field)
@JsonSerializable()
class ExperimentEntry {
  final String id;
  final String experimentId;
  final DateTime date;

  @ExperimentPhaseConverter()
  final ExperimentPhase phase;

  // Intervention tracking
  final bool? interventionApplied; // Did they do the intervention today?
  final DateTime? interventionTime; // When they did it
  final int? interventionDuration;  // Minutes, if applicable
  final int? interventionIntensity; // 1-5 scale, if applicable

  // Outcome measurement
  final int? outcomeValue;          // 1-5 scale from Pulse
  final DateTime? outcomeTime;      // When measured
  final String? linkedPulseEntryId; // Reference to actual pulse entry

  // Quality and notes
  final String? notes;
  final bool hasConfoundingFactors; // User flagged external influences

  ExperimentEntry({
    String? id,
    required this.experimentId,
    DateTime? date,
    required this.phase,
    this.interventionApplied,
    this.interventionTime,
    this.interventionDuration,
    this.interventionIntensity,
    this.outcomeValue,
    this.outcomeTime,
    this.linkedPulseEntryId,
    this.notes,
    this.hasConfoundingFactors = false,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  factory ExperimentEntry.fromJson(Map<String, dynamic> json) =>
      _$ExperimentEntryFromJson(json);
  Map<String, dynamic> toJson() => _$ExperimentEntryToJson(this);

  ExperimentEntry copyWith({
    String? experimentId,
    DateTime? date,
    ExperimentPhase? phase,
    bool? interventionApplied,
    DateTime? interventionTime,
    int? interventionDuration,
    int? interventionIntensity,
    int? outcomeValue,
    DateTime? outcomeTime,
    String? linkedPulseEntryId,
    String? notes,
    bool? hasConfoundingFactors,
  }) {
    return ExperimentEntry(
      id: id,
      experimentId: experimentId ?? this.experimentId,
      date: date ?? this.date,
      phase: phase ?? this.phase,
      interventionApplied: interventionApplied ?? this.interventionApplied,
      interventionTime: interventionTime ?? this.interventionTime,
      interventionDuration: interventionDuration ?? this.interventionDuration,
      interventionIntensity: interventionIntensity ?? this.interventionIntensity,
      outcomeValue: outcomeValue ?? this.outcomeValue,
      outcomeTime: outcomeTime ?? this.outcomeTime,
      linkedPulseEntryId: linkedPulseEntryId ?? this.linkedPulseEntryId,
      notes: notes ?? this.notes,
      hasConfoundingFactors: hasConfoundingFactors ?? this.hasConfoundingFactors,
    );
  }

  /// Check if this entry has a valid outcome measurement
  bool get hasOutcome => outcomeValue != null;

  /// Check if this entry has intervention data (only relevant for intervention phase)
  bool get hasInterventionData =>
      phase == ExperimentPhase.baseline || interventionApplied != null;

  /// Check if this entry is complete (has all required data for analysis)
  bool get isComplete {
    if (!hasOutcome) return false;
    if (phase == ExperimentPhase.intervention && interventionApplied == null) {
      return false;
    }
    return true;
  }

  /// Get a display-friendly date string
  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${date.month}/${date.day}';
  }
}
