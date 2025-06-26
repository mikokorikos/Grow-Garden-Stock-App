import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:grow_garden_tracker/data/repositories/item_info_repository_impl.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';

class PreloadService {
  final ItemInfoRepositoryImpl itemInfoRepository;

  PreloadService({required this.itemInfoRepository});

  Future<void> startPreloading(
      Function(double progress, String message) onProgress) async {
    try {
      Map<String, ItemInfoEntity> allItemsMap;

      final bool cacheExists = await itemInfoRepository.isCacheAvailable();

      if (cacheExists) {
        await onProgress(0.4, "Cargando datos desde el caché...");
        allItemsMap = await itemInfoRepository.getAllItemsInfo();
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        await onProgress(0.1, "Plantando semillas de datos...");
        allItemsMap =
            await itemInfoRepository.getAllItemsInfo(forceRefresh: true);
        await onProgress(0.4, "Catálogo de items cosechado...");
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // La lógica de caché de imágenes (originalmente comentada para pruebas) se puede reactivar aquí si se desea.
      // Por ahora, se mantiene desactivada para agilizar, pero la lógica de datos ya es eficiente.
      debugPrint("[PreloadService] El caché de imágenes está desactivado.");

      await onProgress(1.0, "¡El jardín está listo!");
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      debugPrint("Error durante la pre-carga: $e");
      await onProgress(1.0, "Error al preparar el jardín...");
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}
