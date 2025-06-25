import 'dart:convert'; // Para jsonEncode/Decode
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grow_garden_tracker/core/services/ringtone_service.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart';
import 'navigation_event_service.dart'; // Importar el nuevo servicio

// Hacemos la instancia del RingtoneService accesible globalmente o la pasamos por DI.
// Por simplicidad momentánea y para mantener la funcionalidad original, la instanciamos aquí.
// Una mejor solución sería inyectarla a través del constructor de NotificationService
// o usar un localizador de servicios.
final RingtoneService _ringtoneService = RingtoneService();


class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String sniperAlarmChannelId = 'sniper_alarm_channel';
  static const String sniperAlarmChannelName = 'Sniper Alarms';
  static const String sniperAlarmChannelDescription = 'Notifications for sniper alarms';

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      // Callback para cuando la app está en background/terminada y se recibe una notificación
      // Esto es crucial para que el fullScreenIntent funcione correctamente si la app no está activa
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );
  }

  // Wrapper para mostrar una notificación de alarma de sniper
  Future<void> showSniperAlarmNotification(String title, String body, {Map<String, dynamic>? payloadData}) async {
    // Ahora payloadData es Map<String, dynamic> para más flexibilidad
    final String notificationPayload = payloadData != null ? jsonEncode(payloadData) : jsonEncode({'type': 'sniper_alarm_simple'});


    // Configuración específica para Android
    // Nota: `fullScreenIntent` requiere el permiso USE_FULL_SCREEN_INTENT en AndroidManifest.xml
    // También, la actividad que se lanza (normalmente MainActivity) debe estar configurada
    // para manejar este intent, posiblemente en `android:launchMode="singleTop"` o similar
    // y extraer el payload en `onResume` o `onNewIntent`.
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      sniperAlarmChannelId,
      sniperAlarmChannelName,
      channelDescription: sniperAlarmChannelDescription,
      importance: Importance.max, // MAX Importance para notificaciones heads-up
      priority: Priority.high,    // HIGH Priority
      showWhen: true,
      playSound: false, // El sonido se maneja por RingtoneService manualmente
      fullScreenIntent: true, // ¡CLAVE PARA LA ALARMA DE PANTALLA COMPLETA!
      // `categoryAlarm` puede ayudar al sistema a tratarla como una alarma
      category: AndroidNotificationCategory.alarm,
      // `visibilityPublic` para que se muestre en la pantalla de bloqueo
      visibility: NotificationVisibility.public,
      // Podríamos añadir un sonido custom aquí si no usáramos RingtoneService
      // sound: RawResourceAndroidNotificationSound('alarm_sound'), // si tuvieras res/raw/alarm_sound.mp3
      // Podríamos configurar vibración también
      // enableVibration: true,
      // VIBRATION PATTERN (ejemplo: espera 0ms, vibra 500ms, espera 500ms, vibra 500ms)
      // vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
      // Para luces LED si el dispositivo lo soporta
      // enableLights: true,
      // ledColor: const Color.fromARGB(255, 255, 0, 0), // Rojo
      // ledOnMs: 1000,
      // ledOffMs: 500,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      999, // ID de la notificación para la alarma (para poder cancelarla)
      title,
      body,
      platformChannelSpecifics,
      payload: 'sniper_alarm_payload',
    );
  }

  Future<void> cancelSniperAlarmNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(999);
  }
}

// Esta función necesita ser top-level o static para ser usada como callback.
// Por eso se mantiene fuera de la clase o se hace static.
Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  logD("NotificationService: _onDidReceiveNotificationResponse triggered with payload: $payload");
  if (payload == 'sniper_alarm_payload') {
    logI('NotificationService: Alarma de sniper descartada por el usuario desde la notificación.');
    _ringtoneService.stop();
  }
}
