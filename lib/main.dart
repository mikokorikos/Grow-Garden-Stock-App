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

  void _showSniperAlarm(BuildContext context, dynamic eventData) {
      List<String> foundItems = ["Item Desconocido"];
      Color rarityColor = CupertinoColors.systemRed; // Color por defecto

      if (eventData is Map) {
        // Asegurar que el mapa sea Map<String, dynamic> para el payload
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(eventData);

        if (dataMap['type'] == 'sniper_alarm_legacy') {
            foundItems = [dataMap['message']?.toString() ?? "¡Alarma!"];
        } else {
            dynamic itemsData = dataMap['items'];
            if (itemsData is List) {
              // Si ya es una lista de strings (o puede ser casteada)
              try {
                foundItems = List<String>.from(itemsData.map((item) => item.toString()));
              } catch (e) {
                 logE("Error convirtiendo lista de items a List<String>: $e");
              }
            } else if (itemsData is String) {
              try {
                // Intenta decodificar si es un JSON string de una lista
                final decodedList = jsonDecode(itemsData);
                if (decodedList is List) {
                   foundItems = List<String>.from(decodedList.map((item) => item.toString()));
                } else {
                  foundItems = [itemsData]; //Fallback a tomarlo como string simple
                }
              } catch(e) {
                logW("Items no era un JSON string de lista, tratándolo como string simple: $itemsData. Error: $e");
                foundItems = [itemsData];
              }
            }

            dynamic colorData = dataMap['rarityColorHex'];
            if (colorData is String) {
               try {
                rarityColor = Color(int.parse(colorData));
               } catch(e) {
                logE("Error parseando rarityColorHex (String) del payload: $colorData. Error: $e");
               }
            } else if (colorData is int) {
                rarityColor = Color(colorData);
            }
        }
      } else if (eventData is String) {
        foundItems = [eventData];
      }

      logI("[MyAppState] Evento showSniperAlarm recibido. Mostrando diálogo. Items: $foundItems, Color: $rarityColor");
      ringtoneService.stop();
      ringtoneService.play();

      // La notificación que se muestra aquí es principalmente para el caso en que la app ya esté en primer plano
      // y queramos que la notificación aparezca como una "heads-up" normal además del diálogo.
      // Si el fullScreenIntent ya trajo la app al frente, esta notificación podría ser redundante
      // o incluso no mostrarse dependiendo de la configuración de Android.
      // El payload aquí debe ser el mismo que se espera en _handleNotificationPayload
      Map<String, dynamic> currentPayloadForNotification;
      if (eventData is Map) {
        currentPayloadForNotification = Map<String, dynamic>.from(eventData);
      } else {
        currentPayloadForNotification = {'type': 'sniper_alarm_simple', 'items': jsonEncode(foundItems)};
      }
      // Aseguramos que el payload tenga los datos que _handleNotificationPayload espera
      currentPayloadForNotification['items'] = foundItems; // Asegurar que items sea List<String>
      currentPayloadForNotification['rarityColorHex'] = rarityColor.value;


      notificationService.showSniperAlarmNotification(
        'Sniper Alarm!',
        'Found: ${foundItems.join(', ')}',
        payloadData: currentPayloadForNotification,
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
