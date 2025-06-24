// Archivo: lib/domain/usecases/get_stock_and_weather_usecase.dart
import 'package:flutter/foundation.dart';
import '../entities/stock_item_entity.dart';
import '../entities/weather_entity.dart';
import '../repositories/stock_repository.dart';

/// Caso de uso que encapsula la acción de "obtener el stock y el clima".
class GetStockAndWeatherUseCase {
  final StockRepository repository;
  final String _className = "GetStockAndWeatherUseCase";

  GetStockAndWeatherUseCase(this.repository);

  /// El método `call` permite que esta clase se trate como una función.
  Future<(Map<String, List<StockItemEntity>>, List<WeatherEntity>)> call() async {
    final methodName = "$_className.call";
    debugPrint("[$methodName] Iniciando...");
    // No hay parámetros de entrada para loguear en este use case.

    try {
      final result = await repository.getStockAndWeather();
      debugPrint("[$methodName] Finalizado. Resultado obtenido del repositorio: Stock con ${result.$1.keys.length} categorías, Clima con ${result.$2.length} registros.");
      return result;
    } catch (e, s) {
      debugPrint("[$methodName] Excepción al llamar al repositorio: $e\nStackTrace: $s");
      rethrow;
    }
  }
}
