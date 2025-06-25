import 'package:flutter/foundation.dart';
import 'package:grow_garden_tracker/data/datasources/item_info_rest_data_source.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/repositories/item_info_repository.dart';

class ItemInfoRepositoryImpl implements ItemInfoRepository {
  final ItemInfoRestDataSource itemInfoDataSource;

  ItemInfoRepositoryImpl({
    required this.itemInfoDataSource,
  });

  @override
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo() async {
    try {
      final itemsList = await itemInfoDataSource.getAllItemsInfo();
      final result = {for (var item in itemsList) item.name: item};
      return result;
    } catch (e) {
      debugPrint('[ItemInfoRepositoryImpl] ERROR: $e');
      rethrow;
    }
  }
}
