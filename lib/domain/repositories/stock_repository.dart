import 'package:grow_garden_tracker/domain/entities/stock_item_entity.dart';
import 'package:grow_garden_tracker/domain/entities/weather_entity.dart';

/// Un contrato que define cómo obtener los datos de stock y clima.
abstract class StockRepository {
  /// Obtiene los datos de stock y clima en una sola llamada a la API REST.
  Future<(Map<String, List<StockItemEntity>>, List<WeatherEntity>)>
      getStockAndWeather();
}
