import 'dart:async';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:http/http.dart' as http;
import 'package:grow_garden_tracker/data/datasources/item_info_rest_data_source.dart';
import 'package:grow_garden_tracker/data/datasources/stock_rest_data_source.dart';
import 'package:grow_garden_tracker/data/models/weather_model.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/entities/stock_item_entity.dart';
import 'package:vibration/vibration.dart';
import 'package:grow_garden_tracker/data/models/stock_item_model.dart';
import 'dart:io' show Platform;

const _notificationChannelId = 'sniper_service_channel';
const _notificationId = 888;
const _alarmChannelId = 'sniper_alarm_channel';
const _alarmNotificationId = 999;

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();
String _lastNotificationBody = '';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  service.invoke('service_started');
  final serviceLogic = ServiceLogic();
  service.on('stopService').listen((event) {
    serviceLogic.stop();
    service.invoke('service_stopped');
    Future.delayed(const Duration(milliseconds: 100), () => service.stopSelf());
  });
  service.on('updateSniperList').listen((event) {
    if (event != null && event['sniper_list'] is List) {
      serviceLogic.updateSniperList(List<String>.from(event['sniper_list']));
    }
  });
  service.on('requestInitialData').listen((event) {
    serviceLogic.sendLastKnownDataToUi(service);
  });
  serviceLogic.start(service);
}

class ServiceLogic {
  Timer? _timer;
  Timer? _clockTimer;
  bool _isStopped = false;
  int _failureCount = 0;
  Map<String, dynamic>? _lastKnownStock;
  List<dynamic>? _lastKnownWeather;
  Map<String, ItemInfoEntity> _allItemsInfo = {};
  List<String> _sniperList = [];
  DateTime? _nextStockTime;
  final stockDataSource = StockRestDataSourceImpl(client: http.Client());
  final itemInfoDataSource = ItemInfoRestDataSourceImpl(client: http.Client());

  void stop() {
    _isStopped = true;
    _timer?.cancel();
    _clockTimer?.cancel();
    _notificationsPlugin.cancel(_notificationId);
    debugPrint('[ServiceLogic] Servicio detenido.');
  }

  void updateSniperList(List<String> list) {
    _sniperList = list;
    debugPrint(
        '[ServiceLogic] Sniper list updated. Forcing notification refresh.');
    if (_lastKnownStock != null && _lastKnownWeather != null) {
      _updateDynamicNotification(
        nextStockTime: _nextStockTime,
        sniperList: _sniperList,
        currentStock: _parseStock(_lastKnownStock!),
        currentWeather: _lastKnownWeather!,
        allItemsInfo: _allItemsInfo,
      );
    }
  }

  void sendLastKnownDataToUi(ServiceInstance service) {
    if (_lastKnownStock != null) {
      service.invoke('updateStock', {
        'stock': _lastKnownStock,
        'weather': _lastKnownWeather,
      });
    }
  }

