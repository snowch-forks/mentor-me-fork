// test/bdd_test_runner.dart
// BDD test runner for Gherkin feature tests
//
// Run with: flutter test test/bdd_test_runner.dart

import 'dart:async';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:glob/glob.dart';

// Import all step definitions
import 'steps/common_steps.dart';
import 'steps/goal_steps.dart';
import 'steps/backup_restore_steps.dart';

/// Custom test configuration for MentorMe BDD tests
class MentorMeTestConfiguration extends FlutterTestConfiguration {
  MentorMeTestConfiguration()
      : super(
          // Specify feature files to run
          features: [
            Glob(r'test/features/**.feature'),
          ],
          // Register step definitions
          stepDefinitions: [
            // Common steps (used across features)
            GivenTheAppIsRunning(),
            GivenIAmOnHomeScreen(),
            WhenITapOn(),
            WhenITapGoalToViewDetails(),
            WhenINavigateToGoalDetails(),
            WhenITapMenuButton(),
            WhenISelect(),
            WhenIConfirmDeletion(),
            WhenIWaitForAIGeneration(),
            WhenICloseApp(),
            WhenIRestartApp(),
            ThenIShouldSee(),
            ThenIShouldSeeAtLeastMilestones(),
            ThenMilestonesShouldHaveTitleAndDescription(),
            ThenShouldNotAppearInList(),
            ThenShouldNotAppearInActiveGoals(),
            ThenGoalShouldAppearIn(),
            ThenIShouldStillSeeAllGoals(),
            ThenDataShouldBePreserved(),
            ThenGoalShouldBeTaggedWithCategory(),
            ThenIShouldBeAbleToFilterBy(),

            // Goal-specific steps
            GivenIHaveAnActiveGoal(),
            GivenIHaveAGoalWithMilestones(),
            GivenIHaveAGoalWithProgress(),
            WhenINavigateToGoalsScreen(),
            WhenITapButton(),
            WhenIEnterGoalTitle(),
            WhenIEnterDescription(),
            WhenISelectCategory(),
            WhenIAddMilestones(),
            WhenIMarkMilestoneComplete(),
            WhenICreateGoalInCategory(),
            ThenIShouldSeeGoalInList(),
            ThenGoalStatusShouldBe(),
            ThenGoalProgressShouldBe(),
            ThenGoalShouldHaveMilestones(),
            ThenAllMilestonesShouldBeIncomplete(),
            ThenMilestoneShouldBeCompleted(),
            ThenGoalShouldHaveCompletionDate(),

            // Backup/Restore steps
            GivenIHaveTestData(),
            GivenIHaveConfiguredApiKey(),
            GivenIHaveConfiguredHfToken(),
            GivenIHaveActiveGoals(),
            GivenIHaveJournalEntriesLinkedToGoal(),
            GivenIHaveHabitsWithCompletionHistory(),
            GivenIHaveInvalidBackupFile(),
            GivenIHaveUnsupportedSchemaBackup(),
            GivenIAmNewUserWithNoData(),
            GivenIHaveMinimalBackupFile(),
            GivenIHaveVariousData(),
            GivenIAmOnWebPlatform(),
            GivenIAmOnAndroidPlatform(),
            GivenIHaveExistingData(),
            GivenIHaveBackupFileReady(),
            GivenIHaveConfiguredSettings(),
            GivenIHaveBackupFromSchemaVersion(),
            GivenIHaveCorruptedBackupFile(),
            GivenIHaveVariousDataInApp(),
            WhenINavigateToBackupRestoreScreen(),
            WhenISaveBackupFile(),
            WhenIClearAllAppData(),
            WhenISelectSavedBackupFile(),
            WhenIExportAndRestoreData(),
            WhenIExportBackup(),
            WhenIExportBackupAs(),
            WhenIImportNamedBackup(),
            WhenIOpenBackupFile(),
            WhenIConfirmImport(),
            ThenAllGoalsShouldBeRestored(),
            ThenAllHabitsShouldBeRestored(),
            ThenAllJournalEntriesShouldBeRestored(),
            ThenAllPulseEntriesShouldBeRestored(),
            ThenAllPulseTypesShouldBeRestored(),
            ThenSchemaVersionShouldMatch(),
            ThenBackupShouldNotContain(),
            ThenBackupShouldContainGoals(),
            ThenNoDataShouldBeModified(),
            ThenExistingDataShouldRemainIntact(),
            ThenMilestonesShouldBeCompleted(),
            ThenGoalProgressShouldBePercent(),
            ThenJournalEntriesLinkedToGoal(),
            ThenHabitCompletionHistoryShouldBePreserved(),
            ThenBackupMetadataShouldContain(),
            ThenBackupShouldIncludeExportDate(),
            ThenBackupShouldIncludeBuildInfo(),
            ThenIShouldSeeVariousData(),
            ThenFileShouldBeValidJson(),
            ThenJsonShouldPassSchemaValidation(),
            ThenAllSettingsShouldBePreserved(),
            ThenApiKeyShouldNotBeRestored(),
            ThenHfTokenShouldNotBeRestored(),
            ThenIShouldSeeErrorMessage(),
          ],
          // Reporters for test output
          reporters: [
            ProgressReporter(),
            TestRunSummaryReporter(),
            JsonReporter(path: './test_report/cucumber_report.json'),
          ],
          // Execution options
          order: ExecutionOrder.sequential,
          stopAfterTestFailed: false,
          // Tag expressions to filter tests
          // Examples:
          // - Run only critical tests: '@critical'
          // - Run integration tests: '@integration'
          // - Run specific feature: '@backup'
          // - Exclude slow tests: 'not @slow'
          tagExpression: null, // null = run all tests
          // Hooks for setup/teardown
          hooks: [
            MentorMeTestHooks(),
          ],
          // Custom parameters
          customStepParameterDefinitions: [],
        );
}

/// Test hooks for setup and teardown
class MentorMeTestHooks extends Hook {
  @override
  Future<void> onBeforeRun(TestConfiguration config) async {
    print('🚀 Starting MentorMe BDD Tests');
    print('━' * 80);
  }

  @override
  Future<void> onAfterRun(TestConfiguration config) async {
    print('━' * 80);
    print('✅ MentorMe BDD Tests Complete');

    // Clean up test context
    BackupTestContext.instance.reset();
  }

  @override
  Future<void> onBeforeScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    print('\n📋 Running: $scenario');

    // Reset test context before each scenario
    BackupTestContext.instance.reset();
  }

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    // Cleanup after scenario if needed
  }

  @override
  Future<void> onAfterStep(
    TestConfiguration config,
    String step,
    StepResult stepResult,
  ) async {
    // Log step results if needed
    if (stepResult.result == StepExecutionResult.fail ||
        stepResult.result == StepExecutionResult.error) {
      print('  ❌ FAILED: $step');
      if (stepResult.resultReason != null) {
        print('     Reason: ${stepResult.resultReason}');
      }
    }
  }
}

Future<void> main() {
  final config = MentorMeTestConfiguration();
  return GherkinRunner().execute(config);
}
