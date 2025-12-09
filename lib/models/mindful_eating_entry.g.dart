// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mindful_eating_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MindfulEatingEntry _$MindfulEatingEntryFromJson(Map<String, dynamic> json) =>
    MindfulEatingEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      hungerBefore: (json['hungerBefore'] as num?)?.toInt(),
      moodBefore: (json['moodBefore'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      fullnessAfter: (json['fullnessAfter'] as num?)?.toInt(),
      moodAfter: (json['moodAfter'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      note: json['note'] as String?,
      linkedFoodEntryId: json['linkedFoodEntryId'] as String?,
    );

Map<String, dynamic> _$MindfulEatingEntryToJson(MindfulEatingEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'hungerBefore': instance.hungerBefore,
      'moodBefore': instance.moodBefore,
      'fullnessAfter': instance.fullnessAfter,
      'moodAfter': instance.moodAfter,
      'note': instance.note,
      'linkedFoodEntryId': instance.linkedFoodEntryId,
    };
