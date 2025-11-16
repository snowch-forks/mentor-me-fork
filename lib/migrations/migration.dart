/// Base class for data migrations
///
/// Each migration transforms data from one schema version to another.
/// Migrations are applied in order during app startup or data import.
abstract class Migration {
  /// The schema version this migration starts from
  int get fromVersion;

  /// The schema version this migration produces
  int get toVersion;

  /// Human-readable name for logging and debugging
  String get name;

  /// Description of what this migration does
  String get description;

  /// Apply the migration to the data
  ///
  /// Takes a map of all app data and returns the migrated version.
  /// Implementations should:
  /// - Be idempotent (safe to run multiple times)
  /// - Handle missing keys gracefully
  /// - Log errors without throwing (when possible)
  /// - Return the input unchanged if nothing to migrate
  Future<Map<String, dynamic>> migrate(Map<String, dynamic> data);

  /// Validate that this migration can be safely applied
  ///
  /// Returns true if the data is in the expected format for this migration.
  /// This is called before migrate() to fail fast on corrupted data.
  bool canMigrate(Map<String, dynamic> data) {
    // Default: check version matches
    final version = data['schemaVersion'] as int?;
    return version == fromVersion;
  }
}
