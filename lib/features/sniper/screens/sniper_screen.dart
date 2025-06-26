import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import '../bloc/sniper_bloc.dart';
import '../bloc/sniper_event.dart';
import '../bloc/sniper_state.dart';

class SniperScreen extends StatelessWidget {
  const SniperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SniperView();
  }
}

class _SniperView extends StatefulWidget {
  const _SniperView();

  @override
  State<_SniperView> createState() => _SniperViewState();
}

class _SniperViewState extends State<_SniperView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<SniperBloc>().add(SearchItems(_searchController.text));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sniper de Items'),
      ),
      // === INICIO DE CAMBIOS (1. SafeArea) ===
      // Envolvemos el child en un SafeArea para evitar que la UI se oculte
      // debajo de la barra de estado o el notch del teléfono.
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16.0, 8.0, 16.0, 8.0), // Ajustado el padding superior
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Buscar item...',
              ),
            ),
            Expanded(
              child: BlocBuilder<SniperBloc, SniperState>(
                builder: (context, state) {
                  if (state is SniperLoading || state is SniperInitial) {
                    return const Center(
                        child: CupertinoActivityIndicator(radius: 20));
                  }
                  if (state is SniperError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is SniperLoaded) {
                    final itemsToShow = state.filteredItemsByCategory;

                    if (itemsToShow.isEmpty &&
                        _searchController.text.isNotEmpty) {
                      return const Center(
                        child: Text('No se encontraron items.'),
                      );
                    }

                    return ListView.builder(
                      // Añadido para que el teclado se oculte al hacer scroll
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: itemsToShow.keys.length,
                      itemBuilder: (context, index) {
                        final categoryName = itemsToShow.keys.elementAt(index);
                        final items = itemsToShow[categoryName]!;
                        return _CategorySection(
                          categoryName: categoryName,
                          items: items,
                          selectedIds: state.selectedItemIds,
                        );
                      },
                    );
                  }
                  return const Center(child: Text('Estado desconocido.'));
                },
              ),
            ),
          ],
        ),
      ),
      // === FIN DE CAMBIOS ===
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String categoryName;
  final List<ItemInfoEntity> items;
  final Set<String> selectedIds;

  const _CategorySection({
    required this.categoryName,
    required this.items,
    required this.selectedIds,
  });

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
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
      case 'prismatic':
        return Colors.pink.shade300;
      case 'common':
      default:
        return CupertinoColors.secondaryLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: Text(categoryName),
      children: items.map((item) {
        return CupertinoListTile(
          // === INICIO DE CAMBIOS (2. Expanded) ===
          // El title ahora es un Row para alinear el nombre y la rareza.
          title: Row(
            children: [
              // El widget Expanded le dice al texto del nombre que ocupe todo
              // el espacio disponible, pero sin empujar a los otros widgets.
              // Esto evita el error de "overflow".
              Expanded(
                child: Text(
                  item.name,
                  overflow: TextOverflow
                      .ellipsis, // Añade '...' si el texto aún es muy largo
                ),
              ),
              const SizedBox(width: 8),
              // La "píldora" de rareza se mantiene igual.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRarityColor(item.rarity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.rarity,
                  style: TextStyle(
                    color: _getRarityColor(item.rarity),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
          // === FIN DE CAMBIOS ===
          leading: Image.network(
            item.image,
            width: 40,
            height: 40,
            errorBuilder: (c, e, s) => const Icon(CupertinoIcons.photo),
          ),
          trailing: CupertinoSwitch(
            value: selectedIds.contains(item.name),
            onChanged: (bool value) {
              context.read<SniperBloc>().add(
                    ToggleSniperItem(itemId: item.name, isSelected: value),
                  );
            },
          ),
        );
      }).toList(),
    );
  }
}
