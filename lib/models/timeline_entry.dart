// lib/models/timeline_entry.dart
// Wrapper for unified timeline displaying both journal and pulse entries

import 'journal_entry.dart';
import 'pulse_entry.dart';

enum TimelineEntryType {
  journal,
  pulse,
}

class TimelineEntry {
  final TimelineEntryType type;
  final JournalEntry? journalEntry;
  final PulseEntry? pulseEntry;

  TimelineEntry.journal(this.journalEntry)
      : type = TimelineEntryType.journal,
        pulseEntry = null;

  TimelineEntry.pulse(this.pulseEntry)
      : type = TimelineEntryType.pulse,
        journalEntry = null;

  /// Get the timestamp for sorting
  DateTime get timestamp {
    switch (type) {
      case TimelineEntryType.journal:
        return journalEntry!.createdAt;
      case TimelineEntryType.pulse:
        return pulseEntry!.timestamp;
    }
  }

  /// Get a unique ID
  String get id {
    switch (type) {
      case TimelineEntryType.journal:
        return 'journal_${journalEntry!.id}';
      case TimelineEntryType.pulse:
        return 'pulse_${pulseEntry!.id}';
    }
  }
}
