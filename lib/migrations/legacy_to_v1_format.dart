import 'dart:convert';
import 'package:mentor_me/migrations/migration.dart';

/// Migrates from legacy export format (pre-schema versioning) to v1 schema
///
/// Legacy format characteristics:
/// - Has "version" (string) instead of "schemaVersion" (int)
/// - Has "exportedAt" instead of "exportDate"
/// - Data is nested under "data" object
/// - Has "statistics" object (informational only)
/// - Enums already in full format (e.g., "GoalCategory.personal")
/// - Field names differ (e.g., "journalEntries" vs "journal_entries")
///
/// This migration transforms the legacy structure to match v1 schema:
/// - Flatten "data" object to root level
/// - Rename "version" → "schemaVersion" (convert to int 1)
/// - Rename "exportedAt" → "exportDate"
/// - Remove "statistics" field
/// - Keep enum values as-is (already in correct format)
/// - Rename fields to match v1 naming conventions
/// - Ensure data fields are JSON-encoded strings
class LegacyToV1FormatMigration extends Migration {
  @override
  String get name => 'LegacyToV1Format';

  @override
  String get description =>
      'Migrate legacy export format (pre-schema versioning) to v1 schema';

  @override
  int get fromVersion => 0; // Legacy format (no version)

  @override
  int get toVersion => 1;

  @override
  bool canMigrate(Map<String, dynamic> data) {
    // Legacy format has:
    // - "version" field (string like "1.0.0")
    // - "data" nested object
    // - No "schemaVersion" field
    return data.containsKey('version') &&
        data.containsKey('data') &&
        !data.containsKey('schemaVersion');
  }

