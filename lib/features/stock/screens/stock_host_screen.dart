import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/theme/app_theme.dart';
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

  Widget _buildContent(BuildContext context, StockState state) {
    if (state is StockInitial || state is StockLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 25, color: AppTheme.primaryAppColor));
    }

    if (state is StockServiceInactive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.power, size: 60, color: CupertinoColors.systemGrey.withOpacity(0.8)),
              const SizedBox(height: 20),
              Text(
                'Servicio Inactivo',
                style: AppTheme.headlineStyle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Para ver el stock en tiempo real, por favor, inicia el servicio de sniper en la pestaña de "Ajustes".',
                textAlign: TextAlign.center,
                style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.darkTextColor.withOpacity(0.7), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (state is StockError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 60, color: CupertinoColors.systemRed),
              const SizedBox(height: 20),
               Text(
                'Error al cargar el Stock',
                 style: AppTheme.headlineStyle.copyWith(fontSize: 22),
                 textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.darkTextColor.withOpacity(0.7), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (state is StockActive) {
      final stockData = state.stockData;
      final itemDetails = state.itemDetails;

      final availableCategories = stockData.keys
          .where((k) => stockData[k]!.isNotEmpty)
          .toList();

      if (availableCategories.isEmpty) {
        return Center(
            child: Text(
              "El stock está vacío en este momento.",
              style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.darkTextColor.withOpacity(0.7))
            ));
      }
      // Asegurar que _selectedSegment no esté fuera de rango
      if (_selectedSegment >= availableCategories.length) {
        _selectedSegment = 0;
      }
      final selectedCategoryKey = availableCategories[_selectedSegment];

      final segmentTitles = <int, Widget>{}; // CupertinoSlidingSegmentedControl usa int como key
      for (int i = 0; i < availableCategories.length; i++) {
        final key = availableCategories[i];
        final title = key == 'eventshop'
            ? 'Evento'
            : key[0].toUpperCase() + key.substring(1);
        segmentTitles[i] = Padding( // Usar el índice entero como clave
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Aumentar padding
          child: Text(title, style: AppTheme.bodyTextStyle.copyWith(fontSize: 14)),
        );
      }

      return Column(
        children: [
          HeaderStatusView(state: state), // Este ya tiene su propio estilo glass
          Padding( // Añadir padding alrededor del segmented control
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>( // Cambiado a int
                groupValue: _selectedSegment,
                backgroundColor: AppTheme.glassBarBackgroundColor.withOpacity(0.5), // Fondo glass sutil
                thumbColor: AppTheme.primaryAppColor, // Color del selector
                children: segmentTitles,
                onValueChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _selectedSegment = value;
                    });
                  }
                },
              ),
            ),
          ),
          // No se necesita SizedBox aquí si CategoryTabScreen maneja su propio padding
          Expanded(
            child: CategoryTabScreen(
              items: stockData[selectedCategoryKey] ?? [],
              itemDetails: itemDetails,
            ),
          ),
        ],
      );
    }

    return Center(child: Text("Estado no reconocido", style: AppTheme.bodyTextStyle));
  }


  @override
  Widget build(BuildContext context) {
    // La CupertinoNavigationBar hereda su estilo del CupertinoThemeData
    // incluyendo el barBackgroundColor translúcido.
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Stock de la Tienda', style: AppTheme.cupertinoTheme.textTheme?.navTitleTextStyle),
        // backgroundColor se hereda del tema, no es necesario ponerlo aquí a menos que sea específico para esta barra.
        // El efecto blur se consigue porque el color del tema es translúcido y el contenido hace scroll detrás.
      ),
      child: SafeArea( // SafeArea para evitar solapamientos con notch/barra de estado
        bottom: false, // El TabBar ya maneja el SafeArea inferior
        child: BlocBuilder<StockBloc, StockState>(
          builder: _buildContent,
        ),
      ),
    );
  }
}
