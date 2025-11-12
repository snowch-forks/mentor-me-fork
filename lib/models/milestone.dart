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

  Milestone({
    String? id,
    required this.goalId,
    required this.title,
    required this.description,
    this.targetDate,
    this.completedDate,
    required this.order,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

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
    };
  }

  factory Milestone.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
