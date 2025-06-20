// Archivo: lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'core/theme/app_theme.dart';
import 'data/datasources/item_info_rest_data_source.dart';
import 'data/datasources/stock_rest_data_source.dart';
import 'data/repositories/stock_repository_impl.dart';
import 'domain/repositories/stock_repository.dart';
import 'domain/usecases/get_all_items_info_usecase.dart';
import 'domain/usecases/get_stock_and_weather_usecase.dart';
import 'data/datasources/stock_rest_data_source.dart';
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  final http.Client client = http.Client();

  final StockRestDataSource stockDataSource =
      StockRestDataSourceImpl(client: client);
  final ItemInfoRestDataSource itemInfoDataSource =
      ItemInfoRestDataSourceImpl(client: client);

  final StockRepository stockRepository = StockRepositoryImpl(
    stockDataSource: stockDataSource,
    itemInfoDataSource: itemInfoDataSource,
  );

  final GetAllItemsInfoUseCase getAllItemsInfo =
      GetAllItemsInfoUseCase(stockRepository);
  final GetStockAndWeatherUseCase getStockAndWeather =
      GetStockAndWeatherUseCase(stockRepository);

  final StockBloc stockBloc = StockBloc(
    getAllItemsInfo: getAllItemsInfo,
    getStockAndWeather: getStockAndWeather,
  );

  runApp(MyApp(stockBloc: stockBloc));
}

class MyApp extends StatelessWidget {
  final StockBloc stockBloc;
  const MyApp({super.key, required this.stockBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => stockBloc..add(FetchInitialData()),
      child: const CupertinoApp(
        title: 'Grow a Garden Tracker',
        theme: AppTheme.cupertinoTheme,
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}
