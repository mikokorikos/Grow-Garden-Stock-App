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
  int _pollingAttempt = 0; // Índice para la secuencia de delays de reintento
  static const List<int> _retryDelays = [5, 10, 20, 30, 60]; // Segundos

  StockBloc({
    required this.getAllItemsInfo,
    required this.getStockAndWeather,
  }) : super(StockInitial()) {
    on<FetchInitialData>(_onFetchInitialData);
    on<_PrimaryTimerElapsed>((event, emit) {
      if (state is StockActive) {
        final currentState = state as StockActive;
        // Al iniciar el sondeo, reseteamos el intento y emitimos StockPolling
        // Podríamos pasar un mensaje inicial aquí si el estado StockPolling lo permite
        _pollingAttempt = 0;
        print("No hay stock. Iniciando sondeo..."); // Mensaje temporal
        final initialMessage = "No hay stock. Intentando de nuevo en ${_retryDelays[_pollingAttempt]} segundos...";
        print("No hay stock. Iniciando sondeo... Próximo intento en ${_retryDelays[_pollingAttempt]}s");
        emit(StockPolling(
          lastKnownStockData: currentState.stockData,
          itemDetails: currentState.itemDetails,
          lastKnownWeather: currentState.weather,
          message: initialMessage,
        ));
      }
      // Iniciamos el primer intento de sondeo inmediatamente después de _PrimaryTimerElapsed
      // _scheduleNextPoll se encargará del delay *antes* del siguiente add(_PollForStockUpdate())
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

      // Condición para considerar el stock actualizado:
      // 1. newEndDate no es nulo (hay algún item con fecha de fin).
      // 2. newEndDate es diferente al oldEndDate (el restock cambió).
      // O, una condición más robusta: verificar si newStockData tiene algún item.
      final bool hasActualStock = newStockData.values.any((list) => list.isNotEmpty);

      if (hasActualStock && newEndDate != null && newEndDate != oldEndDate) {
        print("Stock actualizado encontrado.");
        _pollingAttempt = 0; // Reseteamos el contador de intentos
        _pollingTimer?.cancel();
        _startPrimaryCountdown(newStockData);

        emit(StockActive(
          stockData: newStockData,
          itemDetails: currentState.itemDetails,
          weather: newWeatherData,
          nearestEndDate: newEndDate,
        ));
      } else {
        // No hay stock nuevo o es el mismo que antes, o la API devolvió vacío
        // Procedemos a programar el siguiente reintento.
        _scheduleNextPoll(currentState); // Pasamos el estado actual para poder re-emitir StockPolling con mensaje actualizado
      }
    } catch (e) {
      // Si la llamada a la API falla, también programamos el siguiente reintento.
      print("Error al obtener stock: $e. Reintentando...");
      _scheduleNextPoll(currentState);
    }
  }

  void _scheduleNextPoll(StockPolling previousState) {
    final int delaySeconds;
    if (_pollingAttempt < _retryDelays.length) {
      delaySeconds = _retryDelays[_pollingAttempt];
    } else {
      delaySeconds = _retryDelays.last; // Mantener en 60s indefinidamente
    }

    final message = "No hay stock. Intentando de nuevo en $delaySeconds segundos...";
    print(message); // Mensaje temporal para consola

    // Emitimos un nuevo estado StockPolling que podría llevar el mensaje
    // Esto se formalizará cuando actualicemos stock_state.dart
    // Por ahora, si StockPolling no tiene un campo de mensaje, este emit no cambiará mucho la UI
    // a menos que header_status_view.dart se adapte para leer un nuevo campo.
    // Emitimos el estado ANTES de iniciar el timer para que la UI se actualice.
    emit(StockPolling(
        lastKnownStockData: previousState.lastKnownStockData,
        itemDetails: previousState.itemDetails,
        lastKnownWeather: previousState.lastKnownWeather,
        message: message,
    ));

    _pollingTimer = Timer(Duration(seconds: delaySeconds), () {
      add(_PollForStockUpdate());
    });

    // Incrementar el intento para el *siguiente* ciclo, solo si no hemos alcanzado el final de la lista de delays personalizados
    // Si ya estamos en el último delay (60s), no necesitamos incrementar más _pollingAttempt si queremos que se quede en el último índice.
    if (_pollingAttempt < _retryDelays.length -1) {
       _pollingAttempt++;
    } else {
      // Si ya estamos usando el último valor de _retryDelays (60s),
      // nos aseguramos de que _pollingAttempt apunte al índice de ese último valor
      // para que en la siguiente llamada a _scheduleNextPoll se siga usando 60s.
      _pollingAttempt = _retryDelays.length - 1;
    }
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
