// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MentorMe';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get later => 'Later';

  @override
  String get all => 'All';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get backlog => 'Backlog';

  @override
  String get home => 'Home';

  @override
  String get goals => 'Goals';

  @override
  String get journal => 'Journal';

  @override
  String get habits => 'Habits';

  @override
  String get mentor => 'Mentor';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get goalTitle => 'Goal Title';

  @override
  String get goalDescription => 'Description';

  @override
  String get goalCategory => 'Category';

  @override
  String get addGoal => 'Add Goal';

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get deleteGoal => 'Delete Goal';

  @override
  String get noGoals => 'No goals yet';

  @override
  String get createFirstGoal => 'Create your first goal to get started!';

  @override
  String get createYourFirstGoalToStartYourJourney =>
      'Create your first goal to start your journey';

  @override
  String get activeGoals => 'Active Goals';

  @override
  String get focusOnOneToTwoGoalsForBetterResults =>
      'Focus on 1-2 goals at a time for better results';

  @override
  String get noActiveGoalsMessage =>
      'No active goals. Add a goal or move one from backlog.';

  @override
  String get backlogGoals => 'Backlog';

  @override
  String get goalsYourePlanningToWorkOnLater =>
      'Goals you\'re planning to work on later';

  @override
  String completedGoalsCount(int count) {
    return 'Completed ($count)';
  }

  @override
  String get onTrack => 'On Track';

  @override
  String get avgProgress => 'Avg Progress';

  @override
  String get target => 'Target';

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get journalEntry => 'Journal Entry';

  @override
  String get addJournalEntry => 'Add Journal Entry';

  @override
  String get editJournalEntry => 'Edit Journal Entry';

  @override
  String get noJournalEntries => 'No journal entries yet';

  @override
  String get writeFirstEntry => 'Write your first entry to start reflecting!';

  @override
  String get searchEntries => 'Search entries...';

  @override
  String entriesThisMonth(int count, int weekCount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'entries',
      one: 'entry',
    );
    return '$count $_temp0 this month · $weekCount this week';
  }

  @override
  String get compact => 'Compact';

  @override
  String get defaultView => 'Default';

  @override
  String get tipUseAiChatForDeeperInsights =>
      'Tip: Use AI Chat for deeper insights and pattern analysis';

  @override
  String get noMatchingEntries => 'No matching entries';

  @override
  String get tryAdjustingYourSearchOrFilter =>
      'Try adjusting your search or filter';

  @override
  String get pulseCheck => 'Pulse Check';

  @override
  String get justLogHowYouFeel => 'Just log how you feel (10 sec)';

  @override
  String get quickEntry => 'Quick Entry';

  @override
  String get fastSimpleNote => 'Fast, simple note (30 sec)';

  @override
  String get guidedReflection => 'Guided Reflection';

  @override
  String get recommended => 'Recommended';

  @override
  String get stepByStepPrompts => 'Step-by-step prompts (3-5 min)';

  @override
  String get howWouldYouLikeToReflect => 'How would you like to reflect?';

  @override
  String get reflect => 'Reflect';

  @override
  String get entry => 'entry';

  @override
  String get entries => 'entries';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get viewDetails => 'View Details';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deleteEntryConfirm => 'Delete Entry?';

  @override
  String get deleteEntryMessage =>
      'This will permanently delete this journal entry. This action cannot be undone.';

  @override
  String get guidedJournalEntriesCannotBeEdited =>
      'Guided journal entries cannot be edited';

  @override
  String get entryUpdated => 'Entry updated';

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get content => 'Content';

  @override
  String get pleaseWriteSomething => 'Please write something';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get deletePulseEntryConfirm => 'Delete Pulse Entry?';

  @override
  String get deletePulseEntryMessage =>
      'This will permanently delete this pulse entry. This action cannot be undone.';

  @override
  String get pulseEntryDeleted => 'Pulse entry deleted';

  @override
  String get note => 'Note';

  @override
  String get noContent => 'No content';

  @override
  String get habitName => 'Habit Name';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get editHabit => 'Edit Habit';

  @override
  String get deleteHabit => 'Delete Habit';

  @override
  String get noHabits => 'No habits yet';

  @override
  String get trackFirstHabit => 'Track your first habit!';

  @override
  String get createYourFirstHabitToBuildConsistency =>
      'Create your first habit to start building consistency';

  @override
  String get activeHabits => 'Active Habits';

  @override
  String get focusOnOneToTwoHabitsForBetterConsistency =>
      'Focus on 1-2 habits at a time for better consistency';

  @override
  String get noActiveHabitsMessage =>
      'No active habits. Add a habit or move one from backlog.';

  @override
  String get toCompleteToday => 'To Complete Today';

  @override
  String get completedToday => 'Completed Today';

  @override
  String get backlogHabits => 'Backlog';

  @override
  String get habitsYourePlanningToWorkOnLater =>
      'Habits you\'re planning to work on later';

  @override
  String establishedRoutines(int count) {
    return 'Established Routines ($count)';
  }

  @override
  String get remaining => 'Remaining';

  @override
  String get aiSettings => 'AI Settings';

  @override
  String get apiKey => 'API Key';

  @override
  String get modelSelection => 'Model Selection';

  @override
  String get enterApiKey => 'Enter your Claude API key';

  @override
  String get saveApiKey => 'Save API Key';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get backupSuccess => 'Backup created successfully';

  @override
  String get backupFailed => 'Failed to create backup';

  @override
  String get restoreSuccess => 'Data restored successfully';

  @override
  String get restoreFailed => 'Failed to restore data';

  @override
  String get mood => 'Mood';

  @override
  String get energy => 'Energy';

  @override
  String get pulse => 'Pulse';

  @override
  String get checkIn => 'Check In';

  @override
  String get dailyCheckIn => 'Daily Check-In';

  @override
  String get coachingPrompt => 'What would you like help with?';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get chatWithMentor => 'Chat with Mentor';

  @override
  String get yourMentor => 'Your Mentor';

  @override
  String get hereToHelp => 'Here to help';

  @override
  String get startAConversation => 'Start a conversation';

  @override
  String get askMeAboutYourGoals =>
      'Ask me about your goals, get advice, or just chat!';

  @override
  String get howAmIDoingOverall => 'How am I doing overall?';

  @override
  String get whatShouldIFocusOnToday => 'What should I focus on today?';

  @override
  String get whyAmINotMakingProgress => 'Why am I not making progress?';

  @override
  String get helpMeReflectOnMyWeek => 'Help me reflect on my week';

  @override
  String get messageYourMentor => 'Message your mentor...';

  @override
  String get startNewConversation => 'Start New Conversation';

  @override
  String get clearCurrentChat => 'Clear Current Chat';

  @override
  String get viewConversationHistory => 'View Conversation History';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get reminders => 'Reminders';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableReminders => 'Enable Reminders';

  @override
  String get disableReminders => 'Disable Reminders';

  @override
  String get notificationsDisabled => 'Notifications Disabled';

  @override
  String get notificationsCurrentlyDisabled =>
      'Notifications are currently disabled.';

  @override
  String get wontReceiveMentorReminders =>
      'You won\'t receive mentor reminders until you enable them.';

  @override
  String get tapOpenSettingsToEnableNotifications =>
      'Tap \"Open Settings\" to enable notifications in Android settings.';

  @override
  String get exactAlarmsCurrentlyDisabled =>
      'Exact alarms are currently disabled.';

  @override
  String get scheduledRemindersWontWork =>
      'Your scheduled reminders won\'t work until you enable exact alarms.';

  @override
  String get tapOpenSettingsToEnableAlarms =>
      'Tap \"Open Settings\" to enable \"Alarms & reminders\" in Android settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionsEnabled => '✅ Permissions enabled!';

  @override
  String get aiNotConfigured => 'AI Not Configured';

  @override
  String get aiFeaturesCurrentlyUnavailable =>
      'AI features are currently unavailable.';

  @override
  String get youNeedToConfigureEither => 'You need to configure either:';

  @override
  String get cloudAiEnterApiKey => '• Cloud AI - Enter your Claude API key';

  @override
  String get localAiDownloadModel =>
      '• Local AI - Download the on-device model';

  @override
  String get tapConfigureAiToSetup =>
      'Tap \"Configure AI\" to set up AI features in Settings.';

  @override
  String get configureAi => 'Configure AI';

  @override
  String get aiNotConfiguredTooltip => 'AI not configured';

  @override
  String get notificationsDisabledTooltip => 'Notifications disabled';

  @override
  String get yourJourneyBegins => 'Your Journey Begins!';

  @override
  String get dailyReflectionHabitCreated => 'Daily Reflection Habit Created';

  @override
  String get weveCreatedDailyReflectionHabit =>
      'We\'ve created a \"Daily Reflection\" habit for you. This is your foundation for personal growth.';

  @override
  String get regularReflectionHelps =>
      'Regular reflection helps you track progress, gain insights, and discover meaningful habits and goals.';

  @override
  String get readyToStartYourFirstReflection =>
      'Ready to start your first reflection?';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get startReflecting => 'Start Reflecting';

  @override
  String get nextReminder => 'Next Reminder';

  @override
  String get nextReminders => 'Next Reminders';

  @override
  String alsoToday(String label, String time) {
    return 'Also today: $label at $time';
  }

  @override
  String get tomorrow => 'tomorrow';

  @override
  String tomorrowLabel(String label, String time) {
    return 'Tomorrow: $label at $time';
  }

  @override
  String inDays(int count) {
    return 'in $count days';
  }

  @override
  String inHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    return 'in $count $_temp0';
  }

  @override
  String inMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return 'in $count $_temp0';
  }

  @override
  String get soon => 'soon';

  @override
  String get enableNotificationsToReceiveReminders =>
      'Enable notifications to receive reminders';

  @override
  String get enableExactAlarmsToReceiveScheduledReminders =>
      'Enable exact alarms to receive scheduled reminders';

  @override
  String get manageReminders => 'Manage Reminders';

  @override
  String get debugConsole => 'Debug Console';

  @override
  String get debugSettings => 'Debug Settings';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get onboarding => 'Onboarding';

  @override
  String get welcome => 'Welcome';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get noResults => 'No results found';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryFitness => 'Fitness';

  @override
  String get categoryCareer => 'Career';

  @override
  String get categoryLearning => 'Learning';

  @override
  String get categoryRelationships => 'Relationships';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryOther => 'Other';
}
