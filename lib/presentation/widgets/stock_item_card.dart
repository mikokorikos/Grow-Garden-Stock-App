// Archivo: lib/presentation/widgets/stock_item_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(itemInfo?.rarity);

    return GlassmorphismCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CachedNetworkImage(
                imageUrl: stockItem.iconUrl,
                httpHeaders: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
                },
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CupertinoActivityIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(CupertinoIcons.photo, size: 40),
              ),
            ),
          ),
          Text(
            stockItem.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock: ${stockItem.quantity}',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
          if (itemInfo != null)
            Text(
              itemInfo!.rarity,
              style: TextStyle(
                  fontSize: 12,
                  color: rarityColor,
                  fontWeight: FontWeight.w500),
            )
        ],
      ),
    );
  }

  Color _getRarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return CupertinoColors.systemGrey;
      case 'uncommon':
        return CupertinoColors.systemGreen;
      case 'rare':
        return CupertinoColors.systemBlue;
      case 'legendary':
        return CupertinoColors.systemPurple;
      case 'mythical':
        return CupertinoColors.systemOrange;
      case 'divine':
        return CupertinoColors.systemYellow;
      default:
        return AppTheme.textColor;
    }
  }
}
