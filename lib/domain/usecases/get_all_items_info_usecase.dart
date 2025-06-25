import 'package:flutter/foundation.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/repositories/item_info_repository.dart';

class GetAllItemsInfoUseCase {
  final ItemInfoRepository repository; // <-- Cambio aquí
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
          "[$methodName] Excepción al llamar al repositorio: $e\nStackTrace: $s");
      rethrow;
    }
  }
}
