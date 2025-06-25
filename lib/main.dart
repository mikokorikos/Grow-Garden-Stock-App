import 'package:flutter/cupertino.dart';
import 'dart:async'; // Para StreamSubscription
import 'dart:convert'; // Para jsonDecode
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:grow_garden_tracker/core/background/background_service_handler.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/core/services/navigation_event_service.dart'; // Importar
import 'package:grow_garden_tracker/core/services/notification_service.dart';
import 'package:grow_garden_tracker/core/services/ringtone_service.dart';
import 'package:grow_garden_tracker/data/repositories/item_info_repository_impl.dart';
import 'package:grow_garden_tracker/features/sniper/bloc/sniper_bloc.dart';
import 'package:grow_garden_tracker/features/sniper/bloc/sniper_event.dart';
import 'package:grow_garden_tracker/presentation/widgets/sniper_alarm_dialog.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart'; // Importar logger

import 'core/theme/app_theme.dart';
import 'data/datasources/item_info_rest_data_source.dart';
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'domain/usecases/get_all_items_info_usecase.dart';

// Instancias de los servicios ahora centralizadas (o podrían ser inyectadas/localizadas)
final RingtoneService ringtoneService = RingtoneService();
final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa el servicio de notificaciones
  await notificationService.initialize();

  await BackgroundServiceHandler.initializeService();

  // Considerar inyectar el cliente HTTP si la app crece.
  // Por ahora, se mantiene la creación directa para simplicidad.
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

class MyApp extends StatefulWidget { // Convertido a StatefulWidget
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
  // GlobalKey para acceder al NavigatorState, necesario para mostrar diálogos/rutas
  // desde fuera del contexto de un widget específico que tenga acceso a Navigator.of(context)
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _navSubscription = NavigationEventService().navStream.listen((event) {
      if (event.type == NavigationEventType.showSniperAlarm) {
        // Usar el navigatorKey para obtener un contexto que pueda mostrar el diálogo
        final context = navigatorKey.currentContext;
        if (context != null) {
          _showSniperAlarm(context, event.data);
        } else {
          logW("[MyAppState] navigatorKey.currentContext es nulo. No se puede mostrar la alarma de sniper.");
        }
      }
    });
  }

  void _showSniperAlarm(BuildContext context, dynamic eventData) {
      List<String> foundItems = ["Item Desconocido"];
      Color rarityColor = CupertinoColors.systemRed; // Color por defecto

      if (eventData is Map) {
        final dataMap = eventData;
        if (dataMap['type'] == 'sniper_alarm_legacy') {
            // Manejo del payload legacy
            foundItems = [dataMap['message']?.toString() ?? "¡Alarma!"];
        } else {
            // Nuevo formato de payload
            if (dataMap.containsKey('items') && dataMap['items'] is List) {
              foundItems = List<String>.from(dataMap['items']);
            } else if (dataMap.containsKey('items') && dataMap['items'] is String) {
              // Si 'items' es un JSON string de una lista
              try {
                foundItems = List<String>.from(jsonDecode(dataMap['items']));
              } catch(e) {
                logE("Error decodificando items del payload: $e");
                foundItems = [dataMap['items']]; //Fallback a tomarlo como string simple
              }
            }
            if (dataMap.containsKey('rarityColorHex') && dataMap['rarityColorHex'] is String) {
               try {
                rarityColor = Color(int.parse(dataMap['rarityColorHex']));
               } catch(e) {
                logE("Error parseando rarityColorHex del payload: $e");
               }
            } else if (dataMap.containsKey('rarityColorHex') && dataMap['rarityColorHex'] is int) {
                rarityColor = Color(dataMap['rarityColorHex']);
            }
        }
      } else if (eventData is String) { // Por si acaso se envía solo un string
        foundItems = [eventData];
      }


      logI("[MyAppState] Evento showSniperAlarm recibido. Mostrando diálogo. Items: $foundItems");
      ringtoneService.stop();
      ringtoneService.play();

      notificationService.showSniperAlarmNotification(
        'Sniper Alarm!',
        'Found: ${foundItems.join(', ')}',
        // Re-construir payload para la notificación si es necesario, o dejarlo vacío
        // si la notificación es solo para el fullScreenIntent y la data ya está en la app.
        payloadData: eventData is Map ? eventData : {'type': 'sniper_alarm_simple', 'items': jsonEncode(foundItems)},
      );

      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SniperAlarmDialog(
          foundItems: foundItems,
          rarityColor: rarityColor,
        ),
      ).whenComplete(() {
        logD("[MyAppState] Diálogo de alarma (desde NavEvent) cerrado.");
        ringtoneService.stop();
        notificationService.cancelSniperAlarmNotification(); // Cancelar la notificación que podría estar activa
      });
  }

  @override
  void dispose() {
    _navSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.stockBloc..add(ListenToStockUpdates())),
        BlocProvider.value(value: widget.sniperBloc..add(LoadSniperData())),
      ],
      child: BlocListener<StockBloc, StockState>(
        bloc: widget.stockBloc,
        listener: (context, state) {
          if (state is SniperAlarmTriggered) {
            logI("[MyAppState] SniperAlarmTriggered (desde StockBloc) recibido. Items: ${state.foundItems}");
            // Disparar evento de navegación para centralizar la lógica de mostrar la alarma
            NavigationEventService().fireEvent(
              NavigationEventType.showSniperAlarm,
              data: {
                'type': 'sniper_alarm', // Tipo específico para distinguir del payload de notificación simple
                'items': state.foundItems,
                'rarityColorHex': state.rarityColor.value.toString(),
              }
            );
          } else if (state is StockError) {
            logE("[MyAppState] StockError recibido en BlocListener: ${state.message}");
            // Considerar mostrar un Toast o SnackBar aquí para errores generales de stock
            // Ejemplo: Fluttertoast.showToast(msg: "Error de Stock: ${state.message}");
          }
        },
        child: CupertinoApp(
          navigatorKey: navigatorKey, // Asignar el GlobalKey al CupertinoApp
          title: 'Grow a Garden Tracker',
          theme: AppTheme.cupertinoTheme,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
