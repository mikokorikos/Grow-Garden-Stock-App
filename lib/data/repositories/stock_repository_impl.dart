import 'package:grow_garden_tracker/data/datasources/stock_rest_data_source.dart';
import 'package:grow_garden_tracker/domain/entities/stock_item_entity.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart'; // Necesario
import 'package:grow_garden_tracker/core/utils/logger.dart'; // Importar logger
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
    logD("[$methodName] Iniciando...");

    try {
      logD("[$methodName] Solicitando stock y clima a los data sources en paralelo...");
      final results = await Future.wait([
        stockDataSource.getStock(),
        stockDataSource.getWeather(),
      ]);
      logD("[$methodName] Datos recibidos de los data sources.");

      final rawStockData = results[0] as Map<String, dynamic>;
      final rawWeatherData = results[1] as List<dynamic>;

      logD("[$methodName] Mapeando datos crudos de Stock a entidades...");
      final stockData = <String, List<StockItemEntity>>{};
      final knownCategories = ["seed", "gear", "egg", "cosmetic", "eventshop"];

      for (final category in knownCategories) {
        final apiKey = "${category}_stock";
        if (rawStockData.containsKey(apiKey) && rawStockData[apiKey] is List) {
          final itemsList = rawStockData[apiKey] as List;
          if (itemsList.isNotEmpty) {
            try { // Añadido try-catch para el parseo de cada categoría
              stockData[category] = itemsList
                  .map((item) => StockItemModel.fromJson(item as Map<String,dynamic>)) // Cast explícito
                  .toList();
              logD("[$methodName] Parseados ${itemsList.length} items para la categoría '$category'.");
            } catch (e, s) {
              logE("[$methodName] Error al parsear items para la categoría '$category'", error: e, stackTrace: s);
              // Decidir si continuar o lanzar una excepción. Por ahora, continuamos y esa categoría podría quedar vacía.
            }
          }
        } else {
          logW("[$methodName] No se encontraron datos para la clave de API '$apiKey' o no es una lista.");
        }
      }

      logD("[$methodName] Mapeando datos crudos de Clima a entidades...");
      final List<WeatherEntity> weatherData = [];
      for (var item in rawWeatherData) {
        try { // Añadido try-catch para el parseo de cada item de clima
          weatherData.add(WeatherModel.fromJson(item as Map<String,dynamic>)); // Cast explícito
        } catch (e, s) {
          logE("[$methodName] Error al parsear item de clima", error: e, stackTrace: s);
          // Continuamos, omitiendo el item de clima defectuoso
        }
      }
      logD("[$methodName] Mapeo de Clima completado. ${weatherData.length} registros.");

      logI("[$methodName] Retornando datos procesados. Categorías con stock: ${stockData.keys.toList()}");
      return (stockData, weatherData);
    } on AppException catch(e) {
      logW("[$methodName] AppException capturada: ${e.message}");
      rethrow;
    } on FormatException catch (e, s) {
      logE("[$methodName] ERROR de formato durante el mapeo (inesperado aquí si los try-catch internos funcionan)", error: e, stackTrace: s);
      throw ParsingException("Error al procesar los datos recibidos del stock o clima: ${e.message}");
    }
    catch (e, s) {
      logE("[$methodName] ERROR no esperado", error: e, stackTrace: s);
      throw ServerException("Error inesperado al obtener stock y clima: ${e.toString()}");
    }
  }
}
