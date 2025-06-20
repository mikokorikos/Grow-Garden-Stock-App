// Archivo: lib/presentation/bloc/stock/stock_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/exceptions.dart';
import '../../../domain/entities/item_info_entity.dart';
import '../../../domain/entities/stock_item_entity.dart';
import '../../../domain/entities/weather_entity.dart';
import '../../../domain/usecases/get_all_items_info_usecase.dart';
import '../../../domain/usecases/get_stock_and_weather_usecase.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final GetAllItemsInfoUseCase getAllItemsInfo;
  final GetStockAndWeatherUseCase getStockAndWeather;

  Timer? _primaryCountdownTimer;
  Timer? _pollingTimer;
  int _pollingAttempt = 0;

  StockBloc({
    required this.getAllItemsInfo,
    required this.getStockAndWeather,
  }) : super(StockInitial()) {
    on<FetchInitialData>(_onFetchInitialData);
    on<_PrimaryTimerElapsed>((event, emit) {
      if (state is StockActive) {
        final currentState = state as StockActive;
        emit(StockPolling(
          lastKnownStockData: currentState.stockData,
          itemDetails: currentState.itemDetails,
          lastKnownWeather: currentState.weather,
        ));
      }
      add(_PollForStockUpdate());
    });
    on<_PollForStockUpdate>(_onPollForStockUpdate);
  }

  Future<void> _onFetchInitialData(
      FetchInitialData event, Emitter<StockState> emit) async {
    emit(StockLoading());
    try {
      final itemDetails = await getAllItemsInfo();
      final (stockData, weatherData) = await getStockAndWeather();

      _startPrimaryCountdown(stockData);

      emit(StockActive(
        stockData: stockData,
        itemDetails: itemDetails,
        weather: weatherData,
        nearestEndDate: _calculateNearestEndDate(stockData),
      ));
    } on ServerException {
      emit(const StockError("No se pudo conectar con el servidor."));
    } catch (e) {
      emit(StockError("Ocurrió un error inesperado: ${e.toString()}"));
    }
  }

  Future<void> _onPollForStockUpdate(
      _PollForStockUpdate event, Emitter<StockState> emit) async {
    if (state is! StockPolling) return;

    final currentState = state as StockPolling;
    final oldEndDate =
        _calculateNearestEndDate(currentState.lastKnownStockData);

    try {
      final (newStockData, newWeatherData) = await getStockAndWeather();
      final newEndDate = _calculateNearestEndDate(newStockData);

      if (newEndDate != null && newEndDate != oldEndDate) {
        _pollingAttempt = 0;
        _pollingTimer?.cancel();
        _startPrimaryCountdown(newStockData);

        emit(StockActive(
          stockData: newStockData,
          itemDetails: currentState.itemDetails,
          weather: newWeatherData,
          nearestEndDate: newEndDate,
        ));
      } else {
        _scheduleNextPoll();
      }
    } catch (e) {
      _scheduleNextPoll(); // Si la llamada falla, reintentamos con el backoff.
    }
  }

  void _scheduleNextPoll() {
    _pollingAttempt++;
    final baseDelay = 10;
    final delay = (baseDelay * (1 + (_pollingAttempt * 0.5))).clamp(10, 60);

    _pollingTimer = Timer(Duration(seconds: delay.toInt()), () {
      add(_PollForStockUpdate());
    });
  }

  void _startPrimaryCountdown(Map<String, List<StockItemEntity>> stockData) {
    _primaryCountdownTimer?.cancel();
    final nearestEndDate = _calculateNearestEndDate(stockData);

    if (nearestEndDate != null) {
      final durationUntilEnd = nearestEndDate.difference(DateTime.now());
      if (!durationUntilEnd.isNegative) {
        _primaryCountdownTimer =
            Timer(durationUntilEnd + const Duration(seconds: 20), () {
          add(_PrimaryTimerElapsed());
        });
      }
    }
  }

  DateTime? _calculateNearestEndDate(
      Map<String, List<StockItemEntity>> stockData) {
    DateTime? nearest;
    stockData.values.expand((list) => list).forEach((item) {
      if (nearest == null || item.endDate.isBefore(nearest!)) {
        nearest = item.endDate;
      }
    });
    return nearest;
  }

  @override
  Future<void> close() {
    _primaryCountdownTimer?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
