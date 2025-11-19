# MentorMe BDD Tests

This directory contains Behavior-Driven Development (BDD) tests using Gherkin syntax for MentorMe.

## Overview

BDD tests allow us to write tests in plain English using the **Given-When-Then** format, making them readable by both developers and non-technical stakeholders.

## Structure

```
test/
├── features/                      # Feature files (Gherkin .feature files)
│   ├── goal_management.feature    # Goal CRUD and milestone tests
│   └── backup_restore.feature     # Backup/restore comprehensive tests
├── steps/                         # Step definitions (Dart implementations)
│   ├── common_steps.dart          # Reusable steps across features
│   ├── goal_steps.dart            # Goal-specific step definitions
│   └── backup_restore_steps.dart  # Backup/restore step definitions
├── helpers/                       # Test helper utilities
│   └── backup_test_helper.dart    # BackupService test extension
├── bdd_test_runner.dart           # Main test runner configuration
└── BDD_README.md                  # This file
```

## Running BDD Tests

### Run All BDD Tests

```bash
flutter test test/bdd_test_runner.dart
```

### Run Specific Feature File

```bash
# Run only backup/restore tests
flutter test test/features/backup_restore.feature

# Run only goal management tests
flutter test test/features/goal_management.feature
```

### Run Tests by Tag

Tags allow you to filter tests by category:

```bash
# Run only critical tests
flutter test test/bdd_test_runner.dart --dart-define=TAG_EXPRESSION='@critical'

# Run only integration tests
flutter test test/bdd_test_runner.dart --dart-define=TAG_EXPRESSION='@integration'

# Run backup tests only
flutter test test/bdd_test_runner.dart --dart-define=TAG_EXPRESSION='@backup'

# Exclude slow tests
flutter test test/bdd_test_runner.dart --dart-define=TAG_EXPRESSION='not @slow'

# Combine tags (critical AND integration)
flutter test test/bdd_test_runner.dart --dart-define=TAG_EXPRESSION='@critical and @integration'
```

### Available Tags

| Tag | Purpose |
|-----|---------|
| `@critical` | Critical functionality that must always work |
| `@integration` | Integration tests (full app flows) |
| `@regression` | Regression tests (prevent past bugs) |
| `@security` | Security-sensitive tests (API keys, data leaks) |
| `@platform` | Platform-specific tests (web vs mobile) |
| `@performance` | Performance/load tests |
| `@error-handling` | Error handling scenarios |
| `@ui` | UI-specific tests |

## Writing New BDD Tests

### 1. Create a Feature File

Create a new `.feature` file in `test/features/`:

```gherkin
Feature: User Authentication
  As a user
  I want to securely log in
  So that I can access my personalized data

  Background:
    Given the app is running
    And I am on the home screen

  @critical @security
  Scenario: Successful login with valid credentials
    When I navigate to the login screen
    And I enter "user@example.com" as the email
    And I enter "password123" as the password
    And I tap the "Login" button
    Then I should see the dashboard
    And I should see "Welcome back!"

  @security @error-handling
  Scenario: Login fails with invalid credentials
    When I navigate to the login screen
    And I enter "wrong@example.com" as the email
    And I enter "wrongpassword" as the password
    And I tap the "Login" button
    Then I should see an error message "Invalid credentials"
    And I should still be on the login screen
```

### 2. Implement Step Definitions

Create corresponding step definitions in `test/steps/`:

```dart
// test/steps/auth_steps.dart
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

/// When: I enter "X" as the email
class WhenIEnterEmail extends When1<String> {
  @override
  Future<void> executeStep(String email) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.enterText(
      find.byKey(const Key('email_field')),
      email,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I enter {string} as the email');
}

/// Then: I should see the dashboard
class ThenIShouldSeeDashboard extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();
    expect(
      find.byKey(const Key('dashboard_screen')),
      findsOneWidget,
      reason: 'Should see dashboard screen',
    );
  }

  @override
  RegExp get pattern => RegExp(r'I should see the dashboard');
}
```

### 3. Register Steps in Test Runner

Add your new step definitions to `test/bdd_test_runner.dart`:

```dart
import 'steps/auth_steps.dart';

class MentorMeTestConfiguration extends FlutterTestConfiguration {
  MentorMeTestConfiguration()
      : super(
          stepDefinitions: [
            // ... existing steps
            WhenIEnterEmail(),
            ThenIShouldSeeDashboard(),
            // Add more here
          ],
          // ... rest of config
        );
}
```

## Backup/Restore Test Coverage

The `backup_restore.feature` file contains comprehensive tests for:

### Core Functionality
- ✅ Export and restore all data types (goals, habits, journals, pulse, etc.)
- ✅ Validate backup file structure and schema
- ✅ Handle corrupted or invalid backup files
- ✅ Migrate legacy schema versions

### Security
- ✅ Strip sensitive data (API keys, tokens) from exports
- ✅ Preserve API keys during import (don't overwrite user's current keys)

### Data Integrity
- ✅ Preserve complex relationships (goals ↔ milestones ↔ journals)
- ✅ Maintain habit completion history and streaks
- ✅ Preserve journal entry types (quick notes vs guided journaling)
- ✅ Maintain pulse/wellness metric configurations

### Edge Cases
- ✅ Handle empty data (new user with no content)
- ✅ Handle missing optional fields gracefully
- ✅ Handle special characters and Unicode in data
- ✅ Handle large datasets (100+ goals, 500+ journals)

