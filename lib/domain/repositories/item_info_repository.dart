import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';

abstract class ItemInfoRepository {
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo();
}
