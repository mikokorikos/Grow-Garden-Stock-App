import '../entities/stock_item_entity.dart';
import '../repositories/stock_repository.dart';

class ListenToStockUpdatesUseCase {
  final StockRepository repository;
  ListenToStockUpdatesUseCase(this.repository);
  Stream<Map<String, List<StockItemEntity>>> call() =>
      repository.getStockUpdates();
}
