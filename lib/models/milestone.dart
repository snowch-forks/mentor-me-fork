import 'package:uuid/uuid.dart';

class Milestone {
  final String id;
  final String goalId;
  final String title;
  final String description;
  final DateTime? targetDate;
  final DateTime? completedDate;
  final int order;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;  // Last modification timestamp

  Milestone({
    String? id,
    required this.goalId,
    required this.title,
    required this.description,
    this.targetDate,
    this.completedDate,
    required this.order,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'description': description,
      'targetDate': targetDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'order': order,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Milestone.fromJson(Map<String, dynamic> json) {
    // Backward compatibility: use createdAt if available, else use DateTime.now()
    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now();

    return Milestone(
      id: json['id'],
      goalId: json['goalId'],
      title: json['title'],
      description: json['description'],
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
      order: json['order'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : createdAt, // Backward compatibility: use createdAt if updatedAt missing
    );
  }

  Milestone markComplete() {
    return copyWith(
      isCompleted: true,
      completedDate: DateTime.now(),
    );
  }

  Milestone copyWith({
    String? title,
    String? description,
    DateTime? targetDate,
    DateTime? completedDate,
    int? order,
    bool? isCompleted,
  }) {
    return Milestone(
      id: id,
      goalId: goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),  // Always update timestamp on modification
    );
  }
}
