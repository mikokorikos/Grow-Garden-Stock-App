// Archivo: lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'core/theme/app_theme.dart';
import 'data/datasources/item_info_rest_data_source.dart';
import 'data/datasources/stock_rest_data_source.dart';
import 'data/repositories/stock_repository_impl.dart';
import 'domain/repositories/stock_repository.dart';
import 'domain/usecases/get_all_items_info_usecase.dart';
import 'domain/usecases/get_stock_and_weather_usecase.dart';
// import 'data/datasources/stock_rest_data_source.dart'; // Duplicado, se elimina uno
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  const String appName = "Grow a Garden Tracker";
  debugPrint("[$appName] Iniciando aplicación...");

  debugPrint("[$appName main] Configurando dependencias...");
  final http.Client client = http.Client();

  final ItemInfoRestDataSource itemInfoDataSource =
      ItemInfoRestDataSourceImpl(client: client);
  final StockRestDataSource stockDataSource = // Corregido el orden para que coincida con el constructor de StockRepositoryImpl
      StockRestDataSourceImpl(client: client);

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
  debugPrint("[$appName main] Dependencias configuradas. StockBloc creado.");

  runApp(MyApp(stockBloc: stockBloc, appName: appName));
  debugPrint("[$appName main] runApp() llamado.");
}

class MyApp extends StatelessWidget {
  final StockBloc stockBloc;
  final String appName;
  const MyApp({super.key, required this.stockBloc, required this.appName});

  @override
  Widget build(BuildContext context) {
    final methodName = "$appName.MyApp.build";
    debugPrint("[$methodName] Construyendo widget MyApp...");
    return BlocProvider(
      create: (context) {
        debugPrint("[$methodName BlocProvider] Creando y proveyendo StockBloc. Añadiendo FetchInitialData event.");
        return stockBloc..add(FetchInitialData());
      },
      child: CupertinoApp(
        title: 'Grow a Garden Tracker', // El título aquí es para el sistema operativo, no necesita el appName variable
        theme: AppTheme.cupertinoTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
        builder: (context, child) {
          debugPrint("[$methodName CupertinoApp.builder] CupertinoApp construido.");
          return child!;
        },
      ),
    );
  }
}
