// Archivo: lib/data/datasources/item_info_rest_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/item_info_model.dart';

abstract class ItemInfoRestDataSource {
  Future<List<ItemInfoModel>> getAllItemsInfo();
}

class ItemInfoRestDataSourceImpl implements ItemInfoRestDataSource {
  final http.Client client;

  ItemInfoRestDataSourceImpl({required this.client});

  @override
  Future<List<ItemInfoModel>> getAllItemsInfo() async {
    try {
      // CORRECCIÓN: Se usa 'ApiConstants.baseUrl' en lugar de 'itemInfoBaseUrl'.
      final response = await client.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.itemInfoEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ItemInfoModel.fromJson(json)).toList();
      } else {
        throw ServerException();
      }
    } on TimeoutException {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }
}
