part of 'stock_bloc.dart';

abstract class StockState extends Equatable {
  const StockState();
  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockServiceInactive extends StockState {}

class StockActive extends StockState {
  final Map<String, List<StockItemEntity>> stockData;
  final Map<String, ItemInfoEntity> itemDetails;
  final List<WeatherEntity> weather;

  const StockActive({
    required this.stockData,
    required this.itemDetails,
    required this.weather,
  });

  @override
  List<Object?> get props => [stockData, itemDetails, weather];
}

class StockError extends StockState {
  final String message;
  const StockError(this.message);
  @override
  List<Object> get props => [message];
}

class SniperAlarmTriggered extends StockState {
  final List<String> foundItems;
  final Color rarityColor;

  const SniperAlarmTriggered({required this.foundItems, required this.rarityColor});

  @override
  List<Object?> get props => [foundItems, rarityColor];
}
