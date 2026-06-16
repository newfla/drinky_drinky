// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabHistory => 'Historique';

  @override
  String get tabSettings => 'Paramètres';

  @override
  String get appTitle => 'Drinky Drinky';

  @override
  String get goalReached => 'Objectif atteint !';

  @override
  String currentIntake(String current, String target) {
    return '$current / $target L';
  }

  @override
  String get todaysIntake => 'Consommation du jour';

  @override
  String get noDrinksLogged => 'Aucune boisson enregistrée';

  @override
  String get noDrinksLoggedHint =>
      'Appuie sur le bouton + pour enregistrer ta première boisson aujourd\'hui.';

  @override
  String mlAdded(num amount) {
    return '+$amount ml ajoutés';
  }

  @override
  String get undo => 'ANNULER';

  @override
  String get addWaterTooltip => 'Ajouter de l\'eau';

  @override
  String presetButtonLabel(num amount) {
    return '+$amount ml';
  }

  @override
  String get customAmountHint => 'Quantité personnalisée';

  @override
  String get addButton => 'Ajouter';

  @override
  String get errorLoadingDataRestart =>
      'Une erreur s\'est produite lors du chargement des données. Redémarre l\'application.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionDailyGoal => 'OBJECTIF QUOTIDIEN';

  @override
  String get sectionQuickAddPresets => 'AJOUTS RAPIDES';

  @override
  String get sectionNotifications => 'NOTIFICATIONS';

  @override
  String get sectionHydration => 'HYDRATATION';

  @override
  String get recalculateHydration =>
      'Recalculer la recommandation d\'hydratation';

  @override
  String get applyFromTomorrow => 'Appliquer à partir de demain';

  @override
  String get applyFromTomorrowSubtitle =>
      'Les modifications de l\'objectif prendront effet demain';

  @override
  String get applyFromTodaySubtitle =>
      'Les modifications de l\'objectif prendront effet aujourd\'hui';

  @override
  String presetTitle(num number) {
    return 'Préréglage $number';
  }

  @override
  String amountMl(num amount) {
    return '$amount ml';
  }

  @override
  String get notificationsDisabledBanner =>
      'Les notifications sont désactivées. Appuie pour ouvrir les paramètres système.';

  @override
  String get openButton => 'Ouvrir';

  @override
  String intervalMinutes(num minutes) {
    return '$minutes min';
  }

  @override
  String get doNotDisturb => 'Ne pas déranger';

  @override
  String get toggleOn => 'Activé';

  @override
  String get toggleOff => 'Désactivé';

  @override
  String get startTime => 'Heure de début';

  @override
  String get endTime => 'Heure de fin';

  @override
  String get errorLoadingData =>
      'Une erreur s\'est produite lors du chargement des données.';

  @override
  String get historyTitle => 'Historique';

  @override
  String get noHistoryYet => 'Aucun historique';

  @override
  String get noHistoryYetHint =>
      'Commence à enregistrer de l\'eau dans l\'onglet Accueil pour voir ton historique ici.';

  @override
  String dayStreak(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours consécutifs',
      one: '1 jour consécutif',
      zero: 'Aucune série',
    );
    return '$_temp0';
  }

  @override
  String daySummaryWithEntries(String date, num total, num target) {
    return '$date -- $total sur $target ml';
  }

  @override
  String daySummaryNoEntries(String date) {
    return '$date -- Aucune entrée';
  }

  @override
  String calendarDayGoalMet(String month, num day) {
    return '$month $day : objectif atteint';
  }

  @override
  String calendarDayGoalNotMet(String month, num day) {
    return '$month $day : objectif non atteint';
  }

  @override
  String calendarDay(String month, num day) {
    return '$month $day';
  }

  @override
  String get calculatorTitle => 'Calculateur d\'hydratation';

  @override
  String get sexLabel => 'Sexe';

  @override
  String get sexMale => 'Homme';

  @override
  String get sexFemale => 'Femme';

  @override
  String get sexOther => 'Autre';

  @override
  String get weightLabel => 'Poids';

  @override
  String get weightInputLabel => 'Poids (kg)';

  @override
  String get weightUnit => 'kg';

  @override
  String get weightValidationError => 'Saisis un poids entre 1 et 300 kg';

  @override
  String get climateLabel => 'Climat';

  @override
  String get climateCold => 'Froid';

  @override
  String get climateMild => 'Doux';

  @override
  String get climateWarm => 'Chaud';

  @override
  String get climateVeryWarm => 'Très chaud';

  @override
  String get climateHumid => 'Humide';

  @override
  String get yourRecommendation => 'Ta recommandation';

  @override
  String get fillAllFields => 'Remplis tous les champs';

  @override
  String get privacyDisclaimer =>
      'Tes données (sexe, poids, climat) ne sont ni sauvegardées ni transmises. Le calcul s\'effectue entièrement sur ton appareil.';

  @override
  String get useAsTarget => 'Utiliser comme objectif';

  @override
  String get skipButton => 'Ignorer';

  @override
  String get targetUpdateError =>
      'Erreur lors de la mise à jour de l\'objectif. Réessaie.';

  @override
  String targetUpdated(String amount) {
    return 'Objectif mis à jour à $amount';
  }

  @override
  String get permissionTitle => 'Reste hydraté avec des rappels';

  @override
  String get permissionBody =>
      'Drinky Drinky t\'envoie de doux rappels pour boire de l\'eau tout au long de la journée.';

  @override
  String get enableReminders => 'Activer les rappels';

  @override
  String get skipForNow => 'Ignorer pour l\'instant';

  @override
  String get remindersEnabled =>
      'Rappels activés ! Tu peux les régler à tout moment dans les Paramètres.';

  @override
  String get remindersDeclined =>
      'Pas de problème -- tu pourras activer les rappels plus tard dans les paramètres de ton appareil.';

  @override
  String editPresetTitle(num number) {
    return 'Modifier le préréglage $number';
  }

  @override
  String get amountInputLabel => 'Quantité (ml)';

  @override
  String get presetValidationError => 'Saisis une valeur entre 50 et 2000';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get confirmButton => 'Confirmer';

  @override
  String get mlUnit => 'ml';

  @override
  String get notificationBody => 'C\'est l\'heure de boire de l\'eau ! 💧';

  @override
  String dayDetailTotal(num total, num target) {
    return '$total ml / $target ml objectif';
  }

  @override
  String get dayDetailNoEntries => 'Aucune entrée pour ce jour';
}
