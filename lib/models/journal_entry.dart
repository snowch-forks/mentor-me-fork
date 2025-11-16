import 'package:uuid/uuid.dart';

enum JournalEntryType {
  quickNote,
  guidedJournal,
  structuredJournal,
}

/// Data model for journal entries.
///
/// Supports three types of journal entries:
/// - Quick Notes: Simple text-based journal entries
/// - Guided Journals: AI-guided reflection with Q&A pairs
/// - Structured Journals: Template-based entries with structured data
///
/// **JSON Schema:** lib/schemas/v2.json#definitions/journalEntry_v2
/// **Schema Version:** 2 (current)
/// **Export Format:** lib/services/backup_service.dart (journal_entries field)
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.
class JournalEntry {
  final String id;
  final DateTime createdAt;
  final JournalEntryType type;
  final String? reflectionType; // e.g., 'onboarding', 'checkin', 'general', null for quick notes
  final String? content; // For quick notes
  final List<QAPair>? qaPairs; // For guided journaling
  final List<String> goalIds; // Related goals
  final Map<String, String>? aiInsights; // AI-generated insights
  final String? structuredSessionId; // For structured journaling
  final Map<String, dynamic>? structuredData; // Extracted structured data for analytics

  JournalEntry({
    String? id,
    DateTime? createdAt,
    required this.type,
    this.reflectionType,
    this.content,
    this.qaPairs,
    List<String>? goalIds,
    this.aiInsights,
    this.structuredSessionId,
    this.structuredData,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        goalIds = goalIds ?? [],
        assert(
          (type == JournalEntryType.quickNote && content != null) ||
          (type == JournalEntryType.guidedJournal && qaPairs != null) ||
          (type == JournalEntryType.structuredJournal && structuredSessionId != null),
          'Quick notes must have content, guided journals must have qaPairs, structured journals must have structuredSessionId',
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
      'structuredSessionId': structuredSessionId,
      'structuredData': structuredData,
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
      structuredSessionId: json['structuredSessionId'],
      structuredData: json['structuredData'] != null
          ? Map<String, dynamic>.from(json['structuredData'])
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