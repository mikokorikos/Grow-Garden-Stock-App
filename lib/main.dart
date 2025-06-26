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
        // Guard against calls after widget disposal or before context is available.
        if (!mounted) return;
        final context = navigatorKey.currentContext;
        if (context != null) {
          _showSniperAlarm(context, event.data);
        } else {
          logW("[MyAppState] navigatorKey.currentContext es nulo. No se puede mostrar la alarma de sniper.");
          // Podríamos intentar con un pequeño delay si el contexto no está listo inmediatamente
          // Future.delayed(Duration(milliseconds: 100), () {
          //   if (!mounted) return;
          //   final delayedContext = navigatorKey.currentContext;
          //   if (delayedContext != null) _showSniperAlarm(delayedContext, event.data);
          // });
        }
      }
    });
  }

  // Usamos async aquí para poder usar await para la cancelación y el delay
  void _showSniperAlarm(BuildContext context, dynamic eventData) async {
      List<String> foundItems = ["Item Desconocido"];
      Color rarityColor = CupertinoColors.systemRed;

      if (eventData is Map) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(eventData);
        if (dataMap['type'] == 'sniper_alarm_legacy') {
            foundItems = [dataMap['message']?.toString() ?? "¡Alarma!"];
        } else {
            dynamic itemsData = dataMap['items'];
            if (itemsData is List) {
              try {
                foundItems = List<String>.from(itemsData.map((item) => item.toString()));
              } catch (e) {
                 logE("[MyAppState] Error convirtiendo lista de items a List<String>: $e. ItemsData: $itemsData");
                 foundItems = ["Error en items"]; // Fallback
              }
            } else if (itemsData is String) {
              try {
                final decodedList = jsonDecode(itemsData);
                if (decodedList is List) {
                   foundItems = List<String>.from(decodedList.map((item) => item.toString()));
                } else {
                  logW("[MyAppState] Items decodificados no son una lista: $decodedList");
                  foundItems = [itemsData];
                }
              } catch(e) {
                logW("[MyAppState] Items no era un JSON string de lista, tratándolo como string simple: $itemsData. Error: $e");
                foundItems = [itemsData];
              }
            } else if (itemsData != null) {
                logW("[MyAppState] Tipo de itemsData no esperado: ${itemsData.runtimeType}. Valor: $itemsData");
                foundItems = ["Formato de items no reconocido"];
            }


            dynamic colorData = dataMap['rarityColorHex'];
            if (colorData is String) {
               try {
                rarityColor = Color(int.parse(colorData));
               } catch(e) {
                logE("[MyAppState] Error parseando rarityColorHex (String) del payload: $colorData. Error: $e");
               }
            } else if (colorData is int) {
                rarityColor = Color(colorData);
            } else if (colorData != null) {
                logW("[MyAppState] Tipo de colorData no esperado: ${colorData.runtimeType}. Valor: $colorData");
            }
        }
      } else if (eventData is String) {
        foundItems = [eventData];
      }

      logI("[MyAppState] _showSniperAlarm para items: $foundItems, Color: $rarityColor");

      // 1. Cancelar notificación anterior para ayudar al fullScreenIntent
      logD("[MyAppState] Cancelando notificación de alarma anterior (ID 999)...");
      await notificationService.cancelSniperAlarmNotification();
      // Pequeña demora para asegurar que el sistema procese la cancelación
      await Future.delayed(const Duration(milliseconds: 200)); // Aumentado ligeramente

      // 2. Sonido
      logD("[MyAppState] Reproduciendo sonido de alarma...");
      ringtoneService.stop();
      ringtoneService.play();

      // 3. Mostrar nueva notificación (con fullScreenIntent)
      logD("[MyAppState] Mostrando nueva notificación de alarma (con fullScreenIntent)...");
      Map<String, dynamic> currentPayloadForNotification;
      if (eventData is Map) {
        currentPayloadForNotification = Map<String, dynamic>.from(eventData);
        // Asegurar que los datos estén en el formato esperado por _handleNotificationPayload
        currentPayloadForNotification['items'] = foundItems;
        currentPayloadForNotification['rarityColorHex'] = rarityColor.value;
      } else {
        // Fallback si eventData no era un mapa (aunque debería serlo)
        currentPayloadForNotification = {
          'type': 'sniper_alarm_simple',
          'items': foundItems, // Ya es List<String>
          'rarityColorHex': rarityColor.value,
        };
      }
       // Asegurar un tipo si no venía
      currentPayloadForNotification.putIfAbsent('type', () => 'sniper_alarm');


      await notificationService.showSniperAlarmNotification(
        'Sniper Alarm!',
        'Found: ${foundItems.join(', ')}',
        payloadData: currentPayloadForNotification,
      );

      // 4. Navegar a la pantalla de alarma (si la app está en primer plano o es traída al frente)
      // Esto es importante para el caso en que la app esté activa.
      // Si la app estaba cerrada/fondo, el fullScreenIntent debería haberla traído al frente,
      // y esta navegación asegura que se muestre la UI de alarma.
      if (!mounted) return; // Nueva verificación de mounted antes de la navegación
      logD("[MyAppState] Intentando navegar a AlarmScreen...");
      navigatorKey.currentState?.push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => AlarmScreen( // Usar la nueva AlarmScreen
            foundItems: foundItems,
            rarityColor: rarityColor,
          ),
        ),
      )?.whenComplete(() {
        logD("[MyAppState] AlarmScreen cerrada (popeada). Deteniendo tono y cancelando notificación activa.");
        ringtoneService.stop();
        notificationService.cancelSniperAlarmNotification();
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
            NavigationEventService().fireEvent(
              NavigationEventType.showSniperAlarm,
              data: {
                'type': 'sniper_alarm',
                'items': state.foundItems,
                'rarityColorHex': state.rarityColor.value,
              }
            );
          } else if (state is StockError) {
            logE("[MyAppState] StockError recibido en BlocListener: ${state.message}");
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

// ========== NUEVA PANTALLA DE ALARMA ==========
// Podría ir en su propio archivo: lib/presentation/screens/alarm_screen.dart
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
    // Esta pantalla debería ser lo suficientemente "ruidosa" visualmente y funcionalmente
    // para actuar como una alarma. SniperAlarmDialog ya tiene mucha de esa lógica.
    // Lo importante es que esta pantalla pueda ser popeada por el usuario
    // para que el .whenComplete() en _showSniperAlarm se active.
    return SniperAlarmDialog( // SniperAlarmDialog ya tiene su propia lógica de pop
        foundItems: foundItems,
        rarityColor: rarityColor
    );
  }
}
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
