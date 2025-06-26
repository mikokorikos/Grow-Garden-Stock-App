import 'package:equatable/equatable.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';

abstract class SniperState extends Equatable {
  const SniperState();

  @override
  List<Object> get props => [];
}

class SniperInitial extends SniperState {}

class SniperLoading extends SniperState {}

class SniperLoaded extends SniperState {
  /// Todos los items del juego, sin filtrar. Se usa como fuente de verdad.
  final Map<String, List<ItemInfoEntity>> allItemsByCategory;

  // === INICIO DE CAMBIOS ===
  /// Los items que se mostrarán en la UI, ya filtrados por la búsqueda.
  final Map<String, List<ItemInfoEntity>> filteredItemsByCategory;
  // === FIN DE CAMBIOS ===

  /// El conjunto de IDs de los items que el usuario ha seleccionado.
  final Set<String> selectedItemIds;

  const SniperLoaded({
    required this.allItemsByCategory,
    required this.filteredItemsByCategory, // Añadido
    required this.selectedItemIds,
  });

  @override
  List<Object> get props =>
      [allItemsByCategory, filteredItemsByCategory, selectedItemIds];

  SniperLoaded copyWith({
    Map<String, List<ItemInfoEntity>>? allItemsByCategory,
    Map<String, List<ItemInfoEntity>>? filteredItemsByCategory, // Añadido
    Set<String>? selectedItemIds,
  }) {
    return SniperLoaded(
      allItemsByCategory: allItemsByCategory ?? this.allItemsByCategory,
      filteredItemsByCategory:
          filteredItemsByCategory ?? this.filteredItemsByCategory, // Añadido
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
    );
  }
}

class SniperError extends SniperState {
  final String message;

  const SniperError(this.message);

  @override
  List<Object> get props => [message];
}