  Future<void> start(ServiceInstance service) async {
    _isStopped = false;
    try {
      debugPrint(
          '[ServiceLogic] Loading sniper list from storage on startup...');
      _sniperList = await SniperRepository().loadSniperList();
      debugPrint(
          '[ServiceLogic] Sniper list loaded with ${_sniperList.length} items.');
    } catch (e) {
      debugPrint('[ServiceLogic] Could not load sniper list on startup: $e');
    }
    try {
      final itemsList = await itemInfoDataSource.getAllItemsInfo();
      _allItemsInfo = {for (var item in itemsList) item.name: item};
    } catch (e) {
      debugPrint('[ServiceLogic] Error fatal al cargar info de items: $e');
    }
    _startClockTimer();
    _tick(service);
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isStopped) {
        timer.cancel();
        return;
      }
      _updateClockNotification();
    });
  }

  void _updateClockNotification() {
    if (_nextStockTime == null) return;
    String title;
    if (_nextStockTime!.isAfter(DateTime.now())) {
      final remaining = _nextStockTime!.difference(DateTime.now());
      title =
          'Próximo Stock en: ${_formatRemainingTime(remaining)} (a las ${_formatTime(_nextStockTime!)})';
    } else {
      title = 'Buscando nuevo stock...';
    }
    _updateNotificationTitleOnly(title);
  }

  Future<void> _tick(ServiceInstance service) async {
    if (_isStopped) return;
    Duration nextDelay;
    try {
      final results = await Future.wait(
          [stockDataSource.getStock(), stockDataSource.getWeather()]);
      final newStockMap = results[0] as Map<String, dynamic>;
      final newWeather = results[1] as List<dynamic>;
      final parsedStock = _parseStock(newStockMap);
      final stockChanged =
          !const DeepCollectionEquality().equals(_lastKnownStock, newStockMap);
      if (stockChanged) {
        debugPrint('[ServiceLogic] ¡Cambio de stock detectado!');
        _lastKnownStock = newStockMap;
        _lastKnownWeather = newWeather;
        service.invoke(
            'updateStock', {'stock': newStockMap, 'weather': newWeather});
      }
      final foundSniperItems = _checkForSniperItems(parsedStock, _sniperList);
      if (foundSniperItems.isNotEmpty) {
        final rarestItems =
            _getHighestRarityItems(foundSniperItems, _allItemsInfo);
        final highestRarity = _getHighestRarity(rarestItems, _allItemsInfo);
        final rarityColor = _getColorForRarity(highestRarity);

        _showFullScreenAlarmNotification(
          title: '¡ITEM ${highestRarity.toUpperCase()} ENCONTRADO!',
          body: rarestItems.map((e) => e.displayName).join(', '),
        );

        service.invoke('sniperAlarm', {
          'items': rarestItems.map((e) => e.displayName).toList(),
          'rarityColorHex': rarityColor.value,
        });
      }
      final expiration = _getNextStockTime(parsedStock);
      _nextStockTime = expiration;
      if (expiration != null && expiration.isAfter(DateTime.now())) {
        nextDelay =
            expiration.difference(DateTime.now()) + const Duration(seconds: 5);
      } else {
        nextDelay = const Duration(seconds: 20);
      }
      _failureCount = 0;
      _updateDynamicNotification(
        nextStockTime: expiration,
        sniperList: _sniperList,
        currentStock: parsedStock,
        currentWeather: newWeather,
        allItemsInfo: _allItemsInfo,
      );
    } catch (e) {
      debugPrint('[ServiceLogic] Error durante la petición: $e');
      _failureCount++;
      const delays = [5, 10, 15, 20, 25, 30];
      int delaySeconds;
      if (_failureCount <= delays.length) {
        delaySeconds = delays[_failureCount - 1];
      } else {
        delaySeconds = 30;
      }
      nextDelay = Duration(seconds: delaySeconds);
      _nextStockTime = null;
      _updateNotification(
          title: "Error de Red",
          body: "Reintentando en $delaySeconds segundos...");
    }
    if (!_isStopped) {
      _timer?.cancel();
      final scheduleDelay =
          nextDelay > Duration.zero ? nextDelay : const Duration(seconds: 1);
      debugPrint(
          '[ServiceLogic] Próxima revisión programada en ${scheduleDelay.inMinutes}m ${scheduleDelay.inSeconds % 60}s');
      _timer = Timer(scheduleDelay, () => _tick(service));
    }
  }
}

Future<void> _showFullScreenAlarmNotification(
    {required String title, required String body}) async {
  final androidDetails = AndroidNotificationDetails(
    _alarmChannelId,
    'Alarmas de Sniper',
    channelDescription: 'Canal para las alarmas críticas de items encontrados.',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    sound: const RawResourceAndroidNotificationSound('alarm_sound'),
    vibrationPattern: Int64List.fromList([0, 500, 500, 500, 500, 500]),
  );
  await _notificationsPlugin.show(
    _alarmNotificationId,
    title,
    body,
    NotificationDetails(android: androidDetails),
    payload: 'sniper_alarm_payload',
  );
}

