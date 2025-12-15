// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExperimentEntry _$ExperimentEntryFromJson(Map<String, dynamic> json) =>
    ExperimentEntry(
      id: json['id'] as String?,
      experimentId: json['experimentId'] as String,
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
      phase: const ExperimentPhaseConverter().fromJson(json['phase'] as String),
      interventionApplied: json['interventionApplied'] as bool?,
      interventionTime: json['interventionTime'] == null
          ? null
          : DateTime.parse(json['interventionTime'] as String),
      interventionDuration: (json['interventionDuration'] as num?)?.toInt(),
      interventionIntensity: (json['interventionIntensity'] as num?)?.toInt(),
      outcomeValue: (json['outcomeValue'] as num?)?.toInt(),
      outcomeTime: json['outcomeTime'] == null
          ? null
          : DateTime.parse(json['outcomeTime'] as String),
      linkedPulseEntryId: json['linkedPulseEntryId'] as String?,
      notes: json['notes'] as String?,
      hasConfoundingFactors: json['hasConfoundingFactors'] as bool? ?? false,
    );

Map<String, dynamic> _$ExperimentEntryToJson(ExperimentEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'experimentId': instance.experimentId,
      'date': instance.date.toIso8601String(),
      'phase': const ExperimentPhaseConverter().toJson(instance.phase),
      'interventionApplied': instance.interventionApplied,
      'interventionTime': instance.interventionTime?.toIso8601String(),
      'interventionDuration': instance.interventionDuration,
      'interventionIntensity': instance.interventionIntensity,
      'outcomeValue': instance.outcomeValue,
      'outcomeTime': instance.outcomeTime?.toIso8601String(),
      'linkedPulseEntryId': instance.linkedPulseEntryId,
      'notes': instance.notes,
      'hasConfoundingFactors': instance.hasConfoundingFactors,
    };
