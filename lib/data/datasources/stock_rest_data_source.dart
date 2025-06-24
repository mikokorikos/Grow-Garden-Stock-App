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
    final url = ApiConstants.baseUrl + ApiConstants.stockEndpoint;
    debugPrint("[$methodName] Iniciando petición GET a: $url");

    try {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      debugPrint(
          "[$methodName] Respuesta recibida con statusCode: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("[$methodName] Petición exitosa. Decodificando JSON.");
        return json.decode(response.body);
      } else {
        debugPrint(
            "[$methodName] ERROR: Respuesta no fue 200. Body: ${response.body}");
        throw ServerException();
      }
    } on TimeoutException catch (e, s) {
      debugPrint("[$methodName] ERROR: TimeoutException: $e\nStackTrace: $s");
      throw ServerException();
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: Excepción inesperada: $e\nStackTrace: $s");
      throw ServerException();
    }
  }

  @override
  Future<List<dynamic>> getWeather() async {
    final methodName = "$_className.getWeather";
    final url = ApiConstants.baseUrl + ApiConstants.weatherEndpoint;
    debugPrint("[$methodName] Iniciando petición GET a: $url");

    try {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      debugPrint(
          "[$methodName] Respuesta recibida con statusCode: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("[$methodName] Petición exitosa. Decodificando JSON.");
        final decodedBody = json.decode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('weather')) {
          debugPrint(
              "[$methodName] Llave 'weather' encontrada. Retornando lista.");
          return decodedBody['weather'];
        } else {
          debugPrint(
              "[$methodName] ERROR: Respuesta de Clima inesperada. No contiene 'weather'. Body: ${response.body}");
          throw ServerException();
        }
      } else {
        debugPrint(
            "[$methodName] ERROR: Respuesta no fue 200. Body: ${response.body}");
        throw ServerException();
      }
    } on TimeoutException catch (e, s) {
      debugPrint("[$methodName] ERROR: TimeoutException: $e\nStackTrace: $s");
      throw ServerException();
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: Excepción inesperada: $e\nStackTrace: $s");
      throw ServerException();
    }
  }
}
