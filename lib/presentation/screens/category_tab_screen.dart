import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../widgets/stock_item_card.dart';

class CategoryTabScreen extends StatelessWidget {
  // Ya no necesita el nombre de la categoría, solo los items a mostrar
  final List<StockItemEntity> items;
  final Map<String, ItemInfoEntity> itemDetails;

  const CategoryTabScreen({
    super.key,
    required this.items,
    required this.itemDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Se elimina el CupertinoPageScaffold y la navigationBar
    if (items.isEmpty) {
      return const Center(child: Text("No hay stock para esta categoría.")); // Text puede ser const
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Puede ser const
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( // Puede ser const
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final stockItem = items[index];
        final info = itemDetails[stockItem.displayName];
        return StockItemCard(
          stockItem: stockItem,
          itemInfo: info,
          onTap: () => _showItemDetailDialog(context,
              stockItem: stockItem, itemInfo: info),
        );
      },
    );
  }

  void _showItemDetailDialog(BuildContext context,
      {required StockItemEntity stockItem, ItemInfoEntity? itemInfo}) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        child: Material(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stockItem.displayName,
                    style: const TextStyle( // Puede ser const
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16), // Puede ser const
                Image.network(
                  stockItem.iconUrl,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(CupertinoIcons.photo, size: 80), // Puede ser const
                ),
                if (itemInfo?.description.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16), // Puede ser const
                  Text(
                    itemInfo!.description,
                    textAlign: TextAlign.center,
                    style: TextStyle( // No puede ser const por AppTheme.textColor.withOpacity(0.7)
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textColor.withOpacity(0.7)),
                  ),
                ],
                const SizedBox(height: 24), // Puede ser const
                if (itemInfo != null) ...[
                  _buildInfoRow('Rareza:', itemInfo.rarity),
                  if (itemInfo.price != "0")
                    _buildInfoRow(
                        'Precio:', '${itemInfo.price} ${itemInfo.currency}'),
                ],
                const SizedBox(height: 24), // Puede ser const
                CupertinoButton.filled(
                    child: const Text('Cerrar'), // Puede ser const
                    onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty ||
        value.contains('N/A') ||
        value.toLowerCase() == 'null') {
      return const SizedBox.shrink(); // Puede ser const
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Puede ser const
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle( // No puede ser const por AppTheme.textColor.withOpacity(0.9)
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor.withOpacity(0.9))),
          const SizedBox(width: 16), // Puede ser const
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: AppTheme.textColor)), // Puede ser const
          ),
        ],
      ),
    );
  }
}
