// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabHistory => 'Cronologia';

  @override
  String get tabSettings => 'Impostazioni';

  @override
  String get appTitle => 'Drinky Drinky';

  @override
  String get goalReached => 'Obiettivo raggiunto!';

  @override
  String currentIntake(String current, String target) {
    return '$current / $target L';
  }

  @override
  String get todaysIntake => 'Cronologia odierna';

  @override
  String get noDrinksLogged => 'Nessuna bevanda registrata';

  @override
  String get noDrinksLoggedHint =>
      'Tocca il pulsante + per registrare la tua prima bevanda di oggi.';

  @override
  String mlAdded(num amount) {
    return '+$amount ml aggiunti';
  }

  @override
  String get undo => 'ANNULLA';

  @override
  String get addWaterTooltip => 'Aggiungi acqua';

  @override
  String presetButtonLabel(num amount) {
    return '+$amount ml';
  }

  @override
  String get customAmountHint => 'Quantità personalizzata';

  @override
  String get addButton => 'Aggiungi';

  @override
  String get errorLoadingDataRestart =>
      'Qualcosa è andato storto durante il caricamento dei dati. Riavvia l\'app.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get sectionDailyGoal => 'OBIETTIVO GIORNALIERO';

  @override
  String get sectionQuickAddPresets => 'PRESET DI AGGIUNTA RAPIDA';

  @override
  String get sectionNotifications => 'NOTIFICHE';

  @override
  String get sectionHydration => 'IDRATAZIONE';

  @override
  String get recalculateHydration =>
      'Ricalcola la raccomandazione di idratazione';

  @override
  String get applyFromTomorrow => 'Applica da domani';

  @override
  String get applyFromTomorrowSubtitle =>
      'Le modifiche all\'obiettivo entreranno in vigore domani';

  @override
  String get applyFromTodaySubtitle =>
      'Le modifiche all\'obiettivo entreranno in vigore oggi';

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
      'Le notifiche sono disabilitate. Tocca per aprire le impostazioni di sistema.';

  @override
  String get openButton => 'Apri';

  @override
  String intervalMinutes(num minutes) {
    return '$minutes min';
  }

  @override
  String get doNotDisturb => 'Non disturbare';

  @override
  String get toggleOn => 'Attivo';

  @override
  String get toggleOff => 'Non attivo';

  @override
  String get startTime => 'Ora di inizio';

  @override
  String get endTime => 'Ora di fine';

  @override
  String get errorLoadingData =>
      'Qualcosa è andato storto durante il caricamento dei dati.';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get noHistoryYet => 'Nessuna cronologia';

  @override
  String get noHistoryYetHint =>
      'Inizia a registrare l\'acqua nella scheda Home per vedere la tua cronologia qui.';

  @override
  String dayStreak(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni consecutivi',
      one: '1 giorno consecutivo',
      zero: 'Nessuna serie',
    );
    return '$_temp0';
  }

  @override
  String daySummaryWithEntries(String date, num total, num target) {
    return '$date -- $total di $target ml';
  }

  @override
  String daySummaryNoEntries(String date) {
    return '$date -- Nessun dato';
  }

  @override
  String calendarDayGoalMet(String month, num day) {
    return '$month $day: obiettivo raggiunto';
  }

  @override
  String calendarDayGoalNotMet(String month, num day) {
    return '$month $day: obiettivo non raggiunto';
  }

  @override
  String calendarDay(String month, num day) {
    return '$month $day';
  }

  @override
  String get calculatorTitle => 'Calcolatore di idratazione';

  @override
  String get sexLabel => 'Sesso';

  @override
  String get sexMale => 'Maschio';

  @override
  String get sexFemale => 'Femmina';

  @override
  String get sexOther => 'Altro';

  @override
  String get weightLabel => 'Peso';

  @override
  String get weightInputLabel => 'Peso (kg)';

  @override
  String get weightUnit => 'kg';

  @override
  String get weightValidationError => 'Inserisci un peso tra 1 e 300 kg';

  @override
  String get climateLabel => 'Clima';

  @override
  String get climateCold => 'Freddo';

  @override
  String get climateMild => 'Mite';

  @override
  String get climateWarm => 'Caldo';

  @override
  String get climateVeryWarm => 'Molto caldo';

  @override
  String get climateHumid => 'Afoso';

  @override
  String get yourRecommendation => 'La tua raccomandazione';

  @override
  String get fillAllFields => 'Compila tutti i campi';

  @override
  String get privacyDisclaimer =>
      'I tuoi dati (sesso, peso, clima) non vengono salvati né trasmessi. Il calcolo avviene interamente sul tuo dispositivo.';

  @override
  String get useAsTarget => 'Usa come obiettivo';

  @override
  String get skipButton => 'Salta';

  @override
  String get targetUpdateError =>
      'Errore durante l\'aggiornamento dell\'obiettivo. Riprova.';

  @override
  String targetUpdated(String amount) {
    return 'Obiettivo aggiornato a $amount';
  }

  @override
  String get permissionTitle => 'Rimani idratato con i promemoria';

  @override
  String get permissionBody =>
      'Drinky Drinky ti invia gentili promemoria per bere acqua durante la giornata.';

  @override
  String get enableReminders => 'Abilita promemoria';

  @override
  String get skipForNow => 'Salta per ora';

  @override
  String get remindersEnabled =>
      'Promemoria abilitati! Puoi regolarli in qualsiasi momento nelle Impostazioni.';

  @override
  String get remindersDeclined =>
      'Nessun problema -- puoi abilitare i promemoria in seguito nelle impostazioni del dispositivo.';

  @override
  String editPresetTitle(num number) {
    return 'Modifica preset $number';
  }

  @override
  String get amountInputLabel => 'Quantità (ml)';

  @override
  String get presetValidationError => 'Inserisci un valore tra 50 e 2000';

  @override
  String get cancelButton => 'Annulla';

  @override
  String get confirmButton => 'Conferma';

  @override
  String get mlUnit => 'ml';

  @override
  String get notificationBody => 'È ora di bere acqua!';

  @override
  String dayDetailTotal(String total, String target) {
    return '$total L / $target L obiettivo';
  }

  @override
  String get dayDetailNoEntries => 'Nessun dato per questo giorno';
}
