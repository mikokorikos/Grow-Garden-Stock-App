import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart'; // IMPORTANTE AÑADIR
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
import 'presentation/screens/loading_screen.dart'; // IMPORTANTE AÑADIR
import 'domain/usecases/get_all_items_info_usecase.dart';

// Instancias de los servicios
final RingtoneService ringtoneService = RingtoneService();
final NotificationService notificationService = NotificationService();

Future<void> main() async {
  // Asegura que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // === INICIO DE CAMBIOS ===
  // 1. Inicializar Hive para la base de datos local
  await Hive.initFlutter();
  // === FIN DE CAMBIOS ===

  // Inicializar el resto de los servicios
  await notificationService.initialize();
  await BackgroundServiceHandler.initializeService();

  // Inyección de dependencias (creación de BLoCs y repositorios)
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

  // Ejecutar la aplicación
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
    if (_isAlarmCurrentlyShowing) {
      logW(
          "[MyAppState] Alarma ya se está mostrando. Ignorando nueva solicitud.");
      return;
    }
    _isAlarmCurrentlyShowing = true;

    List<String> foundItems = ["Item Desconocido"];
    Color rarityColor = CupertinoColors.systemRed;

    if (eventData is Map) {
      final Map<String, dynamic> dataMap = Map<String, dynamic>.from(eventData);
      dynamic itemsData = dataMap['items'];
      if (itemsData is List) {
        foundItems =
            List<String>.from(itemsData.map((item) => item.toString()));
      }
      dynamic colorData = dataMap['rarityColorHex'];
      if (colorData is int) {
        rarityColor = Color(colorData);
      }
    }

    logI(
        "[MyAppState] _showSniperAlarm para items: $foundItems, Color: $rarityColor");

    logD("[MyAppState] Cancelando notificación de alarma anterior (ID 999)...");
    await notificationService.cancelSniperAlarmNotification();
    await Future.delayed(const Duration(milliseconds: 100));

    logD("[MyAppState] Reproduciendo sonido de alarma...");
    ringtoneService.stop();
    ringtoneService.play();

    if (!mounted) {
      _isAlarmCurrentlyShowing = false;
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
      _isAlarmCurrentlyShowing = false;
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
          // === INICIO DE CAMBIOS ===
          // 2. La pantalla de inicio ahora es tu LoadingScreen
          home: const LoadingScreen(),
          // === FIN DE CAMBIOS ===
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

  @override
  Widget build(BuildContext context) {
    return SniperAlarmDialog(foundItems: foundItems, rarityColor: rarityColor);
  }
}
