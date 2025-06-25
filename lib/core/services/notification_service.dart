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

// Constantes del canal de notificación (top-level para asegurar que sean const en tiempo de compilación)
const String _sniperAlarmChannelId = 'sniper_alarm_channel';
const String _sniperAlarmChannelName = 'Sniper Alarms';
const String _sniperAlarmChannelDescription = 'Notifications for sniper alarms';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Ya no son static const aquí, se usan las top-level
  // static const String sniperAlarmChannelId = 'sniper_alarm_channel';
  // static const String sniperAlarmChannelName = 'Sniper Alarms';
  // static const String sniperAlarmChannelDescription = 'Notifications for sniper alarms';

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Asegúrate que '@mipmap/ic_launcher' es correcto y existe
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponseHandler, // Nombre corregido
    );
  }

  Future<void> showSniperAlarmNotification(String title, String body, {Map<String, dynamic>? payloadData}) async {
    final String notificationPayload = payloadData != null ? jsonEncode(payloadData) : jsonEncode({'type': 'sniper_alarm_simple'});

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _sniperAlarmChannelId, // Usar las constantes top-level
      _sniperAlarmChannelName,
      channelDescription: _sniperAlarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      // Las siguientes propiedades comentadas no son const, por lo que no se pueden usar en un const constructor
      // si se descomentan, androidPlatformChannelSpecifics no podría ser const.
      // sound: RawResourceAndroidNotificationSound('alarm_sound'),
      // vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
      // ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      999,
      title,
      body,
      platformChannelSpecifics,
      payload: notificationPayload, // Usar el payload dinámico
    );
  }

  Future<void> cancelSniperAlarmNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(999);
  }
}

// Definición de la función top-level para el callback de background
@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponseHandler(NotificationResponse notificationResponse) {
  // Este es el wrapper que se pasa a initialize.
  // Mantenlo simple: imprime o realiza tareas muy básicas de almacenamiento.
  // No intentes actualizar la UI o usar plugins complejos aquí.
  // NOTA: El logger global puede no estar inicializado en este isolate. Usar print.
  print("NotificationService (Background): _onDidReceiveBackgroundNotificationResponseHandler triggered with payload: ${notificationResponse.payload}");
  // No llamar a _handleNotificationPayload desde aquí directamente si implica lógica compleja o NavigationEventService.
  // El fullScreenIntent debería ser suficiente para traer la app al frente, y luego
  // onDidReceiveNotificationResponse o la lógica de intent de MainActivity se encargarán.
}

// Callback para cuando se interactúa con la notificación y la app está en primer plano.
Future<void> _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  logD("NotificationService: _onDidReceiveNotificationResponse triggered with payload: ${notificationResponse.payload}");
  _handleNotificationPayload(notificationResponse.payload);
}

// Lógica centralizada para manejar el payload (llamada desde el isolate principal)
void _handleNotificationPayload(String? payloadString) {
  if (payloadString == null) {
    logW("NotificationService: Payload nulo recibido.");
    return;
  }

  try {
    final Map<String, dynamic> payloadMap = jsonDecode(payloadString);
    final type = payloadMap['type'];

    if (type == 'sniper_alarm' || type == 'sniper_alarm_simple' || type == 'sniper_alarm_legacy') {
      logI('NotificationService: Alarma de sniper recibida (type: $type).');
      _ringtoneService.stop();
      NavigationEventService().fireEvent(NavigationEventType.showSniperAlarm, data: payloadMap);
    } else {
      logW("NotificationService: Tipo de payload desconocido: $type. Payload: $payloadString");
    }
  } catch (e) {
    logE("NotificationService: Error decodificando payload JSON '$payloadString'. Error: $e");
    // Si el payload no es JSON pero es el string que usábamos antes
    if (payloadString == 'sniper_alarm_payload') { // Este era el payload original
       logI('NotificationService: Alarma de sniper (payload string original) recibida.');
      _ringtoneService.stop();
      // Disparamos con un mapa que simula el tipo para que _MyAppState lo maneje
      NavigationEventService().fireEvent(NavigationEventType.showSniperAlarm, data: {'type': 'sniper_alarm_legacy', 'message': 'Sniper Alarm!'});
    }
  }
}
