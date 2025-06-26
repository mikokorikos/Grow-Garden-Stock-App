import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/theme/app_theme.dart';
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

  Widget _buildBody(BuildContext context, SniperState state) {
    if (state is SniperLoading || state is SniperInitial) {
      return const Center(child: CupertinoActivityIndicator(radius: 25, color: AppTheme.primaryAppColor));
    }
    if (state is SniperError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 60, color: CupertinoColors.systemRed),
              const SizedBox(height: 20),
              Text(
                'Error al cargar Items',
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
    if (state is SniperLoaded) {
      final itemsToShow = state.filteredItemsByCategory;

      if (itemsToShow.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron items para "${_searchController.text}".'
                  : 'No hay items para mostrar.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.darkTextColor.withOpacity(0.7), fontSize: 16),
            ),
          ),
        );
      }

      return ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 20), // Espacio al final de la lista
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
    return Center(child: Text('Estado desconocido.', style: AppTheme.bodyTextStyle));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.lightScaffoldBackgroundColor, // Fondo claro
      navigationBar: CupertinoNavigationBar(
        middle: Text('Sniper de Items', style: AppTheme.cupertinoTheme.textTheme?.navTitleTextStyle),
        // El backgroundColor y el efecto blur se heredan del tema.
      ),
      child: SafeArea(
        bottom: false, // El TabBar ya maneja el SafeArea inferior
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0), // Padding ajustado
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Buscar item por nombre...',
                style: AppTheme.bodyTextStyle.copyWith(fontSize: 16),
                decoration: BoxDecoration(
                  color: AppTheme.glassBarBackgroundColor.withOpacity(0.3), // Fondo sutil
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SniperBloc, SniperState>(
                builder: _buildBody,
              ),
            ),
          ],
        ),
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

  Color _getRarityColor(String? rarity) {
     switch (rarity?.toLowerCase()) {
      case 'common':
        return Colors.grey.shade600;
      case 'uncommon':
        return Colors.green.shade600;
      case 'rare':
        return AppTheme.electricBlue;
      case 'legendary':
        return AppTheme.neonPurple;
      case 'mythical':
        return AppTheme.cyberOrange;
      case 'divine':
        return Colors.yellow.shade700;
      case 'prismatic':
        return Colors.pink.shade300;
      default:
        return AppTheme.darkTextColor.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aplicar estilo glassmorphism a las secciones de lista
    // El backgroundColor del CupertinoListSection.insetGrouped es importante para el efecto glass
    return CupertinoListSection.insetGrouped(
      backgroundColor: Colors.transparent, // Hacer transparente para que el fondo del scaffold se vea
      header: Padding(
        padding: const EdgeInsets.only(left: 18.0, bottom: 6.0), // Ajustar padding del header
        child: Text(
          categoryName,
          style: AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.darkTextColor.withOpacity(0.8)),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0), // Margen de la sección
      children: items.map((item) {
        final rarityColor = _getRarityColor(item.rarity);
        final bool isSelected = selectedIds.contains(item.name);

        return Container( // Envolver CupertinoListTile en Container para el efecto glass
          decoration: BoxDecoration(
            color: AppTheme.glassBackgroundColor.withOpacity(0.75), // Color de fondo del tile
            // No se necesita borderRadius aquí si CupertinoListTile lo maneja o si se quiere un efecto continuo
          ),
          child: CupertinoListTile(
            // El backgroundColor del tile debe ser transparente para que el Container de arriba se vea
            backgroundColor: Colors.transparent,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.rarity.isNotEmpty && item.rarity != "N/A") ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), // Padding ajustado
                    decoration: BoxDecoration(
                      color: rarityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6), // Bordes más redondeados
                      border: Border.all(color: rarityColor.withOpacity(0.3), width: 0.5) // Borde sutil
                    ),
                    child: Text(
                      item.rarity,
                      style: AppTheme.captionTextStyle.copyWith(
                        color: rarityColor,
                        fontWeight: FontWeight.w600, // Un poco más bold
                        fontSize: 11,
                      ),
                    ),
                  )
                ]
              ],
            ),
            leading: CachedNetworkImage(
              imageUrl: item.image,
              width: 44, // Tamaño ligeramente mayor
              height: 44,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(radius: 10),
              errorWidget: (context, url, error) => Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(CupertinoIcons.photo_fill, size: 22, color: CupertinoColors.systemGrey2)
              ),
              imageBuilder: (context, imageProvider) => Container(
                 width: 44, height: 44,
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(8), // Bordes redondeados para la imagen
                   image: DecorationImage(image: imageProvider, fit: BoxFit.cover)
                 ),
              ),
            ),
            trailing: CupertinoSwitch(
              value: isSelected,
              activeColor: AppTheme.primaryAppColor, // Usar color primario del tema
              onChanged: (bool value) {
                HapticFeedback.lightImpact(); // Haptic feedback al cambiar
                context.read<SniperBloc>().add(
                      ToggleSniperItem(itemId: item.name, isSelected: value),
                    );
              },
            ),
            onTap: () { // Permitir tap en toda la fila para cambiar el switch
               HapticFeedback.lightImpact();
               context.read<SniperBloc>().add(
                    ToggleSniperItem(itemId: item.name, isSelected: !isSelected),
                  );
            },
          ),
        );
      }).toList(),
    );
  }
}