void _updateDynamicNotification({
  required DateTime? nextStockTime,
  required List<String> sniperList,
  required Map<String, List<StockItemEntity>> currentStock,
  required List<dynamic> currentWeather,
  required Map<String, ItemInfoEntity> allItemsInfo,
}) {
  String title;
  if (nextStockTime != null && nextStockTime.isAfter(DateTime.now())) {
    final remaining = nextStockTime.difference(DateTime.now());
    title =
        'Próximo Stock en: ${_formatRemainingTime(remaining)} (a las ${_formatTime(nextStockTime)})';
  } else {
    title = 'Buscando nuevo stock...';
  }
  final List<String> bodyLines = [];
  try {
    final activeWeather = currentWeather
        .map((w) => WeatherModel.fromJson(w))
        .firstWhere((w) => w.isActive,
            orElse: () =>
                const WeatherModel(name: '', isActive: false, iconUrl: ''));
    if (activeWeather.isActive && activeWeather.name.isNotEmpty) {
      bodyLines.add(
          '<b>Clima:</b> ${_getEmojiForWeather(activeWeather.name)} ${activeWeather.name}');
    }
  } catch (e) {
    debugPrint('[ServiceLogic] Error al parsear clima para notificación: $e');
  }
  final foundSniperItems = _checkForSniperItems(currentStock, sniperList);
  if (foundSniperItems.isNotEmpty) {
    if (bodyLines.isNotEmpty) bodyLines.add('<br>');
    String foundItemsHtml =
        '<b><font color="#34C759">¡Sniper Exitoso!:</font></b> ';
    List<String> foundItemElements = [];
    for (var item in foundSniperItems) {
      final info = allItemsInfo[item.displayName];
      final rarity = info?.rarity ?? 'common';
      final color = _getHexColorForRarity(rarity);
      foundItemElements.add(
          '<font color="$color">•${_getEmojiForItem(item.displayName)} ${item.displayName}</font>');
    }
    foundItemsHtml += foundItemElements.join(' ');
    bodyLines.add(foundItemsHtml);
  }
  final stockForNotification = _filterStockForNotification(currentStock);
  if (stockForNotification.isNotEmpty) {
    if (bodyLines.isNotEmpty) bodyLines.add('<br>');
    List<String> itemHtmlElements = [];
    for (var item in stockForNotification) {
      final info = allItemsInfo[item.displayName];
      final rarity = info?.rarity ?? 'common';
      final color = _getHexColorForRarity(rarity);
      itemHtmlElements.add(
          '<font color="$color">•${_getEmojiForItem(item.displayName)} ${item.displayName}</font>');
    }
    bodyLines.add('<b>Stock:</b> ${itemHtmlElements.join(' ')}');
  }
  if (sniperList.isNotEmpty) {
    if (bodyLines.isNotEmpty) bodyLines.add('<br>');
    List<String> sniperItemElements = [];
    for (var itemName in sniperList) {
      final info = allItemsInfo[itemName];
      final rarity = info?.rarity ?? 'common';
      final color = _getHexColorForRarity(rarity);
      sniperItemElements.add(
          '<font color="$color">•${_getEmojiForItem(itemName)} $itemName</font>');
    }
    bodyLines.add('<b>Vigilando:</b> ${sniperItemElements.join(' ')}');
  }
  if (bodyLines.isNotEmpty) bodyLines.add('<br>');
  final snipedFruits = sniperList.where((item) => _isFruit(item)).toList();
  String snipedFruitsHtml = '<b>Frutas Vigiladas:</b> ';
  if (snipedFruits.isNotEmpty) {
    List<String> fruitElements = [];
    for (var fruitName in snipedFruits) {
      final info = allItemsInfo[fruitName];
      final rarity = info?.rarity ?? 'common';
      final color = _getHexColorForRarity(rarity);
      fruitElements.add(
          '<font color="$color">•${_getEmojiForItem(fruitName)} $fruitName</font>');
    }
    snipedFruitsHtml += fruitElements.join(' ');
  } else {
    snipedFruitsHtml += 'Ninguna';
  }
  bodyLines.add(snipedFruitsHtml);
  String body = bodyLines.join('');
  if (body.isEmpty) {
    body = 'Añade items a tu lista de sniper.';
  }
  _updateNotification(title: title, body: body);
}

