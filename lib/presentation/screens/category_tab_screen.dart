// Archivo: lib/presentation/screens/category_tab_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    final methodName = "CategoryTabScreen.build";
    debugPrint(
        "[$methodName] Construyendo pantalla para categoría: '$categoryName' con ${items.length} items.");

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(categoryName[0].toUpperCase() + categoryName.substring(1)),
      ),
      child: SafeArea(
        child: items.isEmpty
            ? Center(child: Text("No hay stock para '$categoryName'."))
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
                  debugPrint(
                      "[$methodName] Construyendo StockItemCard para: '${stockItem.displayName}'");
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
    final methodName = "CategoryTabScreen._showItemDetailDialog";
    debugPrint(
        "[$methodName] Mostrando diálogo de detalles para: '${stockItem.displayName}'");
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        child: Material(
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
                    onPressed: () {
                      debugPrint("[$methodName] Cerrando diálogo de detalles.");
                      Navigator.of(ctx).pop();
                    }),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}
