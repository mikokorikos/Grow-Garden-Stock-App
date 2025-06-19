import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/stock/stock_bloc.dart';
import 'category_tab_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBloc, StockState>(
      builder: (context, state) {
        if (state is StockInitial || state is StockLoadingDetails) {
          return const CupertinoPageScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(radius: 20),
                  SizedBox(height: 16),
                  Text("Cargando detalles de artículos..."),
                ],
              ),
            ),
          );
        }

        if (state is StockError) {
          return CupertinoPageScaffold(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.xmark_octagon,
                        color: CupertinoColors.systemRed, size: 60),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      child: const Text("Reintentar"),
                      onPressed: () => context
                          .read<StockBloc>()
                          .add(SubscriptionRequested()),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is StockListening) {
          final stockData = state.stockData;
          final itemDetails = state.itemDetails;

          final categoryIcons = <String, IconData>{
            "gear": CupertinoIcons.gear_alt_fill,
            "seeds": CupertinoIcons.leaf_arrow_circlepath,
            "honey": CupertinoIcons.drop_fill,
            "cosmetics": CupertinoIcons.wand_stars,
            "egg": CupertinoIcons.egg_fill,
          };

          // Usamos las categorías de los detalles para construir las pestañas,
          // asegurando que siempre estén todas presentes.
          final allCategories = categoryIcons.keys.toList();

          return CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              items: allCategories.map((category) {
                return BottomNavigationBarItem(
                  icon: Icon(categoryIcons[category]),
                  label: category[0].toUpperCase() + category.substring(1),
                );
              }).toList(),
            ),
            tabBuilder: (context, index) {
              final categoryKey = allCategories[index];
              // Pasamos la lista de items para esa categoría (puede estar vacía)
              final itemsForCategory = stockData[categoryKey] ?? [];
              return CategoryTabScreen(
                categoryName:
                    categoryKey[0].toUpperCase() + categoryKey.substring(1),
                items: itemsForCategory,
                itemDetails: itemDetails,
              );
            },
          );
        }

        return const CupertinoPageScaffold(
            child: Center(child: Text("Estado desconocido.")));
      },
    );
  }
}
