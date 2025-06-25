import 'dart:async';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:grow_garden_tracker/data/datasources/item_info_rest_data_source.dart';
import 'package:grow_garden_tracker/data/datasources/stock_rest_data_source.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/entities/stock_item_entity.dart';
import 'package:vibration/vibration.dart';
import 'package:grow_garden_tracker/data/models/stock_item_model.dart';

const _notificationChannelId = 'sniper_service_channel';
const _notificationId = 888;
final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

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
  bool _isStopped = false;
  int _failureCount = 0;
  
  Map<String, dynamic>? _lastKnownStock;
  List<dynamic>? _lastKnownWeather;
  Map<String, ItemInfoEntity> _allItemsInfo = {};
  List<String> _sniperList = [];

  final stockDataSource = StockRestDataSourceImpl(client: http.Client());
  final itemInfoDataSource = ItemInfoRestDataSourceImpl(client: http.Client());

  void stop() {
    _isStopped = true;
    _timer?.cancel();
    _notificationsPlugin.cancel(_notificationId);
    debugPrint('[ServiceLogic] Servicio detenido.');
  }

  void updateSniperList(List<String> list) {
    _sniperList = list;
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
      final itemsList = await itemInfoDataSource.getAllItemsInfo();
      _allItemsInfo = {for (var item in itemsList) item.name: item};
    } catch (e) {
      debugPrint('[ServiceLogic] Error fatal al cargar info de items: $e');
    }
    _tick(service);
  }

  Future<void> _tick(ServiceInstance service) async {
    if (_isStopped) return;

    Duration nextDelay;

    try {
      final results = await Future.wait([
        stockDataSource.getStock(),
        stockDataSource.getWeather(),
      ]);

      final newStockMap = results[0] as Map<String, dynamic>;
      final newWeather = results[1] as List<dynamic>;
      final parsedStock = _parseStock(newStockMap); // Parseado una vez
      final stockChanged = !const DeepCollectionEquality().equals(_lastKnownStock, newStockMap);

      if (stockChanged) {
        debugPrint('[ServiceLogic] ¡Cambio de stock detectado!');
        _lastKnownStock = newStockMap;
        _lastKnownWeather = newWeather;
        
        service.invoke('updateStock', {'stock': newStockMap, 'weather': newWeather});

        final foundSniperItems = _checkForSniperItems(parsedStock, _sniperList);
        
        if (foundSniperItems.isNotEmpty) {
           Vibration.vibrate(pattern: [0, 500, 250, 500]);
           final highestRarity = _getHighestRarity(foundSniperItems, _allItemsInfo);
           final rarityColor = _getColorForRarity(highestRarity);
           service.invoke('sniperAlarm', {
             'items': foundSniperItems.map((e) => e.displayName).toList(),
             'rarityColorHex': rarityColor.value,
           });
        }
      }
      
      final expiration = _getNextStockTime(parsedStock);
      
      if (expiration != null && expiration.isAfter(DateTime.now())) {
        nextDelay = expiration.difference(DateTime.now()) + const Duration(seconds: 5);
      } else {
        nextDelay = const Duration(seconds: 60); 
      }
      
      _failureCount = 0;
      // --- MODIFICACIÓN CLAVE ---
      // Se pasa el stock parseado para construir la notificación.
      _updateDynamicNotification(
        nextStockTime: DateTime.now().add(nextDelay), 
        sniperList: _sniperList,
        currentStock: parsedStock,
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
      _updateNotification(title: "Error de Red", body: "Reintentando en $delaySeconds segundos...");
    }
    
    if (!_isStopped) {
      final scheduleDelay = nextDelay > Duration.zero ? nextDelay : Duration.zero;
      debugPrint('[ServiceLogic] Próxima revisión programada en ${scheduleDelay.inMinutes}m ${scheduleDelay.inSeconds % 60}s');
      _timer = Timer(scheduleDelay, () => _tick(service));
    }
  }
}

