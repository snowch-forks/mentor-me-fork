import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'MentorMe'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @backlog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get backlog;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @mentor.
  ///
  /// In en, this message translates to:
  /// **'Mentor'**
  String get mentor;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Title'**
  String get goalTitle;

  /// No description provided for @goalDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get goalDescription;

  /// No description provided for @goalCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get goalCategory;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoal;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @deleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get deleteGoal;

  /// No description provided for @noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get noGoals;

  /// No description provided for @createFirstGoal.
  ///
  /// In en, this message translates to:
  /// **'Create your first goal to get started!'**
  String get createFirstGoal;

  /// No description provided for @createYourFirstGoalToStartYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Create your first goal to start your journey'**
  String get createYourFirstGoalToStartYourJourney;

  /// No description provided for @activeGoals.
  ///
  /// In en, this message translates to:
  /// **'Active Goals'**
  String get activeGoals;

  /// No description provided for @focusOnOneToTwoGoalsForBetterResults.
  ///
  /// In en, this message translates to:
  /// **'Focus on 1-2 goals at a time for better results'**
  String get focusOnOneToTwoGoalsForBetterResults;

  /// No description provided for @noActiveGoalsMessage.
  ///
  /// In en, this message translates to:
  /// **'No active goals. Add a goal or move one from backlog.'**
  String get noActiveGoalsMessage;

  /// No description provided for @backlogGoals.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get backlogGoals;

  /// No description provided for @goalsYourePlanningToWorkOnLater.
  ///
  /// In en, this message translates to:
  /// **'Goals you\'re planning to work on later'**
  String get goalsYourePlanningToWorkOnLater;

  /// No description provided for @completedGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String completedGoalsCount(int count);

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get onTrack;

  /// No description provided for @avgProgress.
  ///
  /// In en, this message translates to:
  /// **'Avg Progress'**
  String get avgProgress;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @journalEntry.
  ///
  /// In en, this message translates to:
  /// **'Journal Entry'**
  String get journalEntry;

  /// No description provided for @addJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Journal Entry'**
  String get addJournalEntry;

  /// No description provided for @editJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Journal Entry'**
  String get editJournalEntry;

  /// No description provided for @noJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet'**
  String get noJournalEntries;

  /// No description provided for @writeFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Write your first entry to start reflecting!'**
  String get writeFirstEntry;

  /// No description provided for @searchEntries.
  ///
  /// In en, this message translates to:
  /// **'Search entries...'**
  String get searchEntries;

  /// No description provided for @entriesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{entry} other{entries}} this month · {weekCount} this week'**
  String entriesThisMonth(int count, int weekCount);

  /// No description provided for @compact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compact;

  /// No description provided for @defaultView.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultView;

  /// No description provided for @tipUseAiChatForDeeperInsights.
  ///
  /// In en, this message translates to:
  /// **'Tip: Use AI Chat for deeper insights and pattern analysis'**
  String get tipUseAiChatForDeeperInsights;

  /// No description provided for @noMatchingEntries.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get noMatchingEntries;

  /// No description provided for @tryAdjustingYourSearchOrFilter.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filter'**
  String get tryAdjustingYourSearchOrFilter;

  /// No description provided for @pulseCheck.
  ///
  /// In en, this message translates to:
  /// **'Pulse Check'**
  String get pulseCheck;

  /// No description provided for @justLogHowYouFeel.
  ///
  /// In en, this message translates to:
  /// **'Just log how you feel (10 sec)'**
  String get justLogHowYouFeel;

  /// No description provided for @quickEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick Entry'**
  String get quickEntry;

  /// No description provided for @fastSimpleNote.
  ///
  /// In en, this message translates to:
  /// **'Fast, simple note (30 sec)'**
  String get fastSimpleNote;

  /// No description provided for @guidedReflection.
  ///
  /// In en, this message translates to:
  /// **'Guided Reflection'**
  String get guidedReflection;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @stepByStepPrompts.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step prompts (3-5 min)'**
  String get stepByStepPrompts;

  /// No description provided for @howWouldYouLikeToReflect.
  ///
  /// In en, this message translates to:
  /// **'How would you like to reflect?'**
  String get howWouldYouLikeToReflect;

  /// No description provided for @reflect.
  ///
  /// In en, this message translates to:
  /// **'Reflect'**
  String get reflect;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'entry'**
  String get entry;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry?'**
  String get deleteEntryConfirm;

  /// No description provided for @deleteEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this journal entry. This action cannot be undone.'**
  String get deleteEntryMessage;

  /// No description provided for @guidedJournalEntriesCannotBeEdited.
  ///
  /// In en, this message translates to:
  /// **'Guided journal entries cannot be edited'**
  String get guidedJournalEntriesCannotBeEdited;

  /// No description provided for @entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get entryUpdated;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get entryDeleted;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @pleaseWriteSomething.
  ///
  /// In en, this message translates to:
  /// **'Please write something'**
  String get pleaseWriteSomething;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @deletePulseEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Pulse Entry?'**
  String get deletePulseEntryConfirm;

  /// No description provided for @deletePulseEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this pulse entry. This action cannot be undone.'**
  String get deletePulseEntryMessage;

  /// No description provided for @pulseEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Pulse entry deleted'**
  String get pulseEntryDeleted;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get noContent;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit Name'**
  String get habitName;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabit;

  /// No description provided for @deleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Delete Habit'**
  String get deleteHabit;

  /// No description provided for @noHabits.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabits;

  /// No description provided for @trackFirstHabit.
  ///
  /// In en, this message translates to:
  /// **'Track your first habit!'**
  String get trackFirstHabit;

  /// No description provided for @createYourFirstHabitToBuildConsistency.
  ///
  /// In en, this message translates to:
  /// **'Create your first habit to start building consistency'**
  String get createYourFirstHabitToBuildConsistency;

  /// No description provided for @activeHabits.
  ///
  /// In en, this message translates to:
  /// **'Active Habits'**
  String get activeHabits;

  /// No description provided for @focusOnOneToTwoHabitsForBetterConsistency.
  ///
  /// In en, this message translates to:
  /// **'Focus on 1-2 habits at a time for better consistency'**
  String get focusOnOneToTwoHabitsForBetterConsistency;

  /// No description provided for @noActiveHabitsMessage.
  ///
  /// In en, this message translates to:
  /// **'No active habits. Add a habit or move one from backlog.'**
  String get noActiveHabitsMessage;

  /// No description provided for @toCompleteToday.
  ///
  /// In en, this message translates to:
  /// **'To Complete Today'**
  String get toCompleteToday;

  /// No description provided for @completedToday.
  ///
  /// In en, this message translates to:
  /// **'Completed Today'**
  String get completedToday;

  /// No description provided for @backlogHabits.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get backlogHabits;

  /// No description provided for @habitsYourePlanningToWorkOnLater.
  ///
  /// In en, this message translates to:
  /// **'Habits you\'re planning to work on later'**
  String get habitsYourePlanningToWorkOnLater;

  /// No description provided for @establishedRoutines.
  ///
  /// In en, this message translates to:
  /// **'Established Routines ({count})'**
  String establishedRoutines(int count);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get aiSettings;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @modelSelection.
  ///
  /// In en, this message translates to:
  /// **'Model Selection'**
  String get modelSelection;

  /// No description provided for @enterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your Claude API key'**
  String get enterApiKey;

  /// No description provided for @saveApiKey.
  ///
  /// In en, this message translates to:
  /// **'Save API Key'**
  String get saveApiKey;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get backupFailed;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore data'**
  String get restoreFailed;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @pulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get pulse;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @dailyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-In'**
  String get dailyCheckIn;

  /// No description provided for @coachingPrompt.
  ///
  /// In en, this message translates to:
  /// **'What would you like help with?'**
  String get coachingPrompt;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @chatWithMentor.
  ///
  /// In en, this message translates to:
  /// **'Chat with Mentor'**
  String get chatWithMentor;

  /// No description provided for @yourMentor.
  ///
  /// In en, this message translates to:
  /// **'Your Mentor'**
  String get yourMentor;

  /// No description provided for @hereToHelp.
  ///
  /// In en, this message translates to:
  /// **'Here to help'**
  String get hereToHelp;

  /// No description provided for @startAConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startAConversation;

  /// No description provided for @askMeAboutYourGoals.
  ///
  /// In en, this message translates to:
  /// **'Ask me about your goals, get advice, or just chat!'**
  String get askMeAboutYourGoals;

  /// No description provided for @howAmIDoingOverall.
  ///
  /// In en, this message translates to:
  /// **'How am I doing overall?'**
  String get howAmIDoingOverall;

  /// No description provided for @whatShouldIFocusOnToday.
  ///
  /// In en, this message translates to:
  /// **'What should I focus on today?'**
  String get whatShouldIFocusOnToday;

  /// No description provided for @whyAmINotMakingProgress.
  ///
  /// In en, this message translates to:
  /// **'Why am I not making progress?'**
  String get whyAmINotMakingProgress;

  /// No description provided for @helpMeReflectOnMyWeek.
  ///
  /// In en, this message translates to:
  /// **'Help me reflect on my week'**
  String get helpMeReflectOnMyWeek;

  /// No description provided for @messageYourMentor.
  ///
  /// In en, this message translates to:
  /// **'Message your mentor...'**
  String get messageYourMentor;

  /// No description provided for @startNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Start New Conversation'**
  String get startNewConversation;

  /// No description provided for @clearCurrentChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Current Chat'**
  String get clearCurrentChat;

  /// No description provided for @viewConversationHistory.
  ///
  /// In en, this message translates to:
  /// **'View Conversation History'**
  String get viewConversationHistory;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get enableReminders;

  /// No description provided for @disableReminders.
  ///
  /// In en, this message translates to:
  /// **'Disable Reminders'**
  String get disableReminders;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabled;

  /// No description provided for @notificationsCurrentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are currently disabled.'**
  String get notificationsCurrentlyDisabled;

  /// No description provided for @wontReceiveMentorReminders.
  ///
  /// In en, this message translates to:
  /// **'You won\'t receive mentor reminders until you enable them.'**
  String get wontReceiveMentorReminders;

  /// No description provided for @tapOpenSettingsToEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Open Settings\" to enable notifications in Android settings.'**
  String get tapOpenSettingsToEnableNotifications;

  /// No description provided for @exactAlarmsCurrentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are currently disabled.'**
  String get exactAlarmsCurrentlyDisabled;

  /// No description provided for @scheduledRemindersWontWork.
  ///
  /// In en, this message translates to:
  /// **'Your scheduled reminders won\'t work until you enable exact alarms.'**
  String get scheduledRemindersWontWork;

  /// No description provided for @tapOpenSettingsToEnableAlarms.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Open Settings\" to enable \"Alarms & reminders\" in Android settings.'**
  String get tapOpenSettingsToEnableAlarms;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @permissionsEnabled.
  ///
  /// In en, this message translates to:
  /// **'✅ Permissions enabled!'**
  String get permissionsEnabled;

  /// No description provided for @aiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI Not Configured'**
  String get aiNotConfigured;

  /// No description provided for @aiFeaturesCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI features are currently unavailable.'**
  String get aiFeaturesCurrentlyUnavailable;

  /// No description provided for @youNeedToConfigureEither.
  ///
  /// In en, this message translates to:
  /// **'You need to configure either:'**
  String get youNeedToConfigureEither;

  /// No description provided for @cloudAiEnterApiKey.
  ///
  /// In en, this message translates to:
  /// **'• Cloud AI - Enter your Claude API key'**
  String get cloudAiEnterApiKey;

  /// No description provided for @localAiDownloadModel.
  ///
  /// In en, this message translates to:
  /// **'• Local AI - Download the on-device model'**
  String get localAiDownloadModel;

  /// No description provided for @tapConfigureAiToSetup.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Configure AI\" to set up AI features in Settings.'**
  String get tapConfigureAiToSetup;

  /// No description provided for @configureAi.
  ///
  /// In en, this message translates to:
  /// **'Configure AI'**
  String get configureAi;

  /// No description provided for @aiNotConfiguredTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI not configured'**
  String get aiNotConfiguredTooltip;

  /// No description provided for @notificationsDisabledTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabledTooltip;

  /// No description provided for @yourJourneyBegins.
  ///
  /// In en, this message translates to:
  /// **'Your Journey Begins!'**
  String get yourJourneyBegins;

  /// No description provided for @dailyReflectionHabitCreated.
  ///
  /// In en, this message translates to:
  /// **'Daily Reflection Habit Created'**
  String get dailyReflectionHabitCreated;

  /// No description provided for @weveCreatedDailyReflectionHabit.
  ///
  /// In en, this message translates to:
  /// **'We\'ve created a \"Daily Reflection\" habit for you. This is your foundation for personal growth.'**
  String get weveCreatedDailyReflectionHabit;

  /// No description provided for @regularReflectionHelps.
  ///
  /// In en, this message translates to:
  /// **'Regular reflection helps you track progress, gain insights, and discover meaningful habits and goals.'**
  String get regularReflectionHelps;

  /// No description provided for @readyToStartYourFirstReflection.
  ///
  /// In en, this message translates to:
  /// **'Ready to start your first reflection?'**
  String get readyToStartYourFirstReflection;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @startReflecting.
  ///
  /// In en, this message translates to:
  /// **'Start Reflecting'**
  String get startReflecting;

  /// No description provided for @nextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next Reminder'**
  String get nextReminder;

  /// No description provided for @nextReminders.
  ///
  /// In en, this message translates to:
  /// **'Next Reminders'**
  String get nextReminders;

  /// No description provided for @alsoToday.
  ///
  /// In en, this message translates to:
  /// **'Also today: {label} at {time}'**
  String alsoToday(String label, String time);

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get tomorrow;

  /// No description provided for @tomorrowLabel.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {label} at {time}'**
  String tomorrowLabel(String label, String time);

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} days'**
  String inDays(int count);

  /// No description provided for @inHours.
  ///
  /// In en, this message translates to:
  /// **'in {count} {count, plural, =1{hour} other{hours}}'**
  String inHours(int count);

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count} {count, plural, =1{minute} other{minutes}}'**
  String inMinutes(int count);

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'soon'**
  String get soon;

  /// No description provided for @enableNotificationsToReceiveReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive reminders'**
  String get enableNotificationsToReceiveReminders;

  /// No description provided for @enableExactAlarmsToReceiveScheduledReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable exact alarms to receive scheduled reminders'**
  String get enableExactAlarmsToReceiveScheduledReminders;

  /// No description provided for @manageReminders.
  ///
  /// In en, this message translates to:
  /// **'Manage Reminders'**
  String get manageReminders;

  /// No description provided for @debugConsole.
  ///
  /// In en, this message translates to:
  /// **'Debug Console'**
  String get debugConsole;

  /// No description provided for @debugSettings.
  ///
  /// In en, this message translates to:
  /// **'Debug Settings'**
  String get debugSettings;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboarding;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get categoryFitness;

  /// No description provided for @categoryCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get categoryCareer;

  /// No description provided for @categoryLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get categoryLearning;

  /// No description provided for @categoryRelationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get categoryRelationships;

  /// No description provided for @categoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
