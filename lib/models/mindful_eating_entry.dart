/// Standalone mindful eating entry for tracking eating awareness
///
/// Allows users to log mindfulness around eating without requiring
/// a full food entry with nutrition details.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'mindful_eating_entry.g.dart';

/// A standalone mindful eating check-in
@JsonSerializable()
class MindfulEatingEntry {
  final String id;
  final DateTime timestamp;

  // Before eating
  final int? hungerBefore; // 1-5 scale: 1=not hungry, 5=starving
  final List<String>? moodBefore; // Feelings before meal (multi-select)

  // After eating
  final int? fullnessAfter; // 1-5 scale: 1=still hungry, 5=overfull
  final List<String>? moodAfter; // Feelings after meal (multi-select)

  // Optional context
  final String? note; // Free-form note about the eating experience
  final String? linkedFoodEntryId; // Optional link to a FoodEntry

  MindfulEatingEntry({
    String? id,
    DateTime? timestamp,
    this.hungerBefore,
    this.moodBefore,
    this.fullnessAfter,
    this.moodAfter,
    this.note,
    this.linkedFoodEntryId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Auto-generated serialization
  factory MindfulEatingEntry.fromJson(Map<String, dynamic> json) =>
      _$MindfulEatingEntryFromJson(json);
  Map<String, dynamic> toJson() => _$MindfulEatingEntryToJson(this);

  MindfulEatingEntry copyWith({
    String? id,
    DateTime? timestamp,
    int? hungerBefore,
    List<String>? moodBefore,
    int? fullnessAfter,
    List<String>? moodAfter,
    String? note,
    String? linkedFoodEntryId,
  }) {
    return MindfulEatingEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      hungerBefore: hungerBefore ?? this.hungerBefore,
      moodBefore: moodBefore ?? this.moodBefore,
      fullnessAfter: fullnessAfter ?? this.fullnessAfter,
      moodAfter: moodAfter ?? this.moodAfter,
      note: note ?? this.note,
      linkedFoodEntryId: linkedFoodEntryId ?? this.linkedFoodEntryId,
    );
  }

  /// Get the date portion for grouping
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get date => DateTime(timestamp.year, timestamp.month, timestamp.day);

  /// Check if this entry has any "before" data
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasBeforeData =>
      hungerBefore != null || (moodBefore != null && moodBefore!.isNotEmpty);

  /// Check if this entry has any "after" data
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasAfterData =>
      fullnessAfter != null || (moodAfter != null && moodAfter!.isNotEmpty);

  /// Summary string for display
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get summary {
    final parts = <String>[];

    if (hungerBefore != null) {
      parts.add('Hunger: $hungerBefore/5');
    }
    if (fullnessAfter != null) {
      parts.add('Fullness: $fullnessAfter/5');
    }
    if (moodBefore != null && moodBefore!.isNotEmpty) {
      parts.add('Before: ${moodBefore!.join(", ")}');
    }
    if (moodAfter != null && moodAfter!.isNotEmpty) {
      parts.add('After: ${moodAfter!.join(", ")}');
    }

    return parts.isEmpty ? 'No data recorded' : parts.join(' · ');
  }
}
