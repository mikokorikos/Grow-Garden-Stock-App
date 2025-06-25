import 'package:grow_garden_tracker/data/datasources/item_info_rest_data_source.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/repositories/item_info_repository.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart'; // Necesario para AppException
import 'package:grow_garden_tracker/core/utils/logger.dart'; // Importar logger

class ItemInfoRepositoryImpl implements ItemInfoRepository {
  final ItemInfoRestDataSource itemInfoDataSource;
  final String _className = "ItemInfoRepositoryImpl"; // Para consistencia en logging

  ItemInfoRepositoryImpl({
    required this.itemInfoDataSource,
  });

  @override
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo() async {
    final methodName = "$_className.getAllItemsInfo"; // Usar _className
    logD("[$methodName] Iniciando...");
    try {
      final itemsList = await itemInfoDataSource.getAllItemsInfo();
      final Map<String, ItemInfoEntity> result = {
        for (var item in itemsList) item.name: item
      };
      logI("[$methodName] Información de items obtenida y mapeada exitosamente. Total: ${result.length} items.");
      return result;
    } on AppException catch(e) {
      logW("[$methodName] AppException capturada: ${e.message}");
      rethrow;
    } catch (e, s) {
      logE("[$methodName] ERROR no esperado", error: e, stackTrace: s);
      throw ServerException("Error inesperado al obtener información de items: ${e.toString()}");
    }
  }
}
