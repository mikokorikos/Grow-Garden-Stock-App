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
  /// Todos los items del juego, agrupados por categoría.
  final Map<String, List<ItemInfoEntity>> allItemsByCategory;

  /// El conjunto de IDs de los items que el usuario ha seleccionado.
  final Set<String> selectedItemIds;

  const SniperLoaded({
    required this.allItemsByCategory,
    required this.selectedItemIds,
  });

  @override
  List<Object> get props => [allItemsByCategory, selectedItemIds];

  SniperLoaded copyWith({
    Map<String, List<ItemInfoEntity>>? allItemsByCategory,
    Set<String>? selectedItemIds,
  }) {
    return SniperLoaded(
      allItemsByCategory: allItemsByCategory ?? this.allItemsByCategory,
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
