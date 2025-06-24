// Archivo: lib/domain/usecases/get_all_items_info_usecase.dart
import 'package:flutter/foundation.dart';
import '../entities/item_info_entity.dart';
import '../repositories/stock_repository.dart';

class GetAllItemsInfoUseCase {
  final StockRepository repository;
  final String _className = "GetAllItemsInfoUseCase";

  GetAllItemsInfoUseCase(this.repository);

  Future<Map<String, ItemInfoEntity>> call() async {
    final methodName = "$_className.call";
    debugPrint("[$methodName] Ejecutando caso de uso...");
    try {
      final result = await repository.getAllItemsInfo();
      debugPrint(
          "[$methodName] Caso de uso completado. Retornando ${result.length} items.");
      return result;
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: Excepción al llamar al repositorio: $e\nStackTrace: $s");
      rethrow;
    }
  }
}
