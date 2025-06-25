import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:grow_garden_tracker/core/background/background_service_handler.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
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

class MyApp extends StatelessWidget {
  final StockBloc stockBloc;
  final SniperBloc sniperBloc;

  const MyApp({
    super.key,
    required this.stockBloc,
    required this.sniperBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: stockBloc..add(ListenToStockUpdates())),
        BlocProvider.value(value: sniperBloc..add(LoadSniperData())),
      ],
      child: BlocListener<StockBloc, StockState>(
        listener: (context, state) {
          if (state is SniperAlarmTriggered) {
            logI("[MyApp] SniperAlarmTriggered recibido en BlocListener. Items: ${state.foundItems}, Color: ${state.rarityColor}");
            ringtoneService.stop(); // Detiene cualquier sonido anterior para reiniciar el bucle.
            ringtoneService.play();

            final String itemsFoundString = state.foundItems.join(', ');
            logD("[MyApp] Mostrando notificación local para alarma de sniper.");
            notificationService.showSniperAlarmNotification(
              'Sniper Alarm!',
              'Found: $itemsFoundString',
            );

            showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => SniperAlarmDialog(
                foundItems: state.foundItems,
                rarityColor: state.rarityColor,
              ),
            ).whenComplete(() {
              logD("[MyApp] Diálogo de alarma de sniper cerrado. Deteniendo tono y cancelando notificación.");
              ringtoneService.stop();
              notificationService.cancelSniperAlarmNotification();
            });
          } else if (state is StockError) {
            // Ejemplo de cómo podríamos loguear otros estados importantes o errores
            logE("[MyApp] StockError recibido en BlocListener: ${state.message}");
            // Aquí podríamos mostrar un Toast/Snackbar si quisiéramos, además del log.
            // Fluttertoast.showToast(msg: "Error: ${state.message}");
          }
        },
        child: const CupertinoApp(
          title: 'Grow a Garden Tracker',
          theme: AppTheme.cupertinoTheme,
          debugShowCheckedModeBanner: false,
          home: HomeScreen(),
        ),
      ),
    );
  }
}
