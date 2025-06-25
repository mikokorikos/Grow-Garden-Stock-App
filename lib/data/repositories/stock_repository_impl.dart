import 'package:flutter/foundation.dart';
import 'package:grow_garden_tracker/data/datasources/stock_rest_data_source.dart';
import 'package:grow_garden_tracker/domain/entities/stock_item_entity.dart';
import 'package:grow_garden_tracker/domain/entities/weather_entity.dart';
import 'package:grow_garden_tracker/domain/repositories/stock_repository.dart';
import 'package:grow_garden_tracker/data/models/stock_item_model.dart';
import 'package:grow_garden_tracker/data/models/weather_model.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRestDataSource stockDataSource;
  final String _className = "StockRepositoryImpl";

  StockRepositoryImpl({
    required this.stockDataSource,
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

      // --- LÓGICA DE PARSEO MEJORADA ---
      debugPrint("[$methodName] Mapeando datos crudos de Stock a entidades...");
      final stockData = <String, List<StockItemEntity>>{};
      final knownCategories = ["seed", "gear", "egg", "cosmetic", "eventshop"];

      for (final category in knownCategories) {
        final apiKey = "${category}_stock";
        if (rawStockData.containsKey(apiKey) && rawStockData[apiKey] is List) {
          final itemsList = rawStockData[apiKey] as List;
          if (itemsList.isNotEmpty) {
            stockData[category] =
                itemsList.map((item) => StockItemModel.fromJson(item)).toList();
            debugPrint(
                "[$methodName] CORRECTO: Parseados ${itemsList.length} items para la categoría '$category'.");
          }
        } else {
          debugPrint(
              "[$methodName] ADVERTENCIA: No se encontraron datos para la clave de API '$apiKey'.");
        }
      }

      debugPrint("[$methodName] Mapeando datos crudos de Clima a entidades...");
      final weatherData =
          rawWeatherData.map((item) => WeatherModel.fromJson(item)).toList();
      debugPrint(
          "[$methodName] Mapeo de Clima completado. ${weatherData.length} registros.");

      debugPrint(
          "[$methodName] Retornando datos procesados. Categorías con stock: ${stockData.keys.toList()}");
      return (stockData, weatherData);
    } catch (e, s) {
      debugPrint("[$methodName] ERROR: Excepción: $e\nStackTrace: $s");
      rethrow;
    }
  }
}
