import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import '../bloc/sniper_bloc.dart';
import '../bloc/sniper_event.dart';
import '../bloc/sniper_state.dart';

// El widget principal ahora es mucho más simple.
class SniperScreen extends StatelessWidget {
  const SniperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ya no crea un BlocProvider. Asume que uno ya existe en el árbol de widgets.
    // El evento LoadSniperData ahora se despacha desde main.dart.
    return const _SniperView();
  }
}

class _SniperView extends StatelessWidget {
  const _SniperView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sniper de Items'),
      ),
      child: BlocBuilder<SniperBloc, SniperState>(
        builder: (context, state) {
          if (state is SniperLoading || state is SniperInitial) {
            return const Center(child: CupertinoActivityIndicator(radius: 20));
          }
          if (state is SniperError) {
            return Center(child: Text(state.message));
          }
          if (state is SniperLoaded) {
            return ListView.builder(
              itemCount: state.allItemsByCategory.keys.length,
              itemBuilder: (context, index) {
                final categoryName =
                    state.allItemsByCategory.keys.elementAt(index);
                final items = state.allItemsByCategory[categoryName]!;
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
