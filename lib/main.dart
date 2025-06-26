import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:grow_garden_tracker/core/background/background_service_handler.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/core/services/navigation_event_service.dart';
import 'package:grow_garden_tracker/core/services/notification_service.dart';
import 'package:grow_garden_tracker/core/services/ringtone_service.dart';
import 'package:grow_garden_tracker/data/repositories/item_info_repository_impl.dart';
import 'package:grow_garden_tracker/features/sniper/bloc/sniper_bloc.dart';
import 'package:grow_garden_tracker/features/sniper/bloc/sniper_event.dart';
import 'package:grow_garden_tracker/presentation/widgets/sniper_alarm_dialog.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/item_info_rest_data_source.dart';
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'domain/usecases/get_all_items_info_usecase.dart';

final RingtoneService ringtoneService = RingtoneService();
final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await notificationService.initialize();
  await BackgroundServiceHandler.initializeService();

  final client = http.Client();
  final itemInfoDataSource = ItemInfoRestDataSourceImpl(client: client);
  final itemInfoRepository =
      ItemInfoRepositoryImpl(itemInfoDataSource: itemInfoDataSource);
  final getAllItemsInfo = GetAllItemsInfoUseCase(itemInfoRepository);
  final sniperRepository = SniperRepository();

  final stockBloc = StockBloc(getAllItemsInfoUseCase: getAllItemsInfo);
  final sniperBloc = SniperBloc(
    getAllItemsInfoUseCase: getAllItemsInfo,
    sniperRepository: sniperRepository,
  );

  runApp(MyApp(
    stockBloc: stockBloc,
    sniperBloc: sniperBloc,
  ));
}

class MyApp extends StatefulWidget {
  final StockBloc stockBloc;
  final SniperBloc sniperBloc;