List<StockItemEntity> _filterStockForNotification(
    Map<String, List<StockItemEntity>> currentStock) {
  final relevantItems = <StockItemEntity>[];
  if (currentStock.containsKey('seed')) {
    relevantItems.addAll(currentStock['seed']!);
  }
  if (currentStock.containsKey('gear')) {
    relevantItems.addAll(currentStock['gear']!);
  }
  return relevantItems;
}

bool _isFruit(String itemName) {
  final name = itemName.toLowerCase();
  const fruits = [
    'carrot',
    'strawberry',
    'tomato',
    'blueberry',
    'watermelon',
    'pineapple',
    'apple'
  ];
  return fruits.any((fruit) => name.contains(fruit));
}

Map<String, List<StockItemEntity>> _parseStock(Map<String, dynamic> rawStock) {
  final Map<String, List<StockItemEntity>> stockData = {};
  rawStock.forEach((key, value) {
    if (value is List && key.endsWith('_stock')) {
      final category = key.replaceAll('_stock', '');
      stockData[category] =
          value.map((e) => StockItemModel.fromJson(e)).toList();
    }
  });
  return stockData;
}

List<StockItemEntity> _checkForSniperItems(
    Map<String, List<StockItemEntity>> stock, List<String> sniperList) {
  if (sniperList.isEmpty) return [];
  final foundItems = <StockItemEntity>[];
  final sniperSet = sniperList.toSet();
  for (var category in stock.values) {
    for (var item in category) {
      if (sniperSet.contains(item.displayName)) {
        foundItems.add(item);
      }
    }
  }
  return foundItems;
}

List<StockItemEntity> _getHighestRarityItems(
    List<StockItemEntity> items, Map<String, ItemInfoEntity> allInfo) {
  if (items.isEmpty) return [];
  final highestRarityName = _getHighestRarity(items, allInfo);
  return items.where((item) {
    final info = allInfo[item.displayName];
    return info != null &&
        info.rarity.toLowerCase() == highestRarityName.toLowerCase();
  }).toList();
}

String _getHighestRarity(
    List<StockItemEntity> items, Map<String, ItemInfoEntity> allInfo) {
  const rarityOrder = [
    'common',
    'uncommon',
    'rare',
    'legendary',
    'mythical',
    'divine',
    'prismatic'
  ];
  int highestIndex = -1;
  String highestRarity = 'common';
  for (var item in items) {
    final info = allInfo[item.displayName];
    if (info != null) {
      final rarityIndex = rarityOrder.indexOf(info.rarity.toLowerCase());
      if (rarityIndex > highestIndex) {
        highestIndex = rarityIndex;
        highestRarity = info.rarity;
      }
    }
  }
  return highestRarity;
}

Color _getColorForRarity(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'uncommon':
      return CupertinoColors.systemGreen;
    case 'rare':
      return CupertinoColors.systemBlue;
    case 'legendary':
      return CupertinoColors.systemPurple;
    case 'mythical':
      return CupertinoColors.systemOrange;
    case 'divine':
      return CupertinoColors.systemYellow;
    case 'prismatic':
      return CupertinoColors.systemPink;
    default:
      return CupertinoColors.systemGrey;
  }
}

