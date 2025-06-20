// Archivo: lib/data/repositories/stock_repository_impl.dart
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

  StockRepositoryImpl({
    required this.stockDataSource,
    required this.itemInfoDataSource,
  });

  @override
  Future<(Map<String, List<StockItemEntity>>, List<WeatherEntity>)>
      getStockAndWeather() async {
    // Hacemos las dos llamadas a la API en paralelo para optimizar el tiempo.
    final results = await Future.wait([
      stockDataSource.getStock(),
      stockDataSource.getWeather(),
    ]);

    final rawStockData = results[0] as Map<String, dynamic>;
    final rawWeatherData = results[1] as List<dynamic>;

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

    return (stockData, weatherData);
  }

  @override
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo() async {
    final itemsList = await itemInfoDataSource.getAllItemsInfo();
    return {for (var item in itemsList) item.name: item};
  }
}
