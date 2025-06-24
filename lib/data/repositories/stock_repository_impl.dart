// Archivo: lib/data/repositories/stock_repository_impl.dart
import 'package:flutter/foundation.dart';
import 'package:grow_garden_tracker/data/datasources/stock_rest_data_source.dart';

import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/item_info_rest_data_source.dart';
import '../models/stock_item_model.dart';
import '../models/weather_model.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRestDataSource stockDataSource;
  final ItemInfoRestDataSource itemInfoDataSource;
  final String _className = "StockRepositoryImpl";

  StockRepositoryImpl({
    required this.stockDataSource,
    required this.itemInfoDataSource,
  });

  @override
  Future<(Map<String, List<StockItemEntity>>, List<WeatherEntity>)>
      getStockAndWeather() async {
    final methodName = "$_className.getStockAndWeather";
    debugPrint("[$methodName] Iniciando...");

    try {
      // Hacemos las dos llamadas a la API en paralelo para optimizar el tiempo.
      debugPrint("[$methodName] Solicitando stock y clima a los data sources...");
      final results = await Future.wait([
        stockDataSource.getStock(),
        stockDataSource.getWeather(),
      ]);
      debugPrint("[$methodName] Datos de stock y clima recibidos de los data sources.");

      final rawStockData = results[0] as Map<String, dynamic>;
      final rawWeatherData = results[1] as List<dynamic>;
      debugPrint("[$methodName] Datos crudos - Stock: ${rawStockData.keys.length} categorías, Clima: ${rawWeatherData.length} registros.");

      final stockData = <String, List<StockItemEntity>>{};
      rawStockData.forEach((key, value) {
        if (value is List && key.endsWith('_stock')) {
          final categoryName = key.replaceAll('_stock', '');
          stockData[categoryName] =
              value.map((item) => StockItemModel.fromJson(item)).toList();
        }
      });

      final weatherData =
          rawWeatherData.map((item) => WeatherModel.fromJson(item)).toList();

      debugPrint("[$methodName] Datos procesados - Stock: ${stockData.keys.length} categorías, Clima: ${weatherData.length} entidades.");
      debugPrint("[$methodName] Retornando stock y clima procesados.");
      return (stockData, weatherData);
    } catch (e, s) {
      debugPrint("[$methodName] Excepción: $e\nStackTrace: $s");
      rethrow; // Permite que las capas superiores manejen la excepción
    }
  }

  @override
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo() async {
    final methodName = "$_className.getAllItemsInfo";
    debugPrint("[$methodName] Iniciando...");
    try {
      debugPrint("[$methodName] Solicitando todos los items info del data source...");
      final itemsList = await itemInfoDataSource.getAllItemsInfo();
      debugPrint("[$methodName] Recibidos ${itemsList.length} items info del data source.");

      final result = {for (var item in itemsList) item.name: item};
      debugPrint("[$methodName] Items info procesados en un mapa de ${result.length} entradas.");
      debugPrint("[$methodName] Retornando mapa de items info.");
      return result;
    } catch (e, s) {
      debugPrint("[$methodName] Excepción: $e\nStackTrace: $s");
      rethrow; // Permite que las capas superiores manejen la excepción
    }
  }
}
