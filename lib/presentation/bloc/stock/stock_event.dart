// Archivo: lib/presentation/bloc/stock/stock_event.dart
part of 'stock_bloc.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object> get props => [];
}

/// Evento para iniciar todo el proceso: obtener detalles y luego escuchar el stock.
class SubscriptionRequested extends StockEvent {}

/// Evento interno para manejar una nueva actualización de stock recibida del WebSocket.
class _StockUpdateReceived extends StockEvent {
  final Map<String, List<StockItemEntity>> stockData;

  const _StockUpdateReceived(this.stockData);

  @override
  List<Object> get props => [stockData];
}
