import 'package:flutter/cupertino.dart';
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

// === INICIO DE CAMBIOS ===
// 1. Convertido a StatefulWidget para manejar el TextEditingController
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
    // Añadimos un listener para despachar el evento de búsqueda cuando el usuario escribe
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
      child: Column(
        // 2. Envuelto en un Column
        children: [
          // 3. Añadimos el campo de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Buscar item...',
            ),
          ),
          // 4. La lista ahora está dentro de un Expanded
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
                  // 5. Usamos la lista FILTRADA
                  final itemsToShow = state.filteredItemsByCategory;

                  if (itemsToShow.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron items.'),
                    );
                  }

                  return ListView.builder(
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
    );
  }
}
// === FIN DE CAMBIOS ===

class _CategorySection extends StatelessWidget {
  final String categoryName;
  final List<ItemInfoEntity> items;
  final Set<String> selectedIds;

  const _CategorySection({
    required this.categoryName,
    required this.items,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: Text(categoryName),
      children: items.map((item) {
        return CupertinoListTile(
          title: Text(item.name),
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
