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
