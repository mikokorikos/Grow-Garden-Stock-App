import 'dart:ui'; // Para ImageFilter
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import '../../core/theme/app_theme.dart';
import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../widgets/stock_item_card.dart'; // Ya está estilizada

class CategoryTabScreen extends StatelessWidget {
  final List<StockItemEntity> items;
  final Map<String, ItemInfoEntity> itemDetails;

  const CategoryTabScreen({
    super.key,
    required this.items,
    required this.itemDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
          child: Text(
        "No hay stock para esta categoría.",
        style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.darkTextColor.withOpacity(0.7)),
      ));
    }

    // El GridView ya usa StockItemCard, que ha sido estilizado con Glassmorphism.
    // Solo necesitamos asegurar que el padding y espaciado sean adecuados.
    return GridView.builder(
      padding: const EdgeInsets.all(16.0), // Padding general para el GridView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14.0, // Espaciado ligeramente menor
          mainAxisSpacing: 14.0,  // Espaciado ligeramente menor
          childAspectRatio: 0.78), // Ajustar aspect ratio si es necesario por el nuevo padding interno de StockItemCard
      itemCount: items.length,
      itemBuilder: (context, index) {
        final stockItem = items[index];
        final info = itemDetails[stockItem.displayName];
        return StockItemCard(
          stockItem: stockItem,
          itemInfo: info,
          onTap: () {
            HapticFeedback.lightImpact();
            _showItemDetailDialog(context, stockItem: stockItem, itemInfo: info);
          },
        );
      },
    );
  }

  void _showItemDetailDialog(BuildContext context,
      {required StockItemEntity stockItem, ItemInfoEntity? itemInfo}) {
    showCupertinoModalPopup(
      context: context,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Aplicar blur al fondo
      builder: (ctx) => CupertinoPopupSurface(
        // El PopupSurface ya tiene un efecto de material y sombra estilo iOS.
        // Podemos personalizarlo más si es necesario, pero por defecto es bastante bueno.
        // Para un efecto glassmorphism más directo aquí, necesitaríamos un Container con BackdropFilter.
        // Por simplicidad y coherencia con popups de iOS, mantenemos CupertinoPopupSurface.
        // Si se desea glassmorphism aquí:
        // return BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY:10), child: Dialog(...))
        // Pero CupertinoPopupSurface es más idiomático.
        child: Container( // Contenedor para el contenido del diálogo
            width: MediaQuery.of(context).size.width * 0.9, // Ancho del diálogo
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20), // Padding interno
            decoration: BoxDecoration(
              // No se necesita color aquí si CupertinoPopupSurface lo maneja,
              // o si se quiere un color específico:
              // color: AppTheme.lightScaffoldBackgroundColor.withOpacity(0.95),
              // borderRadius: BorderRadius.circular(14), // iOS-like rounded corners
            ),
            child: SingleChildScrollView( // Para contenido que pueda exceder la altura
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar elementos horizontalmente
                children: [
                  Text(
                    stockItem.displayName,
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineStyle.copyWith(fontSize: 22)
                  ),
                  const SizedBox(height: 18),
                  CachedNetworkImage(
                    imageUrl: stockItem.iconUrl,
                    height: 120, // Imagen un poco más grande
                    fit: BoxFit.contain,
                     placeholder: (context, url) => const CupertinoActivityIndicator(radius: 15),
                    errorWidget: (context, error, stackTrace) =>
                        const Icon(CupertinoIcons.photo_fill, size: 80, color: CupertinoColors.systemGrey3),
                  ),
                  if (itemInfo?.description.isNotEmpty ?? false) ...[
                    const SizedBox(height: 18),
                    Text(
                      itemInfo!.description,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyTextStyle.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.darkTextColor.withOpacity(0.75),
                          fontSize: 14.5),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (itemInfo != null) ...[
                    _buildInfoRow('Rareza:', itemInfo.rarity, context),
                    if (itemInfo.price != "0" && itemInfo.price.isNotEmpty)
                      _buildInfoRow('Precio:', '${itemInfo.price} ${itemInfo.currency}', context),
                  ],
                  const SizedBox(height: 28),
                  CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12), // Padding del botón
                      child: Text('Cerrar', style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.lightTextColor, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(ctx).pop();
                      }),
                ],
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    if (value.trim().isEmpty ||
        value.trim() == "N/A" ||
        value.toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.bodyTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkTextColor.withOpacity(0.85),
                  fontSize: 15.5)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: AppTheme.bodyTextStyle.copyWith(fontSize: 15.5)),
          ),
        ],
      ),
    );
  }
}
