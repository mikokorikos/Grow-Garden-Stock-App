// Archivo: lib/data/datasources/item_info_rest_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/api/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/item_info_model.dart';

abstract class ItemInfoRestDataSource {
  Future<List<ItemInfoModel>> getAllItemsInfo();
}

class ItemInfoRestDataSourceImpl implements ItemInfoRestDataSource {
  final http.Client client;
  final String _className = "ItemInfoRestDataSourceImpl";

  ItemInfoRestDataSourceImpl({required this.client});

  @override
  Future<List<ItemInfoModel>> getAllItemsInfo() async {
    final methodName = "$_className.getAllItemsInfo";
    final url = ApiConstants.baseUrl + ApiConstants.itemInfoEndpoint;
    debugPrint("[$methodName] Iniciando petición GET a: $url");

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint(
          "[$methodName] Respuesta recibida con statusCode: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        debugPrint(
            "[$methodName] Petición exitosa. Decodificando y mapeando ${jsonList.length} items.");
        final result =
            jsonList.map((json) => ItemInfoModel.fromJson(json)).toList();
        debugPrint(
            "[$methodName] Mapeo completado. Retornando lista de modelos.");
        return result;
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
          "[$methodName] ERROR: Excepción no controlada: $e\nStackTrace: $s");
      throw ServerException();
    }
  }
}
