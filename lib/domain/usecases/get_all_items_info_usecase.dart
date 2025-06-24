import 'package:flutter/foundation.dart';
import '../entities/item_info_entity.dart';
import '../repositories/stock_repository.dart';

class GetAllItemsInfoUseCase {
  final StockRepository repository;
  final String _className = "GetAllItemsInfoUseCase";

  GetAllItemsInfoUseCase(this.repository);

  Future<Map<String, ItemInfoEntity>> call() async {
    final methodName = "$_className.call";
    debugPrint("[$methodName] Iniciando...");
    // No hay parámetros de entrada para loguear en este use case.

    try {
      final result = await repository.getAllItemsInfo();
      debugPrint("[$methodName] Finalizado. Resultado obtenido del repositorio: ${result.length} items.");
      return result;
    } catch (e, s) {
      debugPrint("[$methodName] Excepción al llamar al repositorio: $e\nStackTrace: $s");
      rethrow;
    }
  }
}
