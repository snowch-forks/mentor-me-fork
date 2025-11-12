import 'package:uuid/uuid.dart';

enum JournalEntryType {
  quickNote,
  guidedJournal,
}

class JournalEntry {
  final String id;
  final DateTime createdAt;
  final JournalEntryType type;
  final String? reflectionType; // e.g., 'onboarding', 'checkin', 'general', null for quick notes
  final String? content; // For quick notes
  final List<QAPair>? qaPairs; // For guided journaling
  final List<String> goalIds; // Related goals
  final Map<String, String>? aiInsights; // AI-generated insights

  JournalEntry({
    String? id,
    DateTime? createdAt,
    required this.type,
    this.reflectionType,
    this.content,
    this.qaPairs,
    List<String>? goalIds,
    this.aiInsights,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        goalIds = goalIds ?? [],
        assert(
          (type == JournalEntryType.quickNote && content != null) ||
          (type == JournalEntryType.guidedJournal && qaPairs != null),
          'Quick notes must have content, guided journals must have qaPairs',
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'reflectionType': reflectionType,
      'content': content,
      'qaPairs': qaPairs?.map((pair) => pair.toJson()).toList(),
      'goalIds': goalIds,
      'aiInsights': aiInsights,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      type: JournalEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => JournalEntryType.quickNote,
      ),
      reflectionType: json['reflectionType'],
      content: json['content'],
      qaPairs: json['qaPairs'] != null
          ? (json['qaPairs'] as List)
              .map((pair) => QAPair.fromJson(pair))
              .toList()
          : null,
      goalIds: List<String>.from(json['goalIds'] ?? []),
      aiInsights: json['aiInsights'] != null
          ? Map<String, String>.from(json['aiInsights'])
          : null,
    );
  }
}

class QAPair {
  final String question;
  final String answer;

  QAPair({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }

  factory QAPair.fromJson(Map<String, dynamic> json) {
    return QAPair(
      question: json['question'],
      answer: json['answer'],
    );
  }
}