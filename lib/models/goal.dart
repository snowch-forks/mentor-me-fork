import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'milestone.dart';

enum GoalStatus {
  active,     // Currently working on (max 2)
  backlog,    // Planning to do later
  completed,  // Successfully finished
  abandoned,  // Decided not to pursue
}

class Goal {
  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final DateTime createdAt;
  final DateTime? targetDate;
  final List<String> milestones;
  final List<Milestone> milestonesDetailed;
  final int currentProgress;
  bool isActive;  // Deprecated: Use status instead
  final GoalStatus status;
  
  Goal({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    DateTime? createdAt,
    this.targetDate,
    List<String>? milestones,
    List<Milestone>? milestonesDetailed,
    this.currentProgress = 0,
    this.isActive = true,  // Deprecated
    this.status = GoalStatus.active,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        milestones = milestones ?? [],
        milestonesDetailed = milestonesDetailed ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'milestones': milestones,
      'milestonesDetailed': milestonesDetailed.map((m) => m.toJson()).toList(),
      'currentProgress': currentProgress,
      'isActive': isActive,
      'status': status.toString(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    // Parse status, defaulting to active for backwards compatibility
    GoalStatus parsedStatus = GoalStatus.active;
    if (json['status'] != null) {
      parsedStatus = GoalStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => GoalStatus.active,
      );
    }

    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: GoalCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
      milestones: List<String>.from(json['milestones'] ?? []),
      milestonesDetailed: (json['milestonesDetailed'] as List?)
          ?.map((m) => Milestone.fromJson(m))
          .toList() ?? [],
      currentProgress: json['currentProgress'] ?? 0,
      isActive: json['isActive'] ?? true,
      status: parsedStatus,
    );
  }

  Goal copyWith({
    String? title,
    String? description,
    GoalCategory? category,
    DateTime? targetDate,
    List<String>? milestones,
    List<Milestone>? milestonesDetailed,
    int? currentProgress,
    bool? isActive,
    GoalStatus? status,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt,
      targetDate: targetDate ?? this.targetDate,
      milestones: milestones ?? this.milestones,
      milestonesDetailed: milestonesDetailed ?? this.milestonesDetailed,
      currentProgress: currentProgress ?? this.currentProgress,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
    );
  }
}

enum GoalCategory {
  health,
  fitness,
  career,
  learning,
  relationships,
  finance,
  personal,
  other,
}

extension GoalCategoryExtension on GoalCategory {
  String get displayName {
    switch (this) {
      case GoalCategory.health:
        return 'Health & Wellness';
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.learning:
        return 'Learning';
      case GoalCategory.relationships:
        return 'Relationships';
      case GoalCategory.finance:
        return 'Finance';
      case GoalCategory.personal:
        return 'Personal Development';
      case GoalCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalCategory.health:
        return Icons.favorite;
      case GoalCategory.fitness:
        return Icons.fitness_center;
      case GoalCategory.career:
        return Icons.work;
      case GoalCategory.learning:
        return Icons.school;
      case GoalCategory.relationships:
        return Icons.people;
      case GoalCategory.finance:
        return Icons.attach_money;
      case GoalCategory.personal:
        return Icons.self_improvement;
      case GoalCategory.other:
        return Icons.more_horiz;
    }
  }
}
