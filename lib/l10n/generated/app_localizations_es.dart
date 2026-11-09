// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get apply => 'Aplicar';

  @override
  String get close => 'Cerrar';

  @override
  String get retry => 'Reintentar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get allow => 'Permitir';

  @override
  String get notNow => 'Ahora no';

  @override
  String get navHome => 'Inicio';

  @override
  String get navStats => 'Estadísticas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get mainNavigation => 'Navegación principal';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSupport =>
      'Tema, recordatorios, datos de sueño e información de la app.';

  @override
  String get appearance => 'Apariencia';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get sleepReminder => 'Aviso de sueño';

  @override
  String get sleepReminderOff => 'Desactivado';

  @override
  String sleepReminderEveryDay(String time) {
    return 'Todos los días a las $time';
  }

  @override
  String get reminderTime => 'Hora del recordatorio';

  @override
  String get notificationsOff => 'Las notificaciones están desactivadas';

  @override
  String get notificationsOffSupport =>
      'Permite que Sleepy3 envíe la notificación.';

  @override
  String get notificationsPermissionNeeded =>
      'Permite las notificaciones para recibir el recordatorio de sueño.';

  @override
  String get sleepReminderScheduleFailed =>
      'No se pudo programar el recordatorio. Inténtalo de nuevo.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get sleepReminderNotificationTitle => 'Hora de registrar tu sueño';

  @override
  String get sleepReminderNotificationBody =>
      'Abre Sleepy3 y toca Dormir cuando apagues la luz.';

  @override
  String get sleepReminderChannelName => 'Recordatorio de sueño';

  @override
  String get sleepReminderChannelDescription =>
      'Un recordatorio nocturno para registrar tu sueño.';

  @override
  String get sleepData => 'Datos de sueño';

  @override
  String get googleHealth => 'Google Health';

  @override
  String get about => 'Acerca de';

  @override
  String get theme => 'Tema';

  @override
  String get timeFormat => 'Formato de hora';

  @override
  String get language => 'Idioma';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get timeFormat12 => '12 horas';

  @override
  String get timeFormat24 => '24 horas';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get privacy => 'Privacidad';

  @override
  String get version => 'Versión';

  @override
  String get licenses => 'Licencias';

  @override
  String get privacyLocal => 'Solo en este dispositivo.';

  @override
  String get privacyHealth =>
      'Guardado en Health Connect. Google Health puede leerlo.';

  @override
  String get source => 'Fuente';

  @override
  String get import => 'Importar';

  @override
  String get importSupport => 'Descarga de Google Health a la copia local.';

  @override
  String get sleepDataSourceDialogTitle => 'Fuente de datos de sueño';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceHealth => 'Google Health';

  @override
  String get copyLocalSessionsTitle => '¿Copiar las sesiones locales?';

  @override
  String localSessionsNotInHealth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones locales aún no están en Google Health.',
      one: '1 sesión local aún no está en Google Health.',
    );
    return '$_temp0';
  }

  @override
  String get sync => 'Sincronizar';

  @override
  String get add => 'Añadir';

  @override
  String get syncRecentSupport => 'Envía la más reciente.';

  @override
  String get addAllSupport => 'Envía todas las sesiones locales.';

  @override
  String get status => 'Estado';

  @override
  String get connected => 'Conectado';

  @override
  String connectedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conectado · $count pendientes',
      one: 'Conectado · 1 pendiente',
    );
    return '$_temp0';
  }

  @override
  String connectedLastSync(String time) {
    return 'Conectado · Última sincronización $time';
  }

  @override
  String get permissionNeeded => 'Permiso necesario';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get updateRequired => 'Actualización necesaria';

  @override
  String get checking => 'Comprobando…';

  @override
  String get connect => 'Conectar';

  @override
  String get connectSupport =>
      'Permite que Sleepy3 lea y escriba datos de sueño.';

  @override
  String get install => 'Instalar';

  @override
  String get installSupport => 'Obtén o actualiza Health Connect.';

  @override
  String get syncSupport => 'Envía la sesión local más reciente.';

  @override
  String get addSupport =>
      'Envía las sesiones locales que no estén en Google Health.';

  @override
  String get healthPermissionReadWrite =>
      'Google Health necesita permiso para leer y escribir datos de sueño.';

  @override
  String get sleepAction => 'Dormir';

  @override
  String get wakeAction => 'Despertar';

  @override
  String get slideToWake => 'Desliza para despertar';

  @override
  String get slideToWakeHint =>
      'Desliza el círculo hacia la derecha o haz doble toque para confirmar.';

  @override
  String get wakeSlideJustNow => 'Ahora';

  @override
  String get wakeSlideJustNowSemantics =>
      'Acabas de dormirte. Desliza para despertar.';

  @override
  String wakeSlideSemantics(String duration) {
    return 'Llevas $duration durmiendo. Desliza para despertar.';
  }

  @override
  String get savingSession => 'Guardando sesión';

  @override
  String get sessionSaved => 'Sesión guardada';

  @override
  String get sessionDiscarded => 'Sesión descartada';

  @override
  String get sessionSaveFailed => 'No se pudo guardar la sesión';

  @override
  String get dayStatus => 'Día · listo para despertar';

  @override
  String get nightStatus => 'Noche · hora de descansar';

  @override
  String get dayStatusSpoken => 'Día, listo para despertar';

  @override
  String get nightStatusSpoken => 'Noche, hora de descansar';

  @override
  String currentTime(String time) {
    return 'Hora actual $time';
  }

  @override
  String sleepingSince(String time) {
    return 'Durmiendo desde las $time';
  }

  @override
  String lastSession(String duration) {
    return 'Última sesión: $duration';
  }

  @override
  String get noActiveSession => 'No hay sesión activa';

  @override
  String get tapSleepAtNight => 'Toca Dormir cuando apagues la luz';

  @override
  String get sleepTooShortTitle => 'Sueño demasiado corto';

  @override
  String get sleepTooShortBody =>
      'Las sesiones de menos de 10 minutos no se registran. ¿Seguro que quieres descartar esta sesión?';

  @override
  String get keepSleeping => 'Seguir durmiendo';

  @override
  String get discardSession => 'Descartar sesión';

  @override
  String get sleepTooLongTitle => 'Sueño demasiado largo';

  @override
  String get sleepTooLongBody =>
      'Las sesiones de más de 24 horas no se registran. Edita la hora de inicio para conservar esta sesión o descártala.';

  @override
  String get editStartTime => 'Editar hora de inicio';

  @override
  String get startTimeNotSaved => 'No se guardó la hora de inicio';

  @override
  String get selectSleepDate => 'Selecciona la fecha de dormir';

  @override
  String get selectSleepTime => 'Selecciona la hora de dormir';

  @override
  String get selectWakeDate => 'Selecciona la fecha de despertar';

  @override
  String get selectWakeTime => 'Selecciona la hora de despertar';

  @override
  String get last3Days => 'Últimos 3 días';

  @override
  String last3DaysAverage(String average) {
    return 'Últimos 3 días · $average de media';
  }

  @override
  String get last3DaysNoAverage => 'Últimos 3 días · sin media';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get noAverageSpoken => ', sin media';

  @override
  String averageSpoken(String duration) {
    return ', media $duration';
  }

  @override
  String get noSessionSpoken => 'sin sesión';

  @override
  String get loadingSleepHistorySemantic => 'Cargando el historial de sueño';

  @override
  String get loadingSleepHistory => 'Cargando el historial de sueño…';

  @override
  String get historyLoadError => 'No se pudo cargar el historial de sueño';

  @override
  String get historyLoadErrorSupport =>
      'Tus sesiones están a salvo. Inténtalo de nuevo.';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsSupport => 'Tu sueño, noche a noche.';

  @override
  String statsSupportingSleeping(String time) {
    return 'Durmiendo desde las $time · aparecerá cuando despiertes.';
  }

  @override
  String get history => 'Historial';

  @override
  String get timeRange => 'Rango de tiempo';

  @override
  String get range7Days => '7 días';

  @override
  String get range30Days => '30 días';

  @override
  String get rangeAll => 'Todo';

  @override
  String get averageSleep => 'Sueño medio';

  @override
  String get noNightsInRange => 'No hay noches en este rango';

  @override
  String summarySupporting(int nights, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights noches',
      one: '1 noche',
    );
    return 'Durante $_temp0 · $total en total';
  }

  @override
  String get showAll => 'Mostrar todo';

  @override
  String summarySpoken(String average, int nights, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights noches',
      one: '1 noche',
    );
    return 'Sueño medio $average, durante $_temp0, $total en total';
  }

  @override
  String get summarySpokenNoNights =>
      'Sueño medio, no hay noches en este rango';

  @override
  String get noSleepHistoryHealth =>
      'No hay historial de sueño en Google Health';

  @override
  String get noSleepHistory => 'Aún no hay historial de sueño';

  @override
  String get noSleepHistoryHealthSupport =>
      'Las sesiones de sueño de Health Connect aparecerán aquí.';

  @override
  String get noSleepHistorySleepingSupport =>
      'Tu primera noche aparecerá aquí cuando te despiertes.';

  @override
  String get noSleepHistorySupport =>
      'Tus noches aparecerán aquí después de despertarte.';

  @override
  String get refreshSleepHistory => 'Actualizar el historial de sueño';

  @override
  String get refreshingSleepHistory => 'Actualizando el historial de sueño';

  @override
  String get refreshFailed =>
      'No se pudo actualizar el historial de sueño. Inténtalo de nuevo.';

  @override
  String get sessionSavedPendingSync =>
      'Guardado. Google Health se actualizará cuando pueda.';

  @override
  String get sessionDeleted => 'Sesión eliminada.';

  @override
  String get sessionSavedLocallyPermission =>
      'Guardado localmente. Permite la escritura en Google Health para sincronizarlo.';

  @override
  String get sessionAddedHealth => 'Sesión añadida a Google Health.';

  @override
  String get sessionAdded => 'Sesión añadida.';

  @override
  String get sessionSavedLocally =>
      'Sesión guardada localmente. Google Health se actualizará cuando pueda.';

  @override
  String get addSleepSession => 'Añadir una sesión de sueño';

  @override
  String get opensSession => 'Abre la sesión';

  @override
  String get anotherApp => 'Otra app';

  @override
  String get anotherAppLower => 'otra app';

  @override
  String readOnlyFrom(String app) {
    return 'Solo lectura, de $app';
  }

  @override
  String get readOnlySession => 'Sesión de solo lectura';

  @override
  String get otherSleepy3Build => 'otra compilación de Sleepy3';

  @override
  String get goalMetLower => 'objetivo cumplido';

  @override
  String get sessionTitle => 'Sesión';

  @override
  String get newSessionTitle => 'Nueva sesión';

  @override
  String get addAction => 'Añadir';

  @override
  String get fellAsleep => 'Me dormí';

  @override
  String get wokeUp => 'Me desperté';

  @override
  String wokeOn(String date) {
    return 'Me desperté el $date';
  }

  @override
  String sessionHeroSpoken(String duration, String goal, String date) {
    return '$duration, $goal, me desperté el $date';
  }

  @override
  String get goalDefault => 'Tu objetivo de 8 h';

  @override
  String get goalMet => 'Objetivo cumplido';

  @override
  String goalOver(String delta) {
    return 'Objetivo cumplido · $delta por encima del objetivo de 8 h';
  }

  @override
  String goalUnder(String delta) {
    return 'A $delta del objetivo de 8 h';
  }

  @override
  String get spokenGoalDefault => 'objetivo de 8 horas';

  @override
  String get spokenGoalMet => 'objetivo cumplido';

  @override
  String spokenGoalOver(String delta) {
    return 'objetivo cumplido, $delta por encima del objetivo de 8 horas';
  }

  @override
  String spokenGoalUnder(String delta) {
    return '$delta por debajo del objetivo de 8 horas';
  }

  @override
  String sessionDateTimeSemantics(String title) {
    return '$title: fecha y hora';
  }

  @override
  String get discardChangesTitle => '¿Descartar los cambios sin guardar?';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get discard => 'Descartar';

  @override
  String get deleteSessionTitle => '¿Eliminar la sesión?';

  @override
  String get deleteSessionAction => 'Eliminar sesión';

  @override
  String get deleteMessageHealth =>
      'Esta noche se eliminará de Google Health. También se eliminará su copia local si existe.';

  @override
  String get deleteMessageHealthAndLocal =>
      'Esta noche se eliminará de Sleepy3 y Google Health.';

  @override
  String get deleteMessageLocal => 'Esta noche se eliminará de Sleepy3.';

  @override
  String get healthNeedsPermissionTitle => 'Google Health necesita permiso';

  @override
  String get allowWriteHealth =>
      'Permite que Sleepy3 escriba datos de sueño en Google Health e inténtalo de nuevo.';

  @override
  String get allowDeleteHealth =>
      'Permite que Sleepy3 elimine esta sesión de Google Health e inténtalo de nuevo.';

  @override
  String get allowDeleteHealthShort =>
      'Permite que Sleepy3 elimine esta sesión de Google Health.';

  @override
  String get couldNotSave => 'No se pudo guardar';

  @override
  String get couldNotSaveBody =>
      'No se pudo guardar la sesión. Inténtalo de nuevo.';

  @override
  String get couldNotAdd => 'No se pudo añadir la sesión';

  @override
  String get couldNotAddBody =>
      'No se pudo añadir la sesión. Inténtalo de nuevo.';

  @override
  String get couldNotDelete => 'No se pudo eliminar';

  @override
  String get couldNotDeleteBody =>
      'No se pudo eliminar la sesión. Inténtalo de nuevo.';

  @override
  String get healthNoticeStored =>
      'Esta noche se guarda en Google Health. Al guardar se actualiza el registro de Health Connect.';

  @override
  String get healthNoticeBoth =>
      'Esta noche también está en Google Health. Al guardar se actualizan ambas copias.';

  @override
  String get healthNoticeAdded => 'Esta noche se añadirá a Google Health.';

  @override
  String readOnlyOtherBuild(String app) {
    return 'Esta sesión se creó en $app, así que no se puede editar desde esta compilación.';
  }

  @override
  String get readOnlySleepy3 => 'Esta sesión no se puede editar desde Sleepy3.';

  @override
  String readOnlyOtherApp(String app) {
    return 'Esta sesión se creó en $app, así que no se puede editar desde Sleepy3.';
  }

  @override
  String readOnlyDownloadedOtherBuild(String app) {
    return 'Esta sesión se creó en $app. Las copias descargadas no se pueden editar desde esta compilación.';
  }

  @override
  String get readOnlyDownloadedSleepy3 =>
      'Esta sesión se descargó de Google Health. Cambia a Google Health para editarla.';

  @override
  String readOnlyDownloadedOtherApp(String app) {
    return 'Esta sesión se creó en $app. Las copias descargadas no se pueden editar en Local.';
  }

  @override
  String get readOnlyDownloadedUnknown =>
      'Esta sesión se descargó de Google Health. Las copias descargadas no se pueden editar en Local.';

  @override
  String get errorEndNotAfterStart =>
      'La hora de despertar debe ser posterior a la hora de dormir.';

  @override
  String get errorTooShort =>
      'Una sesión de sueño debe durar al menos 10 minutos.';

  @override
  String get errorTooLong =>
      'Una sesión de sueño no puede durar 24 horas o más.';

  @override
  String get errorStartInTheFuture =>
      'La hora de dormir no puede estar en el futuro.';

  @override
  String get errorEndInTheFuture =>
      'La hora de despertar no puede estar en el futuro.';

  @override
  String get errorOverlapsClosedSession =>
      'Esta sesión se solapa con otra sesión de sueño.';

  @override
  String get errorOverlapsOpenSession =>
      'Esta sesión se solapa con la sesión en curso.';

  @override
  String get copySyncLastTitle => '¿Sincronizar la última sesión?';

  @override
  String get copyAddAllTitle => '¿Añadir todas las sesiones anteriores?';

  @override
  String get copyDownloadTitle => '¿Descargar desde Google Health?';

  @override
  String get copySyncLastBody =>
      'Envía la sesión local más reciente a Google Health.';

  @override
  String get copyAddAllBody =>
      'Envía todas las sesiones locales que aún no estén en Google Health. Las sesiones que ya añadiste manualmente a Google Health pueden aparecer dos veces.';

  @override
  String get copyDownloadBody =>
      'Añade todas las sesiones de sueño de Google Health a la copia local. Las sesiones locales no cambian. Google Health también pedirá acceso a tu historial completo; si no lo concedes, solo se descargarán los últimos 30 días.';

  @override
  String get copySyncAction => 'Sincronizar';

  @override
  String get copyAddAllAction => 'Añadir todo';

  @override
  String get copyDownloadAction => 'Descargar todo';

  @override
  String get copySyncingSession => 'Sincronizando la sesión.';

  @override
  String get copySyncingSessions => 'Sincronizando sesiones.';

  @override
  String get copyDownloadingSessions => 'Descargando sesiones.';

  @override
  String get copyPleaseWait => 'Esto puede tardar un momento.';

  @override
  String get copyCouldNotDownload => 'No se pudo descargar';

  @override
  String get copyCouldNotSync => 'No se pudo sincronizar';

  @override
  String get copySomeFailed => 'Algunas sesiones no se copiaron';

  @override
  String get copyDownloadComplete => 'Descarga completada';

  @override
  String get copySyncComplete => 'Sincronización completada';

  @override
  String get copyNoSessions30Days =>
      'No hay sesiones de sueño en los últimos 30 días de Google Health.';

  @override
  String get copyNoSessionsHealth =>
      'No hay sesiones de sueño en Google Health.';

  @override
  String get copyNoLocalSessions => 'No hay sesiones locales para sincronizar.';

  @override
  String copySessionsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones enviadas a Google Health',
      one: '1 sesión enviada a Google Health',
    );
    return '$_temp0';
  }

  @override
  String copySessionsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones omitidas',
      one: '1 sesión omitida',
    );
    return '$_temp0';
  }

  @override
  String copySessionsFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones fallidas',
      one: '1 sesión fallida',
    );
    return '$_temp0';
  }

  @override
  String copySessionsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones añadidas',
      one: '1 sesión añadida',
    );
    return '$_temp0';
  }

  @override
  String copySessionsUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones actualizadas',
      one: '1 sesión actualizada',
    );
    return '$_temp0';
  }

  @override
  String copySessionsUpToDate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones ya actualizadas',
      one: '1 sesión ya actualizada',
    );
    return '$_temp0';
  }

  @override
  String copyHistoryLimited(String summary) {
    return '$summary. Solo se descargaron los últimos 30 días. Permite el historial completo en Google Health para copiar sesiones anteriores.';
  }

  @override
  String get healthUnavailable =>
      'Google Health no está disponible en este dispositivo.';

  @override
  String get healthUpdateRequired =>
      'Actualiza Health Connect para usar Google Health.';

  @override
  String get healthPermissionRead =>
      'Google Health necesita permiso para leer datos de sueño.';

  @override
  String get healthPermissionWrite =>
      'Google Health necesita permiso para escribir datos de sueño.';

  @override
  String get copyFailed => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get historyLast30Days => 'Solo están disponibles los últimos 30 días';

  @override
  String get historyAllowFullSupport =>
      'Permite el historial completo en Google Health para ver sesiones anteriores.';

  @override
  String get historyAllowFullAction => 'Permitir historial completo';

  @override
  String get historyPermissionDenied =>
      'Google Health necesita permiso para leer sesiones de sueño anteriores.';

  @override
  String syncBannerWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones pendientes de sincronizar',
      one: '1 sesión pendiente de sincronizar',
    );
    return '$_temp0';
  }

  @override
  String get sleepDataSourceSaveFailed =>
      'No se pudo guardar la fuente de datos de sueño.';

  @override
  String timeRangeSeparator(String from, String to) {
    return '$from – $to';
  }

  @override
  String timeRangeSpoken(String from, String to) {
    return '$from a $to';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String spokenDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String spokenDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hora',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '1 minuto',
    );
    return '$_temp0 $_temp1';
  }
}
