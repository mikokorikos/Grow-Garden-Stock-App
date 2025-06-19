import '../entities/item_info_entity.dart';
import '../repositories/stock_repository.dart';

class GetAllItemsInfoUseCase {
  final StockRepository repository;
  GetAllItemsInfoUseCase(this.repository);
  Future<Map<String, ItemInfoEntity>> call() => repository.getAllItemsInfo();
}