Map<String, List<StockItemEntity>> _parseStock(Map<String, dynamic> rawStock) {
  final Map<String, List<StockItemEntity>> stockData = {};
  rawStock.forEach((key, value) {
    if (value is List && key.endsWith('_stock')) {
      final category = key.replaceAll('_stock', '');
      stockData[category] = value.map((e) => StockItemModel.fromJson(e)).toList();
    }
  });
  return stockData;
}

List<StockItemEntity> _checkForSniperItems(Map<String, List<StockItemEntity>> stock, List<String> sniperList) {
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

String _getHighestRarity(List<StockItemEntity> items, Map<String, ItemInfoEntity> allInfo) {
  const rarityOrder = ['common', 'uncommon', 'rare', 'legendary', 'mythical', 'divine', 'prismatic'];
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
    case 'uncommon': return CupertinoColors.systemGreen;
    case 'rare': return CupertinoColors.systemBlue;
    case 'legendary': return CupertinoColors.systemPurple;
    case 'mythical': return CupertinoColors.systemOrange;
    case 'divine': return CupertinoColors.systemYellow;
    case 'prismatic': return CupertinoColors.systemPink;
    default: return CupertinoColors.systemGrey;
  }
}

// --- FUNCIÓN TOTALMENTE ACTUALIZADA ---
void _updateDynamicNotification({ 
  required DateTime? nextStockTime, 
  required List<String> sniperList,
  required Map<String, List<StockItemEntity>> currentStock,
}) {
  final title = nextStockTime != null
    ? 'Próxima Revisión: ${_formatTime(nextStockTime)}'
    : 'Buscando Stock...';
  
  final List<String> bodyLines = [];

  // 1. Añadir la línea de stock de semillas
  final seedStock = currentStock['seed'] ?? [];
  if (seedStock.isNotEmpty) {
    final seedEmojis = seedStock.map((item) => _getEmojiForItem(item.displayName)).join(' ');
    bodyLines.add('Stock: $seedEmojis');
  }

  // 2. Añadir la línea de la lista de sniper
  if (sniperList.isNotEmpty) {
    final sniperEmojis = sniperList.map((e) => _getEmojiForItem(e)).join(' ');
    bodyLines.add('Vigilando: $sniperEmojis');
  }

  // 3. Crear el cuerpo final
  String body;
  if (bodyLines.isEmpty) {
    body = 'Añade items a tu lista de sniper.';
  } else {
    body = bodyLines.join('\n'); // Unir líneas con un salto de línea
  }

  _updateNotification(title: title, body: body);
}

Future<void> _updateNotification({required String title, required String body}) async {
  // Usamos BigTextStyle para asegurar que ambas líneas sean visibles.
  final bigTextStyleInformation = BigTextStyleInformation(
    body, 
    htmlFormatBigText: true, 
    contentTitle: title, 
    htmlFormatContentTitle: true,
  );
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    _notificationChannelId,
    'Servicio de Sniper 24/7',
    icon: '@mipmap/ic_launcher',
    ongoing: true,
    styleInformation: bigTextStyleInformation, // Aplicar el estilo de texto grande
    importance: Importance.low,
    priority: Priority.low,
  );
  await _notificationsPlugin.show(
    _notificationId,
    title,
    body,
    NotificationDetails(android: androidPlatformChannelSpecifics),
  );
}

DateTime? _getNextStockTime(Map<String, List<StockItemEntity>> stock) {
  DateTime? earliestDate;
  stock.values.expand((list) => list).forEach((item) {
    if (earliestDate == null || item.endDate.isBefore(earliestDate!)) {
      earliestDate = item.endDate;
    }
  });
  return earliestDate;
}

String _formatTime(DateTime time) {
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
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
  if (name.contains('tool') || name.contains('trowel') || name.contains('wrench')) return '🛠️';
  return '🌱'; // Emoji por defecto
}

class BackgroundServiceHandler {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Servicio de Sniper 24/7',
      description: 'Notificación persistente para el monitoreo de stock.',
      importance: Importance.low,
    );
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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