  const MyApp({
    super.key,
    required this.stockBloc,
    required this.sniperBloc,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _navSubscription;
  StreamSubscription? _alarmServiceSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Flag para prevenir alarmas en bucle
  bool _isAlarmCurrentlyShowing = false;

  @override
  void initState() {
    super.initState();

    _navSubscription = NavigationEventService().navStream.listen((event) {
      if (event.type == NavigationEventType.showSniperAlarm) {
        if (!mounted) return;
        final context = navigatorKey.currentContext;
        if (context != null) {
          _showSniperAlarm(context, event.data);
        } else {
          logW(
              "[MyAppState] navigatorKey.currentContext es nulo. No se puede mostrar la alarma de sniper.");
        }
      }
    });

    _alarmServiceSubscription =
        FlutterBackgroundService().on('sniperAlarm').listen((eventData) {
      if (eventData != null) {
        logI(
            "[MyAppState] Evento 'sniperAlarm' recibido directamente del servicio. Disparando evento de navegación.");
        NavigationEventService()
            .fireEvent(NavigationEventType.showSniperAlarm, data: eventData);
      }
    });
  }

  void _showSniperAlarm(BuildContext context, dynamic eventData) async {
    // === INICIO DE CAMBIOS ===
    // 1. Prevenir que la función se ejecute de nuevo si ya hay una alarma mostrándose.
    if (_isAlarmCurrentlyShowing) {
      logW(
          "[MyAppState] Alarma ya se está mostrando. Ignorando nueva solicitud.");
      return;
    }
    _isAlarmCurrentlyShowing = true;
    // === FIN DE CAMBIOS ===

    List<String> foundItems = ["Item Desconocido"];
    Color rarityColor = CupertinoColors.systemRed;

    // ... (El parseo de `eventData` se mantiene igual) ...
    if (eventData is Map) {
      final Map<String, dynamic> dataMap = Map<String, dynamic>.from(eventData);
      if (dataMap['type'] == 'sniper_alarm_legacy') {
        foundItems = [dataMap['message']?.toString() ?? "¡Alarma!"];
      } else {
        dynamic itemsData = dataMap['items'];
        if (itemsData is List) {
          try {
            foundItems =
                List<String>.from(itemsData.map((item) => item.toString()));
          } catch (e) {
            logE(
                "[MyAppState] Error convirtiendo lista de items a List<String>: $e. ItemsData: $itemsData");
            foundItems = ["Error en items"];
          }
        } else if (itemsData is String) {
          try {
            final decodedList = jsonDecode(itemsData);
            if (decodedList is List) {
              foundItems =
                  List<String>.from(decodedList.map((item) => item.toString()));
            } else {
              logW(
                  "[MyAppState] Items decodificados no son una lista: $decodedList");
              foundItems = [itemsData];
            }
          } catch (e) {
            logW(
                "[MyAppState] Items no era un JSON string de lista, tratándolo como string simple: $itemsData. Error: $e");
            foundItems = [itemsData];
          }
        } else if (itemsData != null) {
          logW(
              "[MyAppState] Tipo de itemsData no esperado: ${itemsData.runtimeType}. Valor: $itemsData");
          foundItems = ["Formato de items no reconocido"];
        }

        dynamic colorData = dataMap['rarityColorHex'];
        if (colorData is String) {
          try {
            rarityColor = Color(int.parse(colorData));
          } catch (e) {
            logE(
                "[MyAppState] Error parseando rarityColorHex (String) del payload: $colorData. Error: $e");
          }
        } else if (colorData is int) {
          rarityColor = Color(colorData);
        } else if (colorData != null) {
          logW(
              "[MyAppState] Tipo de colorData no esperado: ${colorData.runtimeType}. Valor: $colorData");
        }
      }
    } else if (eventData is String) {
      foundItems = [eventData];
    }

    logI(
        "[MyAppState] _showSniperAlarm para items: $foundItems, Color: $rarityColor");

    // Cancelar notificaciones viejas (esto está bien)
    logD("[MyAppState] Cancelando notificación de alarma anterior (ID 999)...");
    await notificationService.cancelSniperAlarmNotification();
    await Future.delayed(const Duration(milliseconds: 100));

    // Reproducir sonido (esto está bien)
    logD("[MyAppState] Reproduciendo sonido de alarma...");
    ringtoneService.stop();
    ringtoneService.play();

    // === INICIO DE CAMBIOS ===
    // 2. ELIMINAR LA CREACIÓN DE UNA NUEVA NOTIFICACIÓN DESDE AQUÍ
    // El servicio en segundo plano ya creó la notificación que despertó al teléfono.
    // Volver a crearla aquí es lo que causa el bucle.
    /*
    logD(
        "[MyAppState] Mostrando nueva notificación de alarma (con fullScreenIntent)...");
    // ... (toda la lógica de `currentPayloadForNotification` se elimina) ...
    await notificationService.showSniperAlarmNotification(
      'Sniper Alarm!',
      'Found: ${foundItems.join(', ')}',
      payloadData: currentPayloadForNotification,
    );
    */
    // === FIN DE CAMBIOS ===

    // Navegar a la pantalla de la alarma (esto está bien)
    if (!mounted) {
      // === INICIO DE CAMBIOS ===
      // 3. Resetear el flag si el widget ya no está montado
      _isAlarmCurrentlyShowing = false;
      // === FIN DE CAMBIOS ===
      return;
    }
    logD("[MyAppState] Intentando navegar a AlarmScreen...");
    navigatorKey.currentState
        ?.push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => AlarmScreen(
          foundItems: foundItems,
          rarityColor: rarityColor,
        ),
      ),
    )
        ?.whenComplete(() {
      logD(
          "[MyAppState] AlarmScreen cerrada. Deteniendo tono y cancelando notificación.");
      ringtoneService.stop();
      notificationService.cancelSniperAlarmNotification();
      // === INICIO DE CAMBIOS ===
      // 4. Resetear el flag cuando la pantalla de alarma se cierra
      _isAlarmCurrentlyShowing = false;
      // === FIN DE CAMBIOS ===
    });
  }

  @override
  void dispose() {
    _navSubscription?.cancel();
    _alarmServiceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
            value: widget.stockBloc..add(ListenToStockUpdates())),
        BlocProvider.value(value: widget.sniperBloc..add(LoadSniperData())),
      ],
      child: BlocListener<StockBloc, StockState>(
        bloc: widget.stockBloc,
        listener: (context, state) {
          if (state is StockError) {
            logE(
                "[MyAppState] StockError recibido en BlocListener: ${state.message}");
          }
        },
        child: CupertinoApp(
          navigatorKey: navigatorKey,
          title: 'Grow a Garden Tracker',
          theme: AppTheme.cupertinoTheme,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

class AlarmScreen extends StatelessWidget {
  final List<String> foundItems;
  final Color rarityColor;

  const AlarmScreen({
    super.key,
    required this.foundItems,
    required this.rarityColor,
  });

  static const String routeName = '/alarm';

  @override
  Widget build(BuildContext context) {
    return SniperAlarmDialog(foundItems: foundItems, rarityColor: rarityColor);
  }
}