  @override
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> legacyData) async {
    final data = legacyData['data'] as Map<String, dynamic>;

    // Extract and convert goals
    String? goalsJson;
    if (data.containsKey('goals') && data['goals'] != null) {
      final goals = data['goals'] as List;
      final cleanedGoals = goals.map((goal) => _cleanGoal(goal as Map<String, dynamic>)).toList();
      goalsJson = json.encode(cleanedGoals);
    }

    // Extract and convert journal entries
    String? journalEntriesJson;
    if (data.containsKey('journalEntries') && data['journalEntries'] != null) {
      final entries = data['journalEntries'] as List;
      final cleanedEntries = entries.map((entry) => _cleanJournalEntry(entry as Map<String, dynamic>)).toList();
      journalEntriesJson = json.encode(cleanedEntries);
    }

    // Extract and convert checkin (singular object in legacy)
    String? checkinsJson;
    if (data.containsKey('checkin') && data['checkin'] != null) {
      final checkin = _cleanCheckin(data['checkin'] as Map<String, dynamic>);
      checkinsJson = json.encode(checkin);
    }

    // Extract and convert habits
    String? habitsJson;
    if (data.containsKey('habits') && data['habits'] != null) {
      final habits = data['habits'] as List;
      final cleanedHabits = habits.map((habit) => _cleanHabit(habit as Map<String, dynamic>)).toList();
      habitsJson = json.encode(cleanedHabits);
    }

    // Extract and convert pulse entries
    String? pulseEntriesJson;
    if (data.containsKey('pulseEntries') && data['pulseEntries'] != null) {
      final pulseEntries = data['pulseEntries'] as List;
      final cleanedPulseEntries = pulseEntries.map((entry) => _cleanPulseEntry(entry as Map<String, dynamic>)).toList();
      pulseEntriesJson = json.encode(cleanedPulseEntries);
    }

    // Extract and convert pulse types
    String? pulseTypesJson;
    if (data.containsKey('pulseTypes') && data['pulseTypes'] != null) {
      final pulseTypes = data['pulseTypes'] as List;
      final cleanedPulseTypes = pulseTypes.map((type) => _cleanPulseType(type as Map<String, dynamic>)).toList();
      pulseTypesJson = json.encode(cleanedPulseTypes);
    }

    // Extract and convert conversations
    String? conversationsJson;
    if (data.containsKey('conversations') && data['conversations'] != null) {
      final conversations = data['conversations'] as List;
      final cleanedConversations = conversations.map((conv) => _cleanConversation(conv as Map<String, dynamic>)).toList();
      conversationsJson = json.encode(cleanedConversations);
    }

    // Extract and convert settings
    String? settingsJson;
    if (data.containsKey('settings') && data['settings'] != null) {
      final settings = _cleanSettings(data['settings'] as Map<String, dynamic>);
      settingsJson = json.encode(settings);
    }

    // Build v1 format structure
    final v1Data = <String, dynamic>{
      'schemaVersion': 1,
      'exportDate': legacyData['exportedAt'] ?? DateTime.now().toIso8601String(),
      'appVersion': legacyData['version'] ?? '1.0.0',
      'buildNumber': legacyData['buildInfo']?['gitCommitShort'] ?? 'unknown',
      'buildInfo': legacyData['buildInfo'] ?? {},

      // Data fields (JSON-encoded strings)
      'journal_entries': journalEntriesJson,
      'goals': goalsJson,
      'habits': habitsJson,
      'checkins': checkinsJson,
      'pulse_entries': pulseEntriesJson ?? json.encode([]),
      'pulse_types': pulseTypesJson,
      'conversations': conversationsJson,
      'chat_conversations': conversationsJson, // Support both names
      'settings': settingsJson,
      'custom_templates': null,
      'sessions': null,
      'enabled_templates': json.encode([]),
    };

    return v1Data;
  }

  /// Clean goal object - fix field names but keep enum values as-is
  Map<String, dynamic> _cleanGoal(Map<String, dynamic> goal) {
    final cleaned = Map<String, dynamic>.from(goal);

    // Note: DO NOT clean enum values - legacy format already has full enum strings
    // like "GoalCategory.personal" which is what fromJson expects

    // Remove redundant fields
    cleaned.remove('isActive'); // Derived from status
    cleaned.remove('milestones'); // Use milestonesDetailed instead

    // Clean milestones
    if (cleaned['milestonesDetailed'] != null) {
      final milestones = cleaned['milestonesDetailed'] as List;
      cleaned['milestonesDetailed'] = milestones.map((m) => _cleanMilestone(m as Map<String, dynamic>)).toList();
    }

    return cleaned;
  }

  /// Clean milestone object
  Map<String, dynamic> _cleanMilestone(Map<String, dynamic> milestone) {
    final cleaned = Map<String, dynamic>.from(milestone);
    // No enum values to clean in milestones currently
    return cleaned;
  }

  /// Clean journal entry object
  Map<String, dynamic> _cleanJournalEntry(Map<String, dynamic> entry) {
    final cleaned = Map<String, dynamic>.from(entry);

    // Note: DO NOT clean enum values - legacy format already has full enum strings
    // However, journal entry types might be plain strings like "quickNote" or "structuredJournal"
    // which is the format fromJson expects

    // Generate content for structured journals if missing
    // This prepares for v2 schema which requires structured journals to have content
    if (cleaned['type'] == 'structuredJournal' &&
        (cleaned['content'] == null || (cleaned['content'] as String).isEmpty)) {
      cleaned['content'] = _generateStructuredJournalContent(
        cleaned['structuredData'] as Map<String, dynamic>?,
      );
    }

    return cleaned;
  }

  /// Generate readable content from structured journal data
  ///
  /// Format: "emoji name\n\nField: Value"
  /// This matches the format expected by v2 schema
  String _generateStructuredJournalContent(Map<String, dynamic>? structuredData) {
    if (structuredData == null || structuredData.isEmpty) {
      return 'Structured entry';
    }

    final buffer = StringBuffer();

    // Detect if first entry is a template header (contains emoji)
    final firstKey = structuredData.keys.isNotEmpty ? structuredData.keys.first : null;
    bool hasHeader = false;

    if (firstKey != null && _hasEmoji(firstKey)) {
      // First entry is template header
      buffer.writeln(firstKey);
      buffer.writeln(); // Blank line after header
      hasHeader = true;
    }

    // Add each field from structured data
    int fieldIndex = 0;
    for (var entry in structuredData.entries) {
      final key = entry.key;
      final value = entry.value;

      // Skip the header if we already processed it
      if (hasHeader && fieldIndex == 0) {
        fieldIndex++;
        continue;
      }

      // Skip null or empty values
      if (value == null || value.toString().isEmpty) {
        fieldIndex++;
        continue;
      }

      // Format the field
      buffer.writeln('$key: $value');
      fieldIndex++;
    }

    return buffer.toString().trim();
  }

  /// Check if string contains emoji characters
  bool _hasEmoji(String text) {
    // Simple emoji detection - checks for common emoji code points
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }

  /// Clean checkin object
  Map<String, dynamic> _cleanCheckin(Map<String, dynamic> checkin) {
    return Map<String, dynamic>.from(checkin);
  }

  /// Clean habit object - keep structure as-is
  Map<String, dynamic> _cleanHabit(Map<String, dynamic> habit) {
    final cleaned = Map<String, dynamic>.from(habit);

    // Note: DO NOT clean enum values - legacy format already has full enum strings
    // like "HabitFrequency.daily" which is what fromJson expects

    // Note: DO NOT convert completionDates to completions map
    // The current app uses completionDates as List<String> (ISO date strings)
    // Legacy format already has this in the correct format

    // Note: DO NOT remove isActive - even though deprecated, fromJson still requires it
    // fromJson line 99: isActive: json['isActive'] (no default value)

    return cleaned;
  }

  /// Clean pulse entry object
  Map<String, dynamic> _cleanPulseEntry(Map<String, dynamic> entry) {
    return Map<String, dynamic>.from(entry);
  }

  /// Clean pulse type object
  Map<String, dynamic> _cleanPulseType(Map<String, dynamic> type) {
    return Map<String, dynamic>.from(type);
  }

  /// Clean conversation object
  Map<String, dynamic> _cleanConversation(Map<String, dynamic> conversation) {
    final cleaned = Map<String, dynamic>.from(conversation);

    // Clean messages
    if (cleaned['messages'] != null) {
      final messages = cleaned['messages'] as List;
      cleaned['messages'] = messages.map((m) => _cleanMessage(m as Map<String, dynamic>)).toList();
    }

    return cleaned;
  }

  /// Clean message object
  Map<String, dynamic> _cleanMessage(Map<String, dynamic> message) {
    final cleaned = Map<String, dynamic>.from(message);

    // Note: DO NOT clean enum values - legacy format already has full enum strings
    // like "MessageSender.user" which is what fromJson expects

    return cleaned;
  }

  /// Clean settings object
  Map<String, dynamic> _cleanSettings(Map<String, dynamic> settings) {
    final cleaned = Map<String, dynamic>.from(settings);

    // Remove debug_logs (too large, not part of user settings)
    cleaned.remove('debug_logs');

    return cleaned;
  }
}
