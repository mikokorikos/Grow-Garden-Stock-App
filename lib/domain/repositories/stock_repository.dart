import '../entities/item_info_entity.dart';
import '../entities/stock_item_entity.dart';

abstract class StockRepository {
  Stream<Map<String, List<StockItemEntity>>> getStockUpdates();
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo();
}
