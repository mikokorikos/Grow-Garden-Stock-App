// Archivo: lib/presentation/bloc/stock/stock_state.dart
part of 'stock_bloc.dart';

abstract class StockState extends Equatable {
  const StockState();
  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockActive extends StockState {
  final Map<String, List<StockItemEntity>> stockData;
  final Map<String, ItemInfoEntity> itemDetails;
  final List<WeatherEntity> weather;
  final DateTime? nearestEndDate;

  const StockActive({
    required this.stockData,
    required this.itemDetails,
    required this.weather,
    this.nearestEndDate,
  });

  @override
  List<Object?> get props => [stockData, itemDetails, weather, nearestEndDate];
}

class StockPolling extends StockState {
  final Map<String, List<StockItemEntity>> lastKnownStockData;
  final Map<String, ItemInfoEntity> itemDetails;
  final List<WeatherEntity> lastKnownWeather;
  final String? message; // Mensaje para mostrar en la UI, ej: "Intentando de nuevo en X segundos..."

  const StockPolling({
    required this.lastKnownStockData,
    required this.itemDetails,
    required this.lastKnownWeather,
    this.message,
  });

  @override
  List<Object?> get props =>
      [lastKnownStockData, itemDetails, lastKnownWeather, message];

  StockPolling copyWith({
    Map<String, List<StockItemEntity>>? lastKnownStockData,
    Map<String, ItemInfoEntity>? itemDetails,
    List<WeatherEntity>? lastKnownWeather,
    String? message,
  }) {
    return StockPolling(
      lastKnownStockData: lastKnownStockData ?? this.lastKnownStockData,
      itemDetails: itemDetails ?? this.itemDetails,
      lastKnownWeather: lastKnownWeather ?? this.lastKnownWeather,
      message: message ?? this.message,
    );
  }
}

class StockError extends StockState {
  final String message;
  const StockError(this.message);
  @override
  List<Object> get props => [message];
}
