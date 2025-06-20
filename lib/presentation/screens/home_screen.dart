// Archivo: lib/presentation/screens/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:collection/collection.dart';
import '../bloc/stock/stock_bloc.dart';
import '../widgets/header_status_view.dart';
import 'category_tab_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockBloc, StockState>(
      listener: (previous, current) {
        // Mostramos un toast cuando se actualiza el stock
        if (previous is StockActive &&
            current is StockActive &&
            !const DeepCollectionEquality()
                .equals(previous.stockData, current.stockData)) {
          Fluttertoast.showToast(msg: "Stock actualizado");
        }
      },
      child: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state is StockInitial || state is StockLoading) {
            return _buildLoadingScreen("Cargando stock...");
          }

          if (state is StockError) {
            return _buildErrorScreen(context, state.message);
          }

          // Si estamos en estado Activo o de Sondeo, mostramos la UI principal.
          if (state is StockActive || state is StockPolling) {
            // Extraemos los datos del estado actual, sea cual sea.
            final stockData = state is StockActive
                ? state.stockData
                : (state as StockPolling).lastKnownStockData;
            final itemDetails = state is StockActive
                ? state.itemDetails
                : (state as StockPolling).itemDetails;

            final categoryIcons = <String, IconData>{
              "gear": CupertinoIcons.gear_alt_fill,
              "seed": CupertinoIcons.leaf_arrow_circlepath,
              "cosmetic": CupertinoIcons.wand_stars,
              "egg": CupertinoIcons.eye,
              "eventshop": CupertinoIcons.gift_alt_fill,
            };
            final allCategories = categoryIcons.keys.toList();

            return CupertinoPageScaffold(
              child: Column(
                children: [
                  // Pasamos el estado al Header para que pueda mostrar "Actualizando..." si es necesario.
                  SafeArea(
                      bottom: false, child: HeaderStatusView(state: state)),
                  Expanded(
                    child: CupertinoTabScaffold(
                      tabBar: CupertinoTabBar(
                        items: allCategories.map((cat) {
                          final label = cat[0].toUpperCase() + cat.substring(1);
                          return BottomNavigationBarItem(
                              icon: Icon(categoryIcons[cat]), label: label);
                        }).toList(),
                      ),
                      tabBuilder: (context, index) {
                        final categoryKey = allCategories[index];
                        final label = categoryKey[0].toUpperCase() +
                            categoryKey.substring(1);
                        return CategoryTabScreen(
                          categoryName: label,
                          items: stockData[categoryKey] ?? [],
                          itemDetails: itemDetails,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildLoadingScreen("Inicializando...");
        },
      ),
    );
  }

  /// Widget helper reutilizable para mostrar una pantalla de carga estándar.
  Widget _buildLoadingScreen(String message) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 20),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Widget helper reutilizable para mostrar una pantalla de error con un botón para reintentar.
  Widget _buildErrorScreen(BuildContext context, String message) {
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
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                child: const Text("Reintentar"),
                onPressed: () =>
                    context.read<StockBloc>().add(FetchInitialData()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on BuildContext {
  Object? get stockData => null;
}
