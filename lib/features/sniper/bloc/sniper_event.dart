import 'package:equatable/equatable.dart';

abstract class SniperEvent extends Equatable {
  const SniperEvent();

  @override
  List<Object> get props => [];
}

/// Evento para cargar la lista completa de items y la selección del usuario.
class LoadSniperData extends SniperEvent {}

/// Evento para marcar o desmarcar un item de la lista de sniper.
class ToggleSniperItem extends SniperEvent {
  final String itemId;
  final bool isSelected;

  const ToggleSniperItem({required this.itemId, required this.isSelected});

  @override
  List<Object> get props => [itemId, isSelected];
}

// === INICIO DE CAMBIOS ===
/// Evento para filtrar la lista de items basado en un texto de búsqueda.
class SearchItems extends SniperEvent {
  final String query;

  const SearchItems(this.query);

  @override
  List<Object> get props => [query];
}
// === FIN DE CAMBIOS ===
