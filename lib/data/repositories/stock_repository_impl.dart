// Archivo: lib/data/repositories/stock_repository_impl.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/item_info_rest_data_source.dart';
import '../datasources/stock_rest_data_source.dart';
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
      debugPrint(
          "[$methodName] Solicitando stock y clima a los data sources en paralelo...");
      final results = await Future.wait([
        stockDataSource.getStock(),
        stockDataSource.getWeather(),
      ]);
      debugPrint("[$methodName] Datos recibidos de los data sources.");

      final rawStockData = results[0] as Map<String, dynamic>;
      final rawWeatherData = results[1] as List<dynamic>;

      debugPrint("[$methodName] Mapeando datos crudos de Stock a entidades...");
      final stockData = <String, List<StockItemEntity>>{};
      rawStockData.forEach((key, value) {
        if (value is List && key.endsWith('_stock')) {
          final categoryName = key.replaceAll('_stock', '');
          stockData[categoryName] =
              value.map((item) => StockItemModel.fromJson(item)).toList();
        }
      });
      debugPrint(
          "[$methodName] Mapeo de Stock completado. ${stockData.length} categorías.");

      debugPrint("[$methodName] Mapeando datos crudos de Clima a entidades...");
      final weatherData =
          rawWeatherData.map((item) => WeatherModel.fromJson(item)).toList();
      debugPrint(
          "[$methodName] Mapeo de Clima completado. ${weatherData.length} registros.");

      debugPrint("[$methodName] Retornando datos procesados.");
      return (stockData, weatherData);
    } catch (e, s) {
      debugPrint("[$methodName] ERROR: Excepción: $e\nStackTrace: $s");
      rethrow;
    }
  }

  @override
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo() async {
    final methodName = "$_className.getAllItemsInfo";
    debugPrint("[$methodName] Iniciando...");
    try {
      debugPrint(
          "[$methodName] Solicitando todos los items info del data source...");
      final itemsList = await itemInfoDataSource.getAllItemsInfo();
      debugPrint(
          "[$methodName] Recibidos ${itemsList.length} items info. Mapeando a un mapa por nombre.");

      final result = {for (var item in itemsList) item.name: item};
      debugPrint(
          "[$methodName] Mapeo completado. Retornando mapa de ${result.length} entradas.");
      return result;
    } catch (e, s) {
      debugPrint("[$methodName] ERROR: Excepción: $e\nStackTrace: $s");
      rethrow;
    }
  }
}
