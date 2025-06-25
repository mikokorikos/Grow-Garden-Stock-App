import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/logger.dart'; // Importar logger

abstract class StockRestDataSource {
  Future<Map<String, dynamic>> getStock();
  Future<List<dynamic>> getWeather();
}

class StockRestDataSourceImpl implements StockRestDataSource {
  final http.Client client;
  final String _className = "StockRestDataSourceImpl";

  // --- CABECERAS MEJORADAS ---
  // Se define una cabecera estándar para todas las peticiones de esta clase.
  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
  };

  StockRestDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getStock() async {
    final methodName = "$_className.getStock";
    final url = ApiConstants.baseUrl + ApiConstants.stockEndpoint;
    logD("[$methodName] Iniciando petición GET a: $url");

    try {
      // Se añade la cabecera a la petición y se aumenta el timeout a 30 segundos
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));

      logD("[$methodName] Respuesta recibida con statusCode: ${response.statusCode}");
      if (response.statusCode == 200) {
        logI("[$methodName] Stock recibido con éxito.");
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        logW("[$methodName] Error del cliente (4xx) para Stock. StatusCode: ${response.statusCode}, Body: ${response.body}");
        throw ServerException("Error del cliente al obtener stock: ${response.statusCode}");
      } else {
        logE("[$methodName] Error del servidor (5xx o inesperado) para Stock. StatusCode: ${response.statusCode}, Body: ${response.body}");
        throw ServerException("Error del servidor al obtener stock: ${response.statusCode}");
      }
    } on TimeoutException catch (e, s) {
      logE("[$methodName] TimeoutException al obtener Stock", error: e, stackTrace: s);
      throw NetworkException("Timeout al obtener stock. Verifica tu conexión.");
    } on http.ClientException catch (e,s) {
      logE("[$methodName] ClientException (probablemente de red) al obtener Stock", error: e, stackTrace: s);
      throw NetworkException("Error de conexión al obtener stock: ${e.message}");
    } on FormatException catch (e, s) {
      logE("[$methodName] FormatException (error de parseo JSON) al obtener Stock", error: e, stackTrace: s);
      throw ParsingException("Error al procesar la respuesta del stock.");
    } catch (e, s) {
      logE("[$methodName] Excepción no controlada al obtener Stock", error: e, stackTrace: s);
      throw ServerException("Ocurrió un error inesperado al obtener stock: ${e.toString()}");
    }
  }

  @override
  Future<List<dynamic>> getWeather() async {
    final methodName = "$_className.getWeather";
    final url = ApiConstants.baseUrl + ApiConstants.weatherEndpoint;
    logD("[$methodName] Haciendo petición GET a: $url");

    try {
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));

      logD("[$methodName] Respuesta recibida con statusCode: ${response.statusCode}");
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('weather') && decodedBody['weather'] is List) {
          logI("[$methodName] Clima recibido con éxito.");
          return decodedBody['weather'] as List<dynamic>;
        } else {
          logW("[$methodName] Respuesta de Clima inesperada. No contiene 'weather' o no es una lista. Body: ${response.body}");
          throw ParsingException("Formato de respuesta de clima inesperado.");
        }
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        logW("[$methodName] Error del cliente (4xx) para Clima. StatusCode: ${response.statusCode}, Body: ${response.body}");
        throw ServerException("Error del cliente al obtener clima: ${response.statusCode}");
      } else {
        logE("[$methodName] Error del servidor (5xx o inesperado) para Clima. StatusCode: ${response.statusCode}, Body: ${response.body}");
        throw ServerException("Error del servidor al obtener clima: ${response.statusCode}");
      }
    } on TimeoutException catch (e, s) {
      logE("[$methodName] TimeoutException al obtener Clima", error: e, stackTrace: s);
      throw NetworkException("Timeout al obtener clima. Verifica tu conexión.");
    } on http.ClientException catch (e,s) {
      logE("[$methodName] ClientException (probablemente de red) al obtener Clima", error: e, stackTrace: s);
      throw NetworkException("Error de conexión al obtener clima: ${e.message}");
    } on FormatException catch (e, s) {
      logE("[$methodName] FormatException (error de parseo JSON) al obtener Clima", error: e, stackTrace: s);
      throw ParsingException("Error al procesar la respuesta del clima.");
    } catch (e, s) {
      logE("[$methodName] Excepción no controlada al obtener Clima", error: e, stackTrace: s);
      throw ServerException("Ocurrió un error inesperado al obtener clima: ${e.toString()}");
    }
  }
}
