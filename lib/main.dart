import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'core/theme/app_theme.dart';
import 'data/datasources/item_info_rest_data_source.dart';
import 'data/datasources/stock_websocket_data_source.dart';
import 'data/repositories/stock_repository_impl.dart';
import 'domain/usecases/get_all_items_info_usecase.dart';
import 'domain/usecases/listen_to_stock_updates_usecase.dart';
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  // --- INYECCIÓN DE DEPENDENCIAS ---
  final ItemInfoRestDataSource restDataSource =
      ItemInfoRestDataSourceImpl(client: http.Client());
  final StockWebSocketDataSource webSocketDataSource =
      StockWebSocketDataSourceImpl();

  final StockRepositoryImpl stockRepository = StockRepositoryImpl(
    restDataSource: restDataSource,
    webSocketDataSource: webSocketDataSource,
  );

  final GetAllItemsInfoUseCase getAllItemsInfo =
      GetAllItemsInfoUseCase(stockRepository);
  final ListenToStockUpdatesUseCase listenToStockUpdates =
      ListenToStockUpdatesUseCase(stockRepository);

  final StockBloc stockBloc = StockBloc(
    getAllItemsInfo: getAllItemsInfo,
    listenToStockUpdates: listenToStockUpdates,
  );

  runApp(MyApp(stockBloc: stockBloc));
}

class MyApp extends StatelessWidget {
  final StockBloc stockBloc;
  const MyApp({super.key, required this.stockBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => stockBloc..add(SubscriptionRequested()),
      child: const CupertinoApp(
        title: 'Grow a Garden Tracker',
        theme: AppTheme.cupertinoTheme,
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}
