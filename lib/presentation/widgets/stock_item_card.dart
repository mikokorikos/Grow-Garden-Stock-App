import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Necesario para Colors
import '../../core/theme/app_theme.dart';
import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import 'glassmorphism_card.dart';

class StockItemCard extends StatelessWidget {
  final StockItemEntity stockItem;
  final ItemInfoEntity? itemInfo;
  final VoidCallback onTap;

  const StockItemCard({
    super.key,
    required this.stockItem,
    this.itemInfo,
    required this.onTap,
  });

  Color _getRarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return Colors.grey.shade600; // Un gris más estándar
      case 'uncommon':
        return Colors.green.shade600;
      case 'rare':
        return AppTheme.electricBlue; // Usando colores de la paleta
      case 'legendary':
        return AppTheme.neonPurple; // Usando colores de la paleta
      case 'mythical':
        return AppTheme.cyberOrange; // Usando colores de la paleta
      case 'divine':
        return Colors.yellow.shade700; // Un dorado intenso
      case 'prismatic':
        return Colors.pink.shade300; // Mantener si es distintivo
      default:
        return AppTheme.darkTextColor.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(itemInfo?.rarity);
    final bool hasRarityInfo = itemInfo != null && itemInfo!.rarity.isNotEmpty && itemInfo!.rarity != "N/A";

    return GlassmorphismCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mejor distribución vertical
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3, // Dar más espacio a la imagen
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: CachedNetworkImage(
                imageUrl: stockItem.iconUrl,
                httpHeaders: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
                },
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CupertinoActivityIndicator(radius: 12),
                errorWidget: (context, url, error) =>
                    const Icon(CupertinoIcons.photo_fill, size: 30, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              stockItem.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock: ${stockItem.quantity}',
            style: AppTheme.bodyTextStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryAppColor.withOpacity(0.85)),
          ),
          if (hasRarityInfo) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                itemInfo!.rarity,
                style: AppTheme.captionTextStyle.copyWith(
                    color: rarityColor,
                    fontWeight: FontWeight.w600, // Hacerlo un poco más bold
                    fontSize: 11),
              ),
            ),
          ] else ... [
             const SizedBox(height: (11.0 + 2 + 4)), // Espacio equivalente para mantener la altura
          ],
          const SizedBox(height: 2), // Pequeño espacio al final
        ],
      ),
    );
  }
}
