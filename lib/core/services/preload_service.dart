import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:grow_garden_tracker/data/repositories/item_info_repository_impl.dart';

class PreloadService {
  final ItemInfoRepositoryImpl itemInfoRepository;

  PreloadService({required this.itemInfoRepository});

  // La función de progreso ahora nos dará un valor de 0.0 a 1.0 y un mensaje de estado.
  Future<void> startPreloading(
      Function(double progress, String message) onProgress) async {
    try {
      // --- PASO 1: Descargar la información de los items ---
      onProgress(0.1, "Plantando semillas de datos...");
      // Forzamos una actualización desde la red para el pre-cache
      final allItemsMap =
          await itemInfoRepository.getAllItemsInfo(forceRefresh: true);
      final allItems = allItemsMap.values.toList();
      onProgress(0.4, "Catálogo de items cosechado...");
      await Future.delayed(
          const Duration(milliseconds: 500)); // Pequeña pausa visual

      // --- PASO 2: Descargar y guardar en caché todas las imágenes ---
      onProgress(0.5, "Regando las imágenes...");
      final cacheManager = DefaultCacheManager();
      int totalImages = allItems.length;
      int cachedImages = 0;

      for (final item in allItems) {
        if (item.image.isNotEmpty) {
          try {
            // Esta línea descarga la imagen si no está en caché.
            await cacheManager.downloadFile(item.image, authHeaders: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
            });
          } catch (e) {
            debugPrint(
                "No se pudo cachear la imagen: ${item.image}. Error: $e");
          }
        }
        cachedImages++;
        // Actualizamos el progreso basado en las imágenes cacheadas
        onProgress(0.5 + (0.4 * (cachedImages / totalImages)),
            "Cosechando imágenes... ($cachedImages/$totalImages)");
      }

      // --- PASO 3: Finalización ---
      onProgress(0.95, "¡El jardín está casi listo!");
      await Future.delayed(const Duration(milliseconds: 500));
      onProgress(1.0, "¡Bienvenido!");
    } catch (e) {
      debugPrint("Error durante la pre-carga: $e");
      // Manejar el error, quizás mostrando un mensaje y un botón para reintentar.
      // Por ahora, simplemente terminamos el proceso para que la app no se quede bloqueada.
      onProgress(1.0, "Error al cargar. Reintenta más tarde.");
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
