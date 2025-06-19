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
    final response = await client.get(
      Uri.parse(ApiConstants.itemInfoBaseUrl + ApiConstants.itemInfoEndpoint),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ItemInfoModel.fromJson(json)).toList();
    } else {
      throw ServerException();
    }
  }
}