### Platform-Specific
- ✅ Web platform downloads JSON file
- ✅ Android platform saves to file system
- ✅ File picker integration

### Error Handling
- ✅ Import validation errors
- ✅ Schema version mismatches
- ✅ Partial import failures
- ✅ User cancellation of operations

## Test Data Management

### Test Context

The `BackupTestContext` class maintains state between test steps:

```dart
class BackupTestContext {
  String? savedBackupJson;                    // Current backup JSON
  Map<String, String> namedBackups = {};      // Named backups (backup1, backup2)
  Map<String, dynamic>? backupData;           // Parsed backup data
  List<Goal> originalGoals = [];              // Original data for comparison
  // ... more fields
}
```

This allows steps to share data:

```gherkin
Given I have 3 goals
When I export a backup as "backup1"    # Saves to namedBackups['backup1']
And I add 2 more goals
When I export a backup as "backup2"    # Saves to namedBackups['backup2']
And I import "backup1"                 # Restores from namedBackups['backup1']
Then I should have 3 goals
```

### Test Helpers

The `backup_test_helper.dart` file provides:

- **`importBackupFromJson(jsonString)`** - Test-friendly import that bypasses file picker
- **`_importDataHelper()`** - Reusable data import logic

This allows tests to programmatically import backups without UI interaction.

## Best Practices

### 1. Use Descriptive Scenario Names

❌ **Bad:**
```gherkin
Scenario: Test backup
```

✅ **Good:**
```gherkin
Scenario: Backup preserves habit streaks and completion history
```

### 2. Tag Appropriately

```gherkin
@integration @critical @security
Scenario: Backup strips sensitive API keys
```

### 3. Use Background for Common Setup

```gherkin
Background:
  Given the app is running
  And I am on the home screen
```

This runs before EVERY scenario in the feature.

### 4. Use Data Tables for Multiple Items

```gherkin
Given I have the following test data:
  | Type            | Count |
  | Goals           | 3     |
  | Habits          | 2     |
  | Journal Entries | 5     |
```

### 5. Keep Scenarios Independent

Each scenario should be able to run in isolation. Don't rely on state from previous scenarios.

### 6. Use Scenario Outlines for Multiple Cases

```gherkin
Scenario Outline: Create goals in different categories
  When I create a goal "<title>" in category "<category>"
  Then the goal should be tagged with category "<category>"

  Examples:
    | title                | category  |
    | Morning meditation   | Personal  |
    | Launch startup       | Career    |
    | Run 5k race          | Health    |
```

## Debugging Failed Tests

### 1. Run with Verbose Output

```bash
flutter test test/bdd_test_runner.dart --verbose
```

### 2. Check Test Reports

After running tests, check:
```
test_report/cucumber_report.json
```

This contains detailed step-by-step results in JSON format.

### 3. Add Debug Logging

In step definitions:

```dart
@override
Future<void> executeStep(String input) async {
  print('DEBUG: Executing step with input: $input');
  // ... step implementation
}
```

### 4. Use Breakpoints

Set breakpoints in step definitions and run in debug mode:

```bash
flutter test test/bdd_test_runner.dart --debug
```

## Common Patterns

### Creating Test Data

```dart
/// Helper to create test goals
Future<void> _createTestGoals(int count) async {
  final storage = StorageService();
  final uuid = const Uuid();

  final goals = List.generate(count, (i) => Goal(
    id: uuid.v4(),
    title: 'Test Goal ${i + 1}',
    category: 'Personal',
    status: GoalStatus.active,
    createdAt: DateTime.now(),
    milestones: [],
  ));

  for (final goal in goals) {
    await storage.saveGoal(goal);
  }
}
```

### Waiting for Async Operations

```dart
@override
Future<void> executeStep(String input) async {
  final world = getWorld<FlutterWorld>();

  // Wait for widget to appear
  await world.appDriver.waitFor(find.text('Success'));

  // Wait for loading to finish
  await world.appDriver.waitForAbsent(
    find.byType(CircularProgressIndicator),
    timeout: const Duration(seconds: 10),
  );
}
```

### Verifying Data

```dart
@override
Future<void> executeStep(int expectedCount) async {
  final storage = StorageService();
  final goals = await storage.loadGoals();

  expect(
    goals.length,
    equals(expectedCount),
    reason: 'Should have exactly $expectedCount goals',
  );

  // Verify each goal has required fields
  for (final goal in goals) {
    expect(goal.id, isNotEmpty);
    expect(goal.title, isNotEmpty);
    expect(goal.createdAt, isNotNull);
  }
}
```

## Continuous Integration

BDD tests run automatically in GitHub Actions:

```yaml
# .github/workflows/flutter_test.yml
- name: Run BDD tests
  run: flutter test test/bdd_test_runner.dart

- name: Run critical BDD tests only (fast)
  run: flutter test test/bdd_test_runner.dart --dart-define=TAG_EXPRESSION='@critical'
```

## Contributing

When adding new features to MentorMe:

1. **Write BDD tests FIRST** (test-driven development)
2. Implement the feature
3. Ensure all tests pass
4. Update this README if adding new patterns

## Resources

- [Gherkin Syntax Reference](https://cucumber.io/docs/gherkin/reference/)
- [flutter_gherkin Documentation](https://pub.dev/packages/flutter_gherkin)
- [BDD Best Practices](https://cucumber.io/docs/bdd/)

## Questions?

If you have questions about BDD tests, check:
- This README
- Existing feature files for examples
- Step definitions for implementation patterns
- Project CLAUDE.md for testing strategy
