// Archivo: lib/presentation/bloc/stock/stock_event.dart
part of 'stock_bloc.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object> get props => [];
}

class FetchInitialData extends StockEvent {}

class _PrimaryTimerElapsed extends StockEvent {}

class _PollForStockUpdate extends StockEvent {}
