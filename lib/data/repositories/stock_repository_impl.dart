import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/item_info_rest_data_source.dart';
import '../datasources/stock_websocket_data_source.dart';

class StockRepositoryImpl implements StockRepository {
  final StockWebSocketDataSource webSocketDataSource;
  final ItemInfoRestDataSource restDataSource;

  StockRepositoryImpl({
    required this.webSocketDataSource,
    required this.restDataSource,
  });

  @override
  Stream<Map<String, List<StockItemEntity>>> getStockUpdates() {
    // El modelo es compatible con la entidad, por lo que podemos devolverlo directamente.
    return webSocketDataSource.getStockUpdates();
  }

  @override
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo() async {
    final itemsList = await restDataSource.getAllItemsInfo();
    // Convertimos la lista a un mapa para un acceso O(1) en la UI, usando el nombre como clave.
    return {for (var item in itemsList) item.name: item};
  }
}
