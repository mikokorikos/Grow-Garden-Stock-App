import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Necesario para el Material en el diálogo
import '../../core/theme/app_theme.dart';
import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../widgets/stock_item_card.dart';

class CategoryTabScreen extends StatelessWidget {
  final String categoryName;
  final List<StockItemEntity> items;
  final Map<String, ItemInfoEntity> itemDetails;

  const CategoryTabScreen({
    super.key,
    required this.categoryName,
    required this.items,
    required this.itemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(categoryName)),
      child: SafeArea(
        child: items.isEmpty
            ? const Center(child: Text("No hay stock para esta categoría."))
            : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              ),
      ),
    );
  }

  void _showItemDetailDialog(BuildContext context,
      {required StockItemEntity stockItem, ItemInfoEntity? itemInfo}) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        child: Material(
          // Material para que se vea el texto
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stockItem.displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Image.network(stockItem.iconUrl, height: 100),
                const SizedBox(height: 16),
                if (itemInfo != null) ...[
                  _buildInfoRow('Categoría:', itemInfo.category),
                  _buildInfoRow('Rareza:', itemInfo.rarity),
                  _buildInfoRow('Precio Compra:', itemInfo.buyPrice),
                  _buildInfoRow('Valor Venta:', itemInfo.sellValue),
                  _buildInfoRow(
                      'Comerciable:', itemInfo.tradeable ? 'Sí' : 'No'),
                ],
                const SizedBox(height: 24),
                CupertinoButton.filled(
                    child: const Text('Cerrar'),
                    onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textColor)),
          Text(value, style: const TextStyle(color: AppTheme.textColor)),
        ],
      ),
    );
  }
}
