import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grow_garden_tracker/core/services/ringtone_service.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart'; // Importar logger

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
    );
  }

  // Wrapper para mostrar una notificación de alarma de sniper
  Future<void> showSniperAlarmNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      sniperAlarmChannelId,
      sniperAlarmChannelName,
      channelDescription: sniperAlarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: false, // El sonido se maneja por RingtoneService
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
