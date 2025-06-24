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
    const methodName = "HomeScreen.build";
    debugPrint("[$methodName] Construyendo widget...");

    return BlocListener<StockBloc, StockState>(
      listener: (context, state) {
        debugPrint(
            "[$methodName.BlocListener] El estado del StockBloc ha cambiado a: ${state.runtimeType}");
        if (state is StockActive) {
          Fluttertoast.showToast(msg: "Stock actualizado");
          debugPrint(
              "[$methodName.BlocListener] Mostrando Toast: Stock actualizado.");
        }
      },
      child: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          debugPrint(
              "[$methodName.BlocBuilder] Reconstruyendo UI con estado: ${state.runtimeType}");

          if (state is StockInitial || state is StockLoading) {
            debugPrint(
                "[$methodName.BlocBuilder] Mostrando pantalla de carga.");
            return _buildLoadingScreen("Cargando stock...");
          }

          if (state is StockError) {
            debugPrint(
                "[$methodName.BlocBuilder] Mostrando pantalla de error: ${state.message}");
            return _buildErrorScreen(context, state.message);
          }

          if (state is StockActive || state is StockPolling) {
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

            debugPrint(
                "[$methodName.BlocBuilder] Mostrando UI principal (CupertinoTabScaffold).");
            return CupertinoPageScaffold(
              child: Column(
                children: [
                  SafeArea(
                      bottom: false, child: HeaderStatusView(state: state)),
                  Expanded(
                    child: CupertinoTabScaffold(
                      tabBar: CupertinoTabBar(
                        onTap: (index) => debugPrint(
                            "[$methodName] Tab seleccionado: ${allCategories[index]}"),
                        items: allCategories.map((cat) {
                          final label = cat[0].toUpperCase() + cat.substring(1);
                          return BottomNavigationBarItem(
                              icon: Icon(categoryIcons[cat]), label: label);
                        }).toList(),
                      ),
                      tabBuilder: (context, index) {
                        final categoryKey = allCategories[index];
                        debugPrint(
                            "[$methodName.tabBuilder] Construyendo tab para la categoría: $categoryKey");
                        return CategoryTabScreen(
                          categoryName: categoryKey,
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

          debugPrint(
              "[$methodName.BlocBuilder] Estado no manejado, mostrando carga por defecto.");
          return _buildLoadingScreen("Inicializando...");
        },
      ),
    );
  }

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
                onPressed: () {
                  debugPrint(
                      "[HomeScreen._buildErrorScreen] Botón 'Reintentar' presionado. Añadiendo FetchInitialData.");
                  context.read<StockBloc>().add(FetchInitialData());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
