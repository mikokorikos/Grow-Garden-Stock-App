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

import 'core/theme/app_theme.dart';
import 'data/datasources/item_info_rest_data_source.dart';
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'domain/usecases/get_all_items_info_usecase.dart';

class RingtoneService {
  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();

  void play() => _player.playAlarm(asAlarm: true, looping: true);
  void stop() => _player.stop();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundServiceHandler.initializeService();

  // --- Dependencias Centralizadas ---
  final client = http.Client();
  final itemInfoDataSource = ItemInfoRestDataSourceImpl(client: client);
  final itemInfoRepository =
      ItemInfoRepositoryImpl(itemInfoDataSource: itemInfoDataSource);
  final getAllItemsInfo = GetAllItemsInfoUseCase(itemInfoRepository);
  final sniperRepository = SniperRepository();

  // --- BLoCs Centralizados ---
  final stockBloc = StockBloc(getAllItemsInfoUseCase: getAllItemsInfo);
  final sniperBloc = SniperBloc(
    getAllItemsInfoUseCase: getAllItemsInfo,
    sniperRepository: sniperRepository,
  );

  final ringtoneService = RingtoneService();

  runApp(MyApp(
    stockBloc: stockBloc,
    sniperBloc: sniperBloc,
    ringtoneService: ringtoneService,
  ));
}

class MyApp extends StatelessWidget {
  final StockBloc stockBloc;
  final SniperBloc sniperBloc;
  final RingtoneService ringtoneService;

  const MyApp({
    super.key,
    required this.stockBloc,
    required this.sniperBloc,
    required this.ringtoneService,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos MultiBlocProvider para proveer ambos BLoCs al árbol de widgets.
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: stockBloc..add(ListenToStockUpdates())),
        BlocProvider.value(value: sniperBloc..add(LoadSniperData())),
      ],
      child: BlocListener<StockBloc, StockState>(
        listener: (context, state) {
          if (state is SniperAlarmTriggered) {
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
