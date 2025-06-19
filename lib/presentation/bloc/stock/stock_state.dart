// Archivo: lib/presentation/bloc/stock/stock_state.dart
part of 'stock_bloc.dart';

abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

/// Estado mientras se obtienen los detalles de los ítems (la primera carga).
class StockLoadingDetails extends StockState {}

/// Estado principal: la app está escuchando y mostrando datos en tiempo real.
class StockListening extends StockState {
  final Map<String, List<StockItemEntity>> stockData;
  final Map<String, ItemInfoEntity> itemDetails;

  const StockListening({required this.stockData, required this.itemDetails});

  @override
  List<Object?> get props => [stockData, itemDetails];
}

/// Estado para manejar cualquier error crítico (ej. fallo al obtener detalles).
class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object> get props => [message];
}
