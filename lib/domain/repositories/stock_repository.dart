// Archivo: lib/domain/repositories/stock_repository.dart
import '../entities/item_info_entity.dart';
import '../entities/stock_item_entity.dart';
import '../entities/weather_entity.dart';

abstract class StockRepository {
  /// Obtiene los datos de stock y clima en una sola llamada a la API REST.
  /// Devuelve un tuple con el mapa del stock y la lista de climas.
  Future<(Map<String, List<StockItemEntity>>, List<WeatherEntity>)>
      getStockAndWeather();

  /// Obtiene la información detallada de todos los artículos de la API REST.
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo();
}
