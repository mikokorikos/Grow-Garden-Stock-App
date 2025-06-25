import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:grow_garden_tracker/core/background/background_service_handler.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/data/repositories/item_info_repository_impl.dart';
import 'package:grow_garden_tracker/features/sniper/bloc/sniper_bloc.dart';
import 'package:grow_garden_tracker/features/sniper/bloc/sniper_event.dart';
import 'package:grow_garden_tracker/presentation/widgets/sniper_alarm_dialog.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/item_info_rest_data_source.dart';
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'domain/usecases/get_all_items_info_usecase.dart';

final RingtoneService ringtoneService = RingtoneService();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class RingtoneService {
  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();
  bool isPlaying = false;

  void play() {
    if (isPlaying) return;
    isPlaying = true;
    _player.playAlarm(asAlarm: true, looping: true);
  }

  void stop() {
    if (!isPlaying) return;
    isPlaying = false;
    _player.stop();
  }
}

void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  if (notificationResponse.payload == 'sniper_alarm_payload') {
    print('Alarma de sniper descartada por el usuario desde la notificación.');
    ringtoneService.stop();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

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
            // Detiene cualquier sonido anterior para reiniciar el bucle.
            ringtoneService.stop();
            ringtoneService.play();

            showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => SniperAlarmDialog(
                foundItems: state.foundItems,
                rarityColor: state.rarityColor,
              ),
            ).whenComplete(() {
              ringtoneService.stop();
              // Cancela la notificación de la alarma si el diálogo se cierra
              flutterLocalNotificationsPlugin.cancel(999);
            });
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
