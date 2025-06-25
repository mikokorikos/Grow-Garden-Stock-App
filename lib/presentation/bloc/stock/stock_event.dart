part of 'stock_bloc.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object?> get props => [];
}

class ListenToStockUpdates extends StockEvent {}

// --- NUEVO EVENTO AÑADIDO ---
class StopListeningToStockUpdates extends StockEvent {}

class _StockDataReceived extends StockEvent {
  final Map<String, List<StockItemEntity>> stockData;
  final List<WeatherEntity> weather;
  final Map<String, ItemInfoEntity> itemDetails;

  const _StockDataReceived({
    required this.stockData,
    required this.weather,
    required this.itemDetails,
  });

  @override
  List<Object?> get props => [stockData, weather, itemDetails];
}

// --- NUEVOS EVENTOS PARA MANEJO SEGURO ---
class _StockProcessingFailed extends StockEvent {
  final String errorMessage;
  const _StockProcessingFailed(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class _PersistentErrorReceived extends StockEvent {
  final String message;
  const _PersistentErrorReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class _SniperAlarmReceived extends StockEvent {
  final List<String> foundItems;
  final Color rarityColor;
  const _SniperAlarmReceived({required this.foundItems, required this.rarityColor});
  @override
  List<Object?> get props => [foundItems, rarityColor];
}