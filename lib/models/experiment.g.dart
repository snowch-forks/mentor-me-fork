// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Experiment _$ExperimentFromJson(Map<String, dynamic> json) => Experiment(
      id: json['id'] as String?,
      title: json['title'] as String,
      hypothesis: json['hypothesis'] as String,
      status: json['status'] == null
          ? ExperimentStatus.draft
          : const ExperimentStatusConverter()
              .fromJson(json['status'] as String),
      design: json['design'] == null
          ? ExperimentDesign.baselineIntervention
          : const ExperimentDesignConverter()
              .fromJson(json['design'] as String),
      interventionName: json['interventionName'] as String,
      interventionDescription: json['interventionDescription'] as String?,
      linkedHabitId: json['linkedHabitId'] as String?,
      outcomeName: json['outcomeName'] as String,
      pulseTypeName: json['pulseTypeName'] as String?,
      baselineDays: (json['baselineDays'] as num?)?.toInt() ?? 7,
      interventionDays: (json['interventionDays'] as num?)?.toInt() ?? 14,
      minimumDataPoints: (json['minimumDataPoints'] as num?)?.toInt() ?? 5,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      interventionStartedAt: json['interventionStartedAt'] == null
          ? null
          : DateTime.parse(json['interventionStartedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      linkedGoalId: json['linkedGoalId'] as String?,
      results: json['results'] == null
          ? null
          : ExperimentResults.fromJson(json['results'] as Map<String, dynamic>),
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => ExperimentNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ExperimentToJson(Experiment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'hypothesis': instance.hypothesis,
      'status': const ExperimentStatusConverter().toJson(instance.status),
      'design': const ExperimentDesignConverter().toJson(instance.design),
      'interventionName': instance.interventionName,
      'interventionDescription': instance.interventionDescription,
      'linkedHabitId': instance.linkedHabitId,
      'outcomeName': instance.outcomeName,
      'pulseTypeName': instance.pulseTypeName,
      'baselineDays': instance.baselineDays,
      'interventionDays': instance.interventionDays,
      'minimumDataPoints': instance.minimumDataPoints,
      'createdAt': instance.createdAt.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'interventionStartedAt':
          instance.interventionStartedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'linkedGoalId': instance.linkedGoalId,
      'results': instance.results,
      'notes': instance.notes,
    };

ExperimentResults _$ExperimentResultsFromJson(Map<String, dynamic> json) =>
    ExperimentResults(
      experimentId: json['experimentId'] as String,
      analyzedAt: json['analyzedAt'] == null
          ? null
          : DateTime.parse(json['analyzedAt'] as String),
      baselineMean: (json['baselineMean'] as num).toDouble(),
      baselineStdDev: (json['baselineStdDev'] as num).toDouble(),
      baselineN: (json['baselineN'] as num).toInt(),
      interventionMean: (json['interventionMean'] as num).toDouble(),
      interventionStdDev: (json['interventionStdDev'] as num).toDouble(),
      interventionN: (json['interventionN'] as num).toInt(),
      effectSize: (json['effectSize'] as num).toDouble(),
      percentChange: (json['percentChange'] as num).toDouble(),
      direction: const EffectDirectionConverter()
          .fromJson(json['direction'] as String),
      confidenceLevel: (json['confidenceLevel'] as num).toDouble(),
      significance: const SignificanceLevelConverter()
          .fromJson(json['significance'] as String),
      summaryStatement: json['summaryStatement'] as String,
      caveats: (json['caveats'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ExperimentResultsToJson(ExperimentResults instance) =>
    <String, dynamic>{
      'experimentId': instance.experimentId,
      'analyzedAt': instance.analyzedAt.toIso8601String(),
      'baselineMean': instance.baselineMean,
      'baselineStdDev': instance.baselineStdDev,
      'baselineN': instance.baselineN,
      'interventionMean': instance.interventionMean,
      'interventionStdDev': instance.interventionStdDev,
      'interventionN': instance.interventionN,
      'effectSize': instance.effectSize,
      'percentChange': instance.percentChange,
      'direction': const EffectDirectionConverter().toJson(instance.direction),
      'confidenceLevel': instance.confidenceLevel,
      'significance':
          const SignificanceLevelConverter().toJson(instance.significance),
      'summaryStatement': instance.summaryStatement,
      'caveats': instance.caveats,
      'suggestions': instance.suggestions,
    };

ExperimentNote _$ExperimentNoteFromJson(Map<String, dynamic> json) =>
    ExperimentNote(
      id: json['id'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      content: json['content'] as String,
      type: json['type'] == null
          ? ExperimentNoteType.observation
          : const ExperimentNoteTypeConverter()
              .fromJson(json['type'] as String),
    );

Map<String, dynamic> _$ExperimentNoteToJson(ExperimentNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'content': instance.content,
      'type': const ExperimentNoteTypeConverter().toJson(instance.type),
    };
