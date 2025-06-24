// Archivo: lib/domain/usecases/get_stock_and_weather_usecase.dart
import 'package:flutter/foundation.dart';
import '../entities/stock_item_entity.dart';
import '../entities/weather_entity.dart';
import '../repositories/stock_repository.dart';

class GetStockAndWeatherUseCase {
  final StockRepository repository;
  final String _className = "GetStockAndWeatherUseCase";

  GetStockAndWeatherUseCase(this.repository);

  Future<(Map<String, List<StockItemEntity>>, List<WeatherEntity>)>
      call() async {
    final methodName = "$_className.call";
    debugPrint("[$methodName] Ejecutando caso de uso...");
    try {
      final result = await repository.getStockAndWeather();
      debugPrint(
          "[$methodName] Caso de uso completado. Retornando datos del repositorio.");
      return result;
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: Excepción al llamar al repositorio: $e\nStackTrace: $s");
      rethrow;
    }
  }
}
