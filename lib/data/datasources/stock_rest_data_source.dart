// Archivo: lib/data/datasources/stock_rest_data_source.dart
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

  StockRestDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getStock() async {
    final methodName = "$_className.getStock";
    debugPrint("[$methodName] Iniciando...");

    final url = ApiConstants.baseUrl + ApiConstants.stockEndpoint;
    debugPrint("[$methodName] Haciendo petición GET a: $url");

    try {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        debugPrint("[$methodName] Stock recibido con éxito (status 200).");
        // debugPrint("[$methodName] Respuesta Stock: ${response.body}"); // Descomentar para ver el cuerpo completo
        return json.decode(response.body);
      } else {
        debugPrint("[$methodName] Error de servidor para Stock: ${response.statusCode}. Respuesta: ${response.body}");
        throw ServerException();
      }
    } on TimeoutException catch (e, s) {
      debugPrint("[$methodName] TimeoutException al obtener Stock: $e\nStackTrace: $s");
      throw ServerException();
    } catch (e, s) {
      debugPrint("[$methodName] Excepción al obtener Stock: $e\nStackTrace: $s");
      throw ServerException();
    }
  }

  @override
  Future<List<dynamic>> getWeather() async {
    final methodName = "$_className.getWeather";
    debugPrint("[$methodName] Iniciando...");

    final url = ApiConstants.baseUrl + ApiConstants.weatherEndpoint;
    debugPrint("[$methodName] Haciendo petición GET a: $url");

    try {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        debugPrint("[$methodName] Clima recibido con éxito (status 200).");
        final decodedBody = json.decode(response.body);
        // debugPrint("[$methodName] Respuesta Clima: ${response.body}"); // Descomentar para ver el cuerpo completo
        if (decodedBody is Map && decodedBody.containsKey('weather')) {
          return decodedBody['weather'];
        } else {
          debugPrint("[$methodName] Respuesta de Clima inesperada. No contiene 'weather'. Body: ${response.body}");
          throw ServerException(); // O un tipo de excepción más específico
        }
      } else {
        debugPrint("[$methodName] Error de servidor para Clima: ${response.statusCode}. Respuesta: ${response.body}");
        throw ServerException();
      }
    } on TimeoutException catch (e, s) {
      debugPrint("[$methodName] TimeoutException al obtener Clima: $e\nStackTrace: $s");
      throw ServerException();
    } catch (e, s) {
      debugPrint("[$methodName] Excepción al obtener Clima: $e\nStackTrace: $s");
      throw ServerException();
    }
  }
}
