// lib/services/backup_service.dart
// Export/Import service for backing up and restoring user data

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_io/io.dart';
import 'storage_service.dart';
import 'debug_service.dart';
import '../models/goal.dart';
import '../models/journal_entry.dart';
import '../models/checkin.dart';
import '../models/habit.dart';
import '../models/pulse_entry.dart';
import '../config/build_info.dart';

// Conditional import: web implementation when dart:html is available, stub otherwise
import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper.dart' as web_download;

class BackupService {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  /// Export all user data to a JSON file
  Future<String> _createBackupJson() async {
    // Load all data
    final goals = await _storage.loadGoals();
    final journalEntries = await _storage.loadJournalEntries();
    final checkin = await _storage.loadCheckin();
    final habits = await _storage.loadHabits();
    final pulseEntries = await _storage.loadPulseEntries();
    final settings = await _storage.loadSettings();

    // Remove sensitive data (API key) from export
    final exportSettings = Map<String, dynamic>.from(settings);
    exportSettings.remove('claudeApiKey');

    // Create backup data structure
    final backupData = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'buildInfo': {
        'gitCommit': BuildInfo.gitCommitHash,
        'gitCommitShort': BuildInfo.gitCommitShort,
        'buildTimestamp': BuildInfo.buildTimestamp,
      },
      'data': {
        'goals': goals.map((g) => g.toJson()).toList(),
        'journalEntries': journalEntries.map((e) => e.toJson()).toList(),
        'checkin': checkin?.toJson(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'pulseEntries': pulseEntries.map((m) => m.toJson()).toList(),
        'settings': exportSettings,
      },
      'statistics': {
        'totalGoals': goals.length,
        'totalJournalEntries': journalEntries.length,
        'totalHabits': habits.length,
        'totalPulseEntries': pulseEntries.length,
      },
    };

    // Convert to JSON string (pretty printed for readability)
    return JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Export backup for mobile (uses file picker to let user choose location)
  Future<String?> _exportBackupMobile() async {
    try {
      debugPrint('📦 Starting mobile backup export...');
      final jsonString = await _createBackupJson();
      debugPrint('✓ Backup JSON created (${jsonString.length} bytes)');

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'habits_backup_$timestamp.json';
      debugPrint('📁 Suggested filename: $filename');

      // Convert string to bytes (required for Android/iOS)
      final bytes = utf8.encode(jsonString);
      debugPrint('📊 Converted to bytes: ${bytes.length} bytes');

      // Use file picker in save mode - lets user choose where to save
      // On Android/iOS, bytes must be provided
      debugPrint('🔍 Opening file picker dialog...');
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      debugPrint('📂 File picker result: ${outputPath ?? "null (cancelled)"}');

      if (outputPath == null) {
        // User cancelled
        debugPrint('⚠️ Backup export cancelled by user');
        return null;
      }

      debugPrint('✓ Backup saved successfully: $outputPath (${bytes.length} bytes)');
      return outputPath;
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Export failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      debugPrint('❌ Error creating backup: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Export backup for web (triggers download)
  Future<bool> _exportBackupWeb() async {
    try {
      final jsonString = await _createBackupJson();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'habits_backup_$timestamp.json';

      // Use web download helper (conditionally compiled)
      web_download.downloadFile(jsonString, filename);

      debugPrint('✓ Backup downloaded: $filename');
      return true;
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Web export failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      debugPrint('Error creating backup: $e');
      return false;
    }
  }

  /// Export the backup file (platform-aware)
  /// Returns BackupResult with success status and optional file path
  Future<BackupResult> exportBackup() async {
    try {
      await _debug.info('BackupService', 'Starting data export', metadata: {'platform': kIsWeb ? 'web' : 'mobile'});

      if (kIsWeb) {
        // Web: Download directly
        final success = await _exportBackupWeb();
        return BackupResult(
          success: success,
          message: success ? 'Backup downloaded successfully' : 'Backup download failed',
        );
      } else {
        // Mobile: Let user choose save location
        final savedPath = await _exportBackupMobile();
        if (savedPath == null) {
          return BackupResult(
            success: false,
            message: 'Backup export cancelled',
          );
        }

        final file = File(savedPath);
        final fileSize = await file.length();

        await _debug.info(
          'BackupService',
          'Export successful',
          metadata: {
            'file_size_kb': fileSize ~/ 1024,
            'saved_path': savedPath,
          },
        );

        return BackupResult(
          success: true,
          message: 'Backup saved successfully',
          filePath: savedPath,
        );
      }
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      return BackupResult(
        success: false,
        message: 'Error exporting backup: ${e.toString()}',
      );
    }
  }

  /// Import data from a backup file
  Future<ImportResult> importBackup() async {
    try {
      await _debug.info('BackupService', 'Starting import');

      // Let user pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Important for web
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'No file selected');
      }

      final pickedFile = result.files.single;

      // Get file contents (works for both web and mobile)
      String jsonString;
      if (kIsWeb) {
        // Web: Use bytes from memory
        if (pickedFile.bytes == null) {
          return ImportResult(success: false, message: 'Could not read file');
        }
        jsonString = utf8.decode(pickedFile.bytes!);
      } else {
        // Mobile: Read from file path
        if (pickedFile.path == null) {
          return ImportResult(success: false, message: 'Invalid file path');
        }
        final file = File(pickedFile.path!);
        jsonString = await file.readAsString();
      }

      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (!backupData.containsKey('version') || !backupData.containsKey('data')) {
        return ImportResult(
          success: false,
          message: 'Invalid backup file format',
        );
      }

      final data = backupData['data'] as Map<String, dynamic>;

      // Import data (overwrite existing)
      await _importData(data);

      final stats = backupData['statistics'] as Map<String, dynamic>?;
      await _debug.info(
        'BackupService',
        'Import successful',
        metadata: {
          'version': backupData['version'],
          'exported_at': backupData['exportedAt'],
          'goals': stats?['totalGoals'],
          'journal_entries': stats?['totalJournalEntries'],
          'habits': stats?['totalHabits'],
          'blockers': stats?['totalBlockers'],
          'pulse_entries': stats?['totalPulseEntries'],
        },
      );

      return ImportResult(
        success: true,
        message: 'Backup restored successfully!',
        statistics: stats,
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'BackupService',
        'Import failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return ImportResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  Future<void> _importData(Map<String, dynamic> data) async {
    // Import goals
    if (data.containsKey('goals')) {
      final goalsJson = data['goals'] as List;
      final goals = goalsJson.map((json) => Goal.fromJson(json)).toList();
      await _storage.saveGoals(goals);
    }

    // Import journal entries
    if (data.containsKey('journalEntries')) {
      final entriesJson = data['journalEntries'] as List;
      final entries = entriesJson.map((json) => JournalEntry.fromJson(json)).toList();
      await _storage.saveJournalEntries(entries);
    }

    // Import check-in
    if (data.containsKey('checkin') && data['checkin'] != null) {
      final checkin = Checkin.fromJson(data['checkin']);
      await _storage.saveCheckin(checkin);
    }

    // Import habits
    if (data.containsKey('habits')) {
      final habitsJson = data['habits'] as List;
      final habits = habitsJson.map((json) => Habit.fromJson(json)).toList();
      await _storage.saveHabits(habits);
    }

    // Import pulse entries (support both new and old key names)
    if (data.containsKey('pulseEntries')) {
      final pulseEntriesJson = data['pulseEntries'] as List;
      final pulseEntries = pulseEntriesJson.map((json) => PulseEntry.fromJson(json)).toList();
      await _storage.savePulseEntries(pulseEntries);
    } else if (data.containsKey('moodEntries')) {
      // Backward compatibility: support old exports
      final pulseEntriesJson = data['moodEntries'] as List;
      final pulseEntries = pulseEntriesJson.map((json) => PulseEntry.fromJson(json)).toList();
      await _storage.savePulseEntries(pulseEntries);
    }

    // Import settings (excluding API key which should not be in export)
    if (data.containsKey('settings')) {
      final exportedSettings = data['settings'] as Map<String, dynamic>;
      final currentSettings = await _storage.loadSettings();

      // Merge: keep current API key, import other settings
      final mergedSettings = {
        ...exportedSettings,
        'claudeApiKey': currentSettings['claudeApiKey'], // Keep current API key
      };

      await _storage.saveSettings(mergedSettings);
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? statistics;

  ImportResult({
    required this.success,
    required this.message,
    this.statistics,
  });
}

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}
