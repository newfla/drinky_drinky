// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabHistory => 'Historial';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get appTitle => 'Drinky Drinky';

  @override
  String get goalReached => '¡Meta alcanzada!';

  @override
  String currentIntake(String current, String target) {
    return '$current / $target L';
  }

  @override
  String get todaysIntake => 'Historial de hoy';

  @override
  String get noDrinksLogged => 'Sin bebidas registradas';

  @override
  String get noDrinksLoggedHint =>
      'Pulsa el botón + para registrar tu primera bebida de hoy.';

  @override
  String mlAdded(num amount) {
    return '+$amount ml añadidos';
  }

  @override
  String get undo => 'DESHACER';

  @override
  String get addWaterTooltip => 'Añadir agua';

  @override
  String presetButtonLabel(num amount) {
    return '+$amount ml';
  }

  @override
  String get customAmountHint => 'Cantidad personalizada';

  @override
  String get addButton => 'Añadir';

  @override
  String get errorLoadingDataRestart =>
      'Algo ha ido mal al cargar los datos. Reinicia la app.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionDailyGoal => 'META DIARIA';

  @override
  String get sectionQuickAddPresets => 'AÑADIR RÁPIDO';

  @override
  String get sectionNotifications => 'NOTIFICACIONES';

  @override
  String get sectionHydration => 'HIDRATACIÓN';

  @override
  String get recalculateHydration =>
      'Recalcular la recomendación de hidratación';

  @override
  String get applyFromTomorrow => 'Aplicar desde mañana';

  @override
  String get applyFromTomorrowSubtitle =>
      'Los cambios de meta entrarán en vigor mañana';

  @override
  String get applyFromTodaySubtitle =>
      'Los cambios de meta entrarán en vigor hoy';

  @override
  String presetTitle(num number) {
    return 'Preajuste $number';
  }

  @override
  String amountMl(num amount) {
    return '$amount ml';
  }

  @override
  String get notificationsDisabledBanner =>
      'Las notificaciones están desactivadas. Pulsa para abrir los ajustes del sistema.';

  @override
  String get openButton => 'Abrir';

  @override
  String intervalMinutes(num minutes) {
    return '$minutes min';
  }

  @override
  String get doNotDisturb => 'No molestar';

  @override
  String get toggleOn => 'Activo';

  @override
  String get toggleOff => 'Inactivo';

  @override
  String get startTime => 'Hora de inicio';

  @override
  String get endTime => 'Hora de fin';

  @override
  String get errorLoadingData => 'Algo ha ido mal al cargar los datos.';

  @override
  String get historyTitle => 'Historial';

  @override
  String get noHistoryYet => 'Sin historial';

  @override
  String get noHistoryYetHint =>
      'Empieza a registrar agua en la pestaña Inicio para ver tu historial aquí.';

  @override
  String dayStreak(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días consecutivos',
      one: '1 día consecutivo',
      zero: 'Sin racha',
    );
    return '$_temp0';
  }

  @override
  String daySummaryWithEntries(String date, num total, num target) {
    return '$date -- $total de $target ml';
  }

  @override
  String daySummaryNoEntries(String date) {
    return '$date -- Sin registros';
  }

  @override
  String calendarDayGoalMet(String month, num day) {
    return '$month $day: meta alcanzada';
  }

  @override
  String calendarDayGoalNotMet(String month, num day) {
    return '$month $day: meta no alcanzada';
  }

  @override
  String calendarDay(String month, num day) {
    return '$month $day';
  }

  @override
  String get calculatorTitle => 'Calculadora de hidratación';

  @override
  String get sexLabel => 'Sexo';

  @override
  String get sexMale => 'Hombre';

  @override
  String get sexFemale => 'Mujer';

  @override
  String get sexOther => 'Otro';

  @override
  String get weightLabel => 'Peso';

  @override
  String get weightInputLabel => 'Peso (kg)';

  @override
  String get weightUnit => 'kg';

  @override
  String get weightValidationError => 'Introduce un peso entre 1 y 300 kg';

  @override
  String get climateLabel => 'Clima';

  @override
  String get climateCold => 'Frío';

  @override
  String get climateMild => 'Templado';

  @override
  String get climateWarm => 'Cálido';

  @override
  String get climateVeryWarm => 'Muy cálido';

  @override
  String get climateHumid => 'Húmedo';

  @override
  String get yourRecommendation => 'Tu recomendación';

  @override
  String get fillAllFields => 'Rellena todos los campos';

  @override
  String get privacyDisclaimer =>
      'Tus datos (sexo, peso, clima) no se guardan ni se transmiten. El cálculo se realiza íntegramente en tu dispositivo.';

  @override
  String get useAsTarget => 'Usar como meta';

  @override
  String get skipButton => 'Omitir';

  @override
  String get targetUpdateError =>
      'Error al actualizar la meta. Inténtalo de nuevo.';

  @override
  String targetUpdated(String amount) {
    return 'Meta actualizada a $amount';
  }

  @override
  String get permissionTitle => 'Mantente hidratado con recordatorios';

  @override
  String get permissionBody =>
      'Drinky Drinky te envía suaves recordatorios para beber agua a lo largo del día.';

  @override
  String get enableReminders => 'Activar recordatorios';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String get remindersEnabled =>
      '¡Recordatorios activados! Puedes ajustarlos en cualquier momento en Ajustes.';

  @override
  String get remindersDeclined =>
      'Sin problema -- puedes activar los recordatorios más tarde en los ajustes de tu dispositivo.';

  @override
  String editPresetTitle(num number) {
    return 'Editar preajuste $number';
  }

  @override
  String get amountInputLabel => 'Cantidad (ml)';

  @override
  String get presetValidationError => 'Introduce un valor entre 50 y 2000';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get mlUnit => 'ml';

  @override
  String get notificationBody => '¡Es hora de beber agua! 💧';

  @override
  String dayDetailTotal(num total, num target) {
    return '$total ml / $target ml objetivo';
  }

  @override
  String get dayDetailNoEntries => 'Sin registros para este dia';
}