String _getHexColorForRarity(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'uncommon':
      return '#34C759';
    case 'rare':
      return '#007AFF';
    case 'legendary':
      return '#AF52DE';
    case 'mythical':
      return '#FF9500';
    case 'divine':
      return '#FFCC00';
    case 'prismatic':
      return '#FF2D55';
    default:
      return '#8E8E93';
  }
}

Future<void> _updateNotificationTitleOnly(String title) async {
  final bigTextStyleInformation = BigTextStyleInformation(_lastNotificationBody,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true);
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    _notificationChannelId,
    'Servicio de Sniper 24/7',
    icon: '@mipmap/ic_launcher',
    ongoing: true,
    styleInformation: bigTextStyleInformation,
    importance: Importance.low,
    priority: Priority.low,
    onlyAlertOnce: true,
  );
  await _notificationsPlugin.show(_notificationId, title, _lastNotificationBody,
      NotificationDetails(android: androidPlatformChannelSpecifics));
}

Future<void> _updateNotification(
    {required String title, required String body}) async {
  _lastNotificationBody = body;
  final bigTextStyleInformation = BigTextStyleInformation(body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true);
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    _notificationChannelId,
    'Servicio de Sniper 24/7',
    icon: '@mipmap/ic_launcher',
    ongoing: true,
    styleInformation: bigTextStyleInformation,
    importance: Importance.low,
    priority: Priority.low,
  );
  await _notificationsPlugin.show(_notificationId, title, body,
      NotificationDetails(android: androidPlatformChannelSpecifics));
}

DateTime? _getNextStockTime(Map<String, List<StockItemEntity>> stock) {
  DateTime? earliestFutureDate;
  final now = DateTime.now();
  stock.values
      .expand((list) => list)
      .where((item) => item.endDate.isAfter(now))
      .forEach((item) {
    if (earliestFutureDate == null ||
        item.endDate.isBefore(earliestFutureDate!)) {
      earliestFutureDate = item.endDate;
    }
  });
  return earliestFutureDate;
}

String _formatRemainingTime(Duration duration) {
  if (duration.isNegative) return '0s';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

String _formatTime(DateTime time) {
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
}

String _getEmojiForWeather(String weatherName) {
  final name = weatherName.toLowerCase();
  if (name.contains('rain')) return '🌧️';
  if (name.contains('frost')) return '❄️';
  if (name.contains('swarm')) return '🐝';
  if (name.contains('storm')) return '⛈️';
  if (name.contains('meteor')) return '☄️';
  if (name.contains('sun')) return '☀️';
  if (name.contains('disco')) return '🕺';
  if (name.contains('bloodmoon')) return '🌙';
  return '☁️';
}

String _getEmojiForItem(String itemName) {
  final name = itemName.toLowerCase();
  if (name.contains('egg')) return '🥚';
  if (name.contains('carrot')) return '🥕';
  if (name.contains('strawberry')) return '🍓';
  if (name.contains('tomato')) return '🍅';
  if (name.contains('blueberry')) return '🫐';
  if (name.contains('watermelon')) return '🍉';
  if (name.contains('pineapple')) return '🍍';
  if (name.contains('apple')) return '🍎';
  if (name.contains('sprinkler')) return '💦';
  if (name.contains('tool') ||
      name.contains('trowel') ||
      name.contains('wrench')) return '🛠️';
  if (name.contains('can') || name.contains('spray')) return '🥫';
  return '🌱';
}

class BackgroundServiceHandler {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    const alarmChannel = AndroidNotificationChannel(
      _alarmChannelId,
      'Alarmas de Sniper',
      description: 'Canal para las alarmas críticas de items encontrados.',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
    );
    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Servicio de Sniper 24/7',
      description: 'Notificación persistente para el monitoreo de stock.',
      importance: Importance.low,
    );
    final plugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(channel);
    await plugin?.createNotificationChannel(alarmChannel);
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }
}
