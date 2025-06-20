// Archivo: lib/domain/usecases/get_stock_and_weather_usecase.dart
import '../entities/stock_item_entity.dart';
import '../entities/weather_entity.dart';
import '../repositories/stock_repository.dart';

/// Caso de uso que encapsula la acción de "obtener el stock y el clima".
class GetStockAndWeatherUseCase {
  final StockRepository repository;

  GetStockAndWeatherUseCase(this.repository);

  /// El método `call` permite que esta clase se trate como una función.
  Future<(Map<String, List<StockItemEntity>>, List<WeatherEntity>)> call() {
    return repository.getStockAndWeather();
  }
}
