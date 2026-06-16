// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSettings => 'Settings';

  @override
  String get appTitle => 'Drinky Drinky';

  @override
  String get goalReached => 'Goal reached!';

  @override
  String currentIntake(String current, String target) {
    return '$current / $target L';
  }

  @override
  String get todaysIntake => 'Today\'s Intake';

  @override
  String get noDrinksLogged => 'No drinks logged yet';

  @override
  String get noDrinksLoggedHint =>
      'Tap the + button to log your first drink today.';

  @override
  String mlAdded(num amount) {
    return '+$amount ml added';
  }

  @override
  String get undo => 'UNDO';

  @override
  String get addWaterTooltip => 'Add water';

  @override
  String presetButtonLabel(num amount) {
    return '+$amount ml';
  }

  @override
  String get customAmountHint => 'Custom amount';

  @override
  String get addButton => 'Add';

  @override
  String get errorLoadingDataRestart =>
      'Something went wrong loading your data. Please restart the app.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionDailyGoal => 'DAILY GOAL';

  @override
  String get sectionQuickAddPresets => 'QUICK-ADD PRESETS';

  @override
  String get sectionNotifications => 'NOTIFICATIONS';

  @override
  String get sectionHydration => 'HYDRATION';

  @override
  String get recalculateHydration => 'Recalculate hydration recommendation';

  @override
  String get applyFromTomorrow => 'Apply from tomorrow';

  @override
  String get applyFromTomorrowSubtitle => 'Target changes take effect tomorrow';

  @override
  String get applyFromTodaySubtitle => 'Target changes take effect today';

  @override
  String presetTitle(num number) {
    return 'Preset $number';
  }

  @override
  String amountMl(num amount) {
    return '$amount ml';
  }

  @override
  String get notificationsDisabledBanner =>
      'Notifications are disabled. Tap to open system Settings.';

  @override
  String get openButton => 'Open';

  @override
  String intervalMinutes(num minutes) {
    return '$minutes min';
  }

  @override
  String get doNotDisturb => 'Do Not Disturb';

  @override
  String get toggleOn => 'On';

  @override
  String get toggleOff => 'Off';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get errorLoadingData => 'Something went wrong loading your data.';

  @override
  String get historyTitle => 'History';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get noHistoryYetHint =>
      'Start logging water on the Home tab to see your history here.';

  @override
  String dayStreak(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
      zero: 'No streak',
    );
    return '$_temp0';
  }

  @override
  String daySummaryWithEntries(String date, num total, num target) {
    return '$date -- $total of $target ml';
  }

  @override
  String daySummaryNoEntries(String date) {
    return '$date -- No entries';
  }

  @override
  String calendarDayGoalMet(String month, num day) {
    return '$month $day: goal met';
  }

  @override
  String calendarDayGoalNotMet(String month, num day) {
    return '$month $day: goal not met';
  }

  @override
  String calendarDay(String month, num day) {
    return '$month $day';
  }

  @override
  String get calculatorTitle => 'Hydration calculator';

  @override
  String get sexLabel => 'Sex';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexOther => 'Other';

  @override
  String get weightLabel => 'Weight';

  @override
  String get weightInputLabel => 'Weight (kg)';

  @override
  String get weightUnit => 'kg';

  @override
  String get weightValidationError => 'Enter a weight between 1 and 300 kg';

  @override
  String get climateLabel => 'Climate';

  @override
  String get climateCold => 'Cold';

  @override
  String get climateMild => 'Mild';

  @override
  String get climateWarm => 'Warm';

  @override
  String get climateVeryWarm => 'Very warm';

  @override
  String get climateHumid => 'Humid';

  @override
  String get yourRecommendation => 'Your recommendation';

  @override
  String get fillAllFields => 'Fill in all fields';

  @override
  String get privacyDisclaimer =>
      'Your data (sex, weight, climate) is not saved or transmitted. The calculation happens entirely on your device.';

  @override
  String get useAsTarget => 'Use as target';

  @override
  String get skipButton => 'Skip';

  @override
  String get targetUpdateError => 'Error updating target. Try again.';

  @override
  String targetUpdated(String amount) {
    return 'Target updated to $amount';
  }

  @override
  String get permissionTitle => 'Stay hydrated with reminders';

  @override
  String get permissionBody =>
      'Drinky Drinky sends you gentle reminders to drink water throughout the day.';

  @override
  String get enableReminders => 'Enable Reminders';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get remindersEnabled =>
      'Reminders enabled! You can adjust them anytime in Settings.';

  @override
  String get remindersDeclined =>
      'No problem -- you can enable reminders later in your device Settings.';

  @override
  String editPresetTitle(num number) {
    return 'Edit Preset $number';
  }

  @override
  String get amountInputLabel => 'Amount (ml)';

  @override
  String get presetValidationError => 'Enter a value between 50 and 2000';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get mlUnit => 'ml';

  @override
  String get notificationBody => 'Time to drink water! 💧';

  @override
  String dayDetailTotal(num total, num target) {
    return '$total ml / $target ml target';
  }

  @override
  String get dayDetailNoEntries => 'No entries for this day';
}
