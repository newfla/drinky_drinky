import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// Bottom navigation bar label for the Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Bottom navigation bar label for the History tab
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// Bottom navigation bar label for the Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// App name shown in the Home screen AppBar
  ///
  /// In en, this message translates to:
  /// **'Drinky Drinky'**
  String get appTitle;

  /// Text shown in the circular progress indicator when the daily water goal has been met
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get goalReached;

  /// Current vs target intake shown in the circular progress indicator on the Home screen
  ///
  /// In en, this message translates to:
  /// **'{current} / {target} L'**
  String currentIntake(String current, String target);

  /// Section header above the drink log list on the Home screen
  ///
  /// In en, this message translates to:
  /// **'Today\'s Intake'**
  String get todaysIntake;

  /// Empty state primary text on the Home screen when no drinks have been logged today
  ///
  /// In en, this message translates to:
  /// **'No drinks logged yet'**
  String get noDrinksLogged;

  /// Empty state secondary hint text on the Home screen
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to log your first drink today.'**
  String get noDrinksLoggedHint;

  /// SnackBar message shown after logging a drink on the Home screen
  ///
  /// In en, this message translates to:
  /// **'+{amount} ml added'**
  String mlAdded(num amount);

  /// SnackBar action label to undo the last drink log on the Home screen
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undo;

  /// Tooltip for the floating action button on the Home screen
  ///
  /// In en, this message translates to:
  /// **'Add water'**
  String get addWaterTooltip;

  /// Label on quick-add preset buttons in the intake bottom sheet
  ///
  /// In en, this message translates to:
  /// **'+{amount} ml'**
  String presetButtonLabel(num amount);

  /// Hint text in the custom amount text field in the intake bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get customAmountHint;

  /// Primary action button label in the intake bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// Error message on the Home screen when settings fail to load, prompting a restart
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your data. Please restart the app.'**
  String get errorLoadingDataRestart;

  /// AppBar title on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section label for the daily goal card on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'DAILY GOAL'**
  String get sectionDailyGoal;

  /// Section label for the quick-add presets card on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'QUICK-ADD PRESETS'**
  String get sectionQuickAddPresets;

  /// Section label for the notifications card on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get sectionNotifications;

  /// Section label for the hydration card on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'HYDRATION'**
  String get sectionHydration;

  /// List tile title in the Hydration section of the Settings screen that opens the calculator
  ///
  /// In en, this message translates to:
  /// **'Recalculate hydration recommendation'**
  String get recalculateHydration;

  /// SwitchListTile title for the apply-from-tomorrow toggle in the daily goal card on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Apply from tomorrow'**
  String get applyFromTomorrow;

  /// SwitchListTile subtitle when apply-from-tomorrow is enabled on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Target changes take effect tomorrow'**
  String get applyFromTomorrowSubtitle;

  /// SwitchListTile subtitle when apply-from-tomorrow is disabled on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Target changes take effect today'**
  String get applyFromTodaySubtitle;

  /// List tile title for each preset in the quick-add presets card on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Preset {number}'**
  String presetTitle(num number);

  /// List tile subtitle showing the amount in ml for each preset on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'{amount} ml'**
  String amountMl(num amount);

  /// Banner text shown in the notifications card when notification permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Tap to open system Settings.'**
  String get notificationsDisabledBanner;

  /// Button label in the notifications-disabled banner to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButton;

  /// Label showing the selected notification interval in minutes on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String intervalMinutes(num minutes);

  /// SwitchListTile title for the Do Not Disturb toggle in the notifications card
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get doNotDisturb;

  /// SwitchListTile subtitle when Do Not Disturb is enabled on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get toggleOn;

  /// SwitchListTile subtitle when Do Not Disturb is disabled on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get toggleOff;

  /// List tile title for the DND start time picker on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// List tile title for the DND end time picker on the Settings screen
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// Generic error message shown on the Settings screen and History screen when data fails to load
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your data.'**
  String get errorLoadingData;

  /// AppBar title on the History screen
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Empty state primary text on the History screen when no drinks have ever been logged
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// Empty state secondary hint text on the History screen
  ///
  /// In en, this message translates to:
  /// **'Start logging water on the Home tab to see your history here.'**
  String get noHistoryYetHint;

  /// Streak label in the streak card on the History screen; uses ICU plural with explicit =0 for zero case
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak} =1{1 day streak} other{{count} day streak}}'**
  String dayStreak(num count);

  /// Day summary text shown below the calendar when a day with entries is tapped on the History screen
  ///
  /// In en, this message translates to:
  /// **'{date} -- {total} of {target} ml'**
  String daySummaryWithEntries(String date, num total, num target);

  /// Day summary text shown below the calendar when a day with no entries is tapped on the History screen
  ///
  /// In en, this message translates to:
  /// **'{date} -- No entries'**
  String daySummaryNoEntries(String date);

  /// Semantic label for a calendar day cell where the water goal was met
  ///
  /// In en, this message translates to:
  /// **'{month} {day}: goal met'**
  String calendarDayGoalMet(String month, num day);

  /// Semantic label for a calendar day cell where the water goal was not met
  ///
  /// In en, this message translates to:
  /// **'{month} {day}: goal not met'**
  String calendarDayGoalNotMet(String month, num day);

  /// Semantic label for a calendar day cell with no hydration data (today ring only)
  ///
  /// In en, this message translates to:
  /// **'{month} {day}'**
  String calendarDay(String month, num day);

  /// AppBar title on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Hydration calculator'**
  String get calculatorTitle;

  /// Section label above the sex segmented button on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sexLabel;

  /// Male option in the sex segmented button on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// Female option in the sex segmented button on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// Other option in the sex segmented button on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sexOther;

  /// Section label above the weight text field on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// Input field label for the weight text field on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightInputLabel;

  /// Suffix text for the weight input field on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get weightUnit;

  /// Validation error shown when the weight field contains an invalid value on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between 1 and 300 kg'**
  String get weightValidationError;

  /// Section label above the climate slider on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Climate'**
  String get climateLabel;

  /// Climate slider label for the coldest climate option on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get climateCold;

  /// Climate slider label for the mild climate option on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get climateMild;

  /// Climate slider label for the warm climate option on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get climateWarm;

  /// Climate slider label for the very warm climate option on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Very warm'**
  String get climateVeryWarm;

  /// Climate slider label for the humid climate option on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Humid'**
  String get climateHumid;

  /// Label above the computed recommendation value on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Your recommendation'**
  String get yourRecommendation;

  /// Placeholder text shown instead of the recommendation when not all fields are filled on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields'**
  String get fillAllFields;

  /// Privacy disclaimer text at the bottom of the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Your data (sex, weight, climate) is not saved or transmitted. The calculation happens entirely on your device.'**
  String get privacyDisclaimer;

  /// Primary action button label on the Hydration Calculator screen to apply the recommendation as the daily goal
  ///
  /// In en, this message translates to:
  /// **'Use as target'**
  String get useAsTarget;

  /// Secondary button label shown during onboarding on the Hydration Calculator screen to skip setting a goal
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// SnackBar error message shown when saving the recommended target fails on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Error updating target. Try again.'**
  String get targetUpdateError;

  /// SnackBar success message shown after the daily target is updated on the Hydration Calculator screen
  ///
  /// In en, this message translates to:
  /// **'Target updated to {amount}'**
  String targetUpdated(String amount);

  /// Headline text on the Permission screen
  ///
  /// In en, this message translates to:
  /// **'Stay hydrated with reminders'**
  String get permissionTitle;

  /// Body text on the Permission screen explaining what reminders do
  ///
  /// In en, this message translates to:
  /// **'Drinky Drinky sends you gentle reminders to drink water throughout the day.'**
  String get permissionBody;

  /// Primary action button label on the Permission screen to request notification permission
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get enableReminders;

  /// Secondary button label on the Permission screen to defer notification permission
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// SnackBar message shown after the user grants notification permission on the Permission screen
  ///
  /// In en, this message translates to:
  /// **'Reminders enabled! You can adjust them anytime in Settings.'**
  String get remindersEnabled;

  /// SnackBar message shown after the user declines notification permission on the Permission screen
  ///
  /// In en, this message translates to:
  /// **'No problem -- you can enable reminders later in your device Settings.'**
  String get remindersDeclined;

  /// AlertDialog title in the preset edit dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Preset {number}'**
  String editPresetTitle(num number);

  /// Input field label in the preset edit dialog
  ///
  /// In en, this message translates to:
  /// **'Amount (ml)'**
  String get amountInputLabel;

  /// Validation error text in the preset edit dialog when the value is out of range
  ///
  /// In en, this message translates to:
  /// **'Enter a value between 50 and 2000'**
  String get presetValidationError;

  /// Cancel action button in the preset edit dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Confirm action button in the preset edit dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// Suffix text for millilitre unit, used in input fields across the app
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get mlUnit;

  /// Body text of the hydration reminder push notification
  ///
  /// In en, this message translates to:
  /// **'Time to drink water!'**
  String get notificationBody;

  /// Total and target shown in litres above the bar chart on the Day Detail screen
  ///
  /// In en, this message translates to:
  /// **'{total} L / {target} L target'**
  String dayDetailTotal(String total, String target);

  /// Empty state text on the Day Detail screen when no water was logged for the selected date
  ///
  /// In en, this message translates to:
  /// **'No entries for this day'**
  String get dayDetailNoEntries;
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
      <String>['en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
