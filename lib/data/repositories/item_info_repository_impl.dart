import 'package:grow_garden_tracker/data/datasources/item_info_rest_data_source.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/repositories/item_info_repository.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grow_garden_tracker/data/models/item_info_model.dart';

class ItemInfoRepositoryImpl implements ItemInfoRepository {
  final ItemInfoRestDataSource itemInfoDataSource;
  final String _className = "ItemInfoRepositoryImpl";

  static const String _boxName = 'item_info_cache';

  ItemInfoRepositoryImpl({
    required this.itemInfoDataSource,
  });

  Future<bool> isCacheAvailable() async {
    final box = await Hive.openBox(_boxName);
    return box.isNotEmpty;
  }

  @override
  Future<Map<String, ItemInfoEntity>> getAllItemsInfo(
      {bool forceRefresh = false}) async {
    final methodName = "$_className.getAllItemsInfo";
    logD("[$methodName] Iniciando... forceRefresh: $forceRefresh");

    final box = await Hive.openBox(_boxName);

    if (!forceRefresh && box.isNotEmpty) {
      logI(
          "[$methodName] Datos encontrados en caché local. Cargando desde Hive.");
      final Map<String, ItemInfoEntity> cachedItems = {};
      for (var key in box.keys) {
        final itemJson = box.get(key) as Map<dynamic, dynamic>;
        cachedItems[key as String] =
            ItemInfoModel.fromJson(Map<String, dynamic>.from(itemJson));
      }
      return cachedItems;
    }

    logI(
        "[$methodName] No hay caché o se forzó la actualización. Obteniendo datos de la API...");
    try {
      final itemsList = await itemInfoDataSource.getAllItemsInfo();
      final Map<String, ItemInfoEntity> result = {
        for (var item in itemsList) item.name: item
      };

      logI(
          "[$methodName] Información de items obtenida. Guardando en caché...");

      await box.clear();
      result.forEach((key, value) {
        final itemModel = value as ItemInfoModel;
        box.put(key, {
          'display_name': itemModel.name,
          'rarity': itemModel.rarity,
          'icon': itemModel.image,
          'price': itemModel.price,
          'currency': itemModel.currency,
          'description': itemModel.description,
        });
      });
      logI("[$methodName] ${result.length} items guardados en caché local.");

      return result;
    } on AppException catch (e) {
      logW("[$methodName] AppException capturada: ${e.message}");
      rethrow;
    } catch (e, s) {
      logE("[$methodName] ERROR no esperado", error: e, stackTrace: s);
      throw ServerException(
          "Error inesperado al obtener información de items: ${e.toString()}");
    }
  }
}
