// Archivo: lib/data/datasources/stock_rest_data_source.dart
import 'dart:async';
import 'dart:convert';
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
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.baseUrl + ApiConstants.stockEndpoint),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<dynamic>> getWeather() async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.baseUrl + ApiConstants.weatherEndpoint),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // La API de clima devuelve directamente la lista dentro de la clave 'weather'.
        return json.decode(response.body)['weather'];
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }
}
