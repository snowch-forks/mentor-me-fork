import 'package:mentor_me/migrations/migration.dart';
import 'package:mentor_me/migrations/legacy_to_v1_format.dart';
import 'package:mentor_me/migrations/v1_to_v2_journal_content.dart';
import 'package:mentor_me/services/debug_service.dart';

/// Service for managing data schema migrations
///
/// This service:
/// - Tracks the current schema version
/// - Applies migrations in order when needed
/// - Validates data before and after migration
/// - Handles both storage loads and data imports
/// - Supports legacy format (pre-schema versioning) migration
class MigrationService {
  /// Current schema version (increment when data model changes)
  static const int CURRENT_SCHEMA_VERSION = 2;

  final _debug = DebugService();

  /// Registry of all migrations in order
  ///
  /// Add new migrations to this list as the schema evolves.
  /// Migrations will be applied in the order they appear here.
  ///
  /// Note: LegacyToV1 is handled separately via migrateLegacy() method
  final List<Migration> _migrations = [
    V1ToV2JournalContentMigration(),
    // Future migrations go here:
    // V2ToV3PulseMetricsMigration(),
    // V3ToV4GoalCategoriesMigration(),
  ];

  /// Migrate data from any version to the current version
  ///
  /// This is called:
  /// - On app startup (via StorageService)
  /// - When importing backup data
  ///
  /// Returns the migrated data with schemaVersion updated.
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> data) async {
    final startVersion = data['schemaVersion'] as int? ?? 1;

    await _debug.info(
      'MigrationService',
      'Starting migration from v$startVersion to v$CURRENT_SCHEMA_VERSION',
    );

    // Already up to date
    if (startVersion == CURRENT_SCHEMA_VERSION) {
      await _debug.info(
        'MigrationService',
        'Data already at current version, no migration needed',
      );
      return data;
    }

    // Version is newer than current app version
    if (startVersion > CURRENT_SCHEMA_VERSION) {
      final error =
          'Data is from a newer app version (v$startVersion). Current version is v$CURRENT_SCHEMA_VERSION. Please update the app.';
      await _debug.error('MigrationService', error);
      throw Exception(error);
    }

    // Apply migrations in order
    var migratedData = data;
    var currentVersion = startVersion;

    for (final migration in _migrations) {
      // Skip migrations that don't apply to this version range
      if (migration.fromVersion < currentVersion) {
        continue;
      }
      if (migration.toVersion > CURRENT_SCHEMA_VERSION) {
        break;
      }

      // Check if migration can be applied
      if (!migration.canMigrate(migratedData)) {
        final error =
            'Migration ${migration.name} cannot be applied. Data may be corrupted.';
        await _debug.error('MigrationService', error);
        throw Exception(error);
      }

      // Apply the migration
      await _debug.info(
        'MigrationService',
        'Applying migration: ${migration.name} (v${migration.fromVersion} → v${migration.toVersion})',
      );

      try {
        migratedData = await migration.migrate(migratedData);
        currentVersion = migration.toVersion;
        migratedData['schemaVersion'] = currentVersion;

        await _debug.info(
          'MigrationService',
          'Successfully applied ${migration.name}',
        );
      } catch (e, stackTrace) {
        await _debug.error(
          'MigrationService',
          'Failed to apply migration ${migration.name}',
          stackTrace: stackTrace.toString(),
        );
        throw Exception('Migration ${migration.name} failed: $e');
      }
    }

    // Ensure we reached the target version
    if (currentVersion != CURRENT_SCHEMA_VERSION) {
      final error =
          'Migration incomplete. Reached v$currentVersion but expected v$CURRENT_SCHEMA_VERSION';
      await _debug.error('MigrationService', error);
      throw Exception(error);
    }

    await _debug.info(
      'MigrationService',
      'Migration complete: v$startVersion → v$CURRENT_SCHEMA_VERSION',
    );

    return migratedData;
  }

  /// Get the expected version for new data
  int getCurrentVersion() => CURRENT_SCHEMA_VERSION;

  /// Check if a version is supported by this app
  bool isSupportedVersion(int version) {
    return version >= 1 && version <= CURRENT_SCHEMA_VERSION;
  }

  /// Get list of all migrations for debugging
  List<String> getMigrationHistory() {
    return _migrations
        .map((m) => '${m.name}: v${m.fromVersion} → v${m.toVersion}')
        .toList();
  }

  /// Get all registered migrations (for testing)
  List<Migration> getMigrations() => _migrations;

  /// Detect if data is in legacy format (pre-schema versioning)
  ///
  /// Legacy format characteristics:
  /// - Has "version" field (string) instead of "schemaVersion" (int)
  /// - Has "data" nested object
  /// - No "schemaVersion" field
  bool isLegacyFormat(Map<String, dynamic> data) {
    return data.containsKey('version') &&
        data.containsKey('data') &&
        !data.containsKey('schemaVersion');
  }

  /// Migrate legacy format to v1, then continue to current version
  ///
  /// This is called when importing old backup files that were created
  /// before the schema versioning system was implemented.
  Future<Map<String, dynamic>> migrateLegacy(Map<String, dynamic> legacyData) async {
    await _debug.info(
      'MigrationService',
      'Detected legacy format, migrating to v1...',
    );

    final legacyMigration = LegacyToV1FormatMigration();

    if (!legacyMigration.canMigrate(legacyData)) {
      final error = 'Data does not appear to be in valid legacy format';
      await _debug.error('MigrationService', error);
      throw Exception(error);
    }

    try {
      // Migrate legacy → v1
      final v1Data = await legacyMigration.migrate(legacyData);

      await _debug.info(
        'MigrationService',
        'Successfully migrated legacy format to v1',
      );

      // Now migrate v1 → current version (if needed)
      if (CURRENT_SCHEMA_VERSION > 1) {
        return await migrate(v1Data);
      }

      return v1Data;
    } catch (e, stackTrace) {
      await _debug.error(
        'MigrationService',
        'Failed to migrate legacy format: $e',
        stackTrace: stackTrace.toString(),
      );
      throw Exception('Legacy migration failed: $e');
    }
  }
}
