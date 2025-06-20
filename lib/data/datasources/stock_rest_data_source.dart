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

  StockRestDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getStock() async {
    final url = ApiConstants.baseUrl + ApiConstants.stockEndpoint;
    debugPrint("[DataSource] Haciendo petición GET a: $url");
    try {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        debugPrint("[DataSource] Stock recibido con éxito (status 200).");
        return json.decode(response.body);
      } else {
        debugPrint(
            "[DataSource] Error de servidor para Stock: ${response.statusCode}");
        throw ServerException();
      }
    } catch (e) {
      debugPrint("[DataSource] Excepción al obtener Stock: $e");
      throw ServerException();
    }
  }

  @override
  Future<List<dynamic>> getWeather() async {
    final url = ApiConstants.baseUrl + ApiConstants.weatherEndpoint;
    debugPrint("[DataSource] Haciendo petición GET a: $url");
    try {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        debugPrint("[DataSource] Clima recibido con éxito (status 200).");
        return json.decode(response.body)['weather'];
      } else {
        debugPrint(
            "[DataSource] Error de servidor para Clima: ${response.statusCode}");
        throw ServerException();
      }
    } catch (e) {
      debugPrint("[DataSource] Excepción al obtener Clima: $e");
      throw ServerException();
    }
  }
}
