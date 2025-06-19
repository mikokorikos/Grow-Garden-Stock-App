import 'package:flutter/cupertino.dart';
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
            ? const Center(
                child: Text("Esperando stock para esta categoría..."))
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
                  // Buscamos el detalle por el nombre que nos da el WebSocket
                  final info = itemDetails[stockItem.displayName];
                  return StockItemCard(stockItem: stockItem, itemInfo: info);
                },
              ),
      ),
    );
  }
}
