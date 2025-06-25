import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/api/api_constants.dart';
import '../../core/error/exceptions.dart';

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
    debugPrint("[$methodName] Iniciando petición GET a: $url");

    try {
      // Se añade la cabecera a la petición y se aumenta el timeout a 30 segundos
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint("[$methodName] Stock recibido con éxito (status 200).");
        return json.decode(response.body);
      } else {
        debugPrint(
            "[$methodName] Error de servidor para Stock: ${response.statusCode}. Respuesta: ${response.body}");
        throw ServerException();
      }
    } on TimeoutException catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: TimeoutException al obtener Stock: $e\nStackTrace: $s");
      throw ServerException();
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: Excepción al obtener Stock: $e\nStackTrace: $s");
      throw ServerException();
    }
  }

  @override
  Future<List<dynamic>> getWeather() async {
    final methodName = "$_className.getWeather";
    final url = ApiConstants.baseUrl + ApiConstants.weatherEndpoint;
    debugPrint("[$methodName] Haciendo petición GET a: $url");

    try {
      // Se añade la cabecera a la petición y se aumenta el timeout a 30 segundos
      final response = await client
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('weather')) {
          return decodedBody['weather'];
        } else {
          debugPrint(
              "[$methodName] Respuesta de Clima inesperada. No contiene 'weather'. Body: ${response.body}");
          throw ServerException();
        }
      } else {
        debugPrint(
            "[$methodName] Error de servidor para Clima: ${response.statusCode}. Respuesta: ${response.body}");
        throw ServerException();
      }
    } on TimeoutException catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: TimeoutException al obtener Clima: $e\nStackTrace: $s");
      throw ServerException();
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: Excepción al obtener Clima: $e\nStackTrace: $s");
      throw ServerException();
    }
  }
}
