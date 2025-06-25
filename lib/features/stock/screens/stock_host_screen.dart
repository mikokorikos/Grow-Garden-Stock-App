import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// *** ESTA ES LA LÍNEA QUE SOLUCIONA EL ERROR ***
import 'package:grow_garden_tracker/presentation/bloc/stock/stock_bloc.dart';
import 'package:grow_garden_tracker/presentation/screens/category_tab_screen.dart';
import 'package:grow_garden_tracker/presentation/widgets/header_status_view.dart';

class StockHostScreen extends StatefulWidget {
  const StockHostScreen({super.key});

  @override
  State<StockHostScreen> createState() => _StockHostScreenState();
}

class _StockHostScreenState extends State<StockHostScreen> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Stock de la Tienda'),
      ),
      child: SafeArea(
        child: BlocBuilder<StockBloc, StockState>(
          builder: (context, state) {
            if (state is StockInitial || state is StockLoading) {
              return const Center(
                  child: CupertinoActivityIndicator(radius: 20));
            }

            if (state is StockServiceInactive) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.power,
                          size: 50, color: CupertinoColors.systemGrey),
                      const SizedBox(height: 16),
                      const Text(
                        'Servicio Inactivo',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Para ver el stock en tiempo real, por favor, inicia el servicio de sniper en la pestaña de "Ajustes".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CupertinoColors.secondaryLabel),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is StockError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is StockActive) {
              final stockData = state.stockData;
              final itemDetails = state.itemDetails;

              final availableCategories = stockData.keys
                  .where((k) => stockData[k]!.isNotEmpty)
                  .toList();

              if (availableCategories.isEmpty) {
                return const Center(
                    child: Text("El stock está vacío en este momento."));
              }
              if (_selectedSegment >= availableCategories.length) {
                _selectedSegment = 0;
              }
              final selectedCategoryKey = availableCategories[_selectedSegment];

              final segmentTitles = <String, Widget>{};
              for (int i = 0; i < availableCategories.length; i++) {
                final key = availableCategories[i];
                final title = key == 'eventshop'
                    ? 'Evento'
                    : key[0].toUpperCase() + key.substring(1);
                segmentTitles[i.toString()] = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(title),
                );
              }

              return Column(
                children: [
                  HeaderStatusView(state: state),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: _selectedSegment.toString(),
                      thumbColor: CupertinoColors.activeGreen,
                      children: segmentTitles,
                      onValueChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _selectedSegment = int.parse(value);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: CategoryTabScreen(
                      items: stockData[selectedCategoryKey] ?? [],
                      itemDetails: itemDetails,
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text("Estado no reconocido"));
          },
        ),
      ),
    );
  }
}
