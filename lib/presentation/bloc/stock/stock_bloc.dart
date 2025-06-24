// Archivo: lib/presentation/bloc/stock/stock_bloc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final String _className = "StockBloc";

  Timer? _primaryCountdownTimer;
  Timer? _pollingTimer;
  int _pollingAttempt = 0;

  StockBloc({
    required this.getAllItemsInfo,
    required this.getStockAndWeather,
  }) : super(StockInitial()) {
    final constructorMethodName = "$_className.constructor";
    debugPrint("[$constructorMethodName] Inicializando StockBloc. Estado inicial: $state");

    on<FetchInitialData>(_onFetchInitialData);
    on<_PrimaryTimerElapsed>(_onPrimaryTimerElapsed);
    on<_PollForStockUpdate>(_onPollForStockUpdate);
  }

  void _logEvent(StockEvent event) {
    debugPrint("[$_className] Evento recibido: ${event.runtimeType}");
  }

  void _logStateChange(StockState newState) {
    debugPrint("[$_className] Emitiendo nuevo estado: ${newState.runtimeType}");
  }

  Future<void> _onFetchInitialData(
      FetchInitialData event, Emitter<StockState> emit) async {
    _logEvent(event);
    final methodName = "$_className._onFetchInitialData";
    debugPrint("[$methodName] Iniciando...");

    _logStateChange(StockLoading());
    emit(StockLoading());
    try {
      debugPrint("[$methodName] Llamando a getAllItemsInfo use case...");
      final itemDetails = await getAllItemsInfo();
      debugPrint("[$methodName] getAllItemsInfo completado. Items: ${itemDetails.length}");

      debugPrint("[$methodName] Llamando a getStockAndWeather use case...");
      final (stockData, weatherData) = await getStockAndWeather();
      debugPrint("[$methodName] getStockAndWeather completado. Stock: ${stockData.keys.length} categorías, Weather: ${weatherData.length} registros.");

      _startPrimaryCountdown(stockData);

      final newState = StockActive(
        stockData: stockData,
        itemDetails: itemDetails,
        weather: weatherData,
        nearestEndDate: _calculateNearestEndDate(stockData),
      );
      _logStateChange(newState);
      emit(newState);
      debugPrint("[$methodName] Estado StockActive emitido con nearestEndDate: ${newState.nearestEndDate}");
    } on ServerException catch (e, s) {
      debugPrint("[$methodName] ServerException: $e\nStackTrace: $s");
      final errorState = StockError("No se pudo conectar con el servidor. Error: $e");
      _logStateChange(errorState);
      emit(errorState);
    } catch (e, s) {
      debugPrint("[$methodName] Excepción inesperada: $e\nStackTrace: $s");
      final errorState = StockError("Ocurrió un error inesperado: ${e.toString()}");
      _logStateChange(errorState);
      emit(errorState);
    }
  }

  Future<void> _onPrimaryTimerElapsed(
      _PrimaryTimerElapsed event, Emitter<StockState> emit) async {
    _logEvent(event);
    final methodName = "$_className._onPrimaryTimerElapsed";
    debugPrint("[$methodName] Iniciando...");

    if (state is StockActive) {
      final currentState = state as StockActive;
      debugPrint("[$methodName] Estado actual es StockActive. Transicionando a StockPolling.");
      final pollingState = StockPolling(
        lastKnownStockData: currentState.stockData,
        itemDetails: currentState.itemDetails,
        lastKnownWeather: currentState.weather,
      );
      _logStateChange(pollingState);
      emit(pollingState);
      add(_PollForStockUpdate());
    } else {
      debugPrint("[$methodName] Estado actual no es StockActive (${state.runtimeType}). No se transiciona a polling.");
    }
  }

  Future<void> _onPollForStockUpdate(
      _PollForStockUpdate event, Emitter<StockState> emit) async {
    _logEvent(event);
    final methodName = "$_className._onPollForStockUpdate";
    debugPrint("[$methodName] Iniciando (intento: $_pollingAttempt)...");

    if (state is! StockPolling) {
      debugPrint("[$methodName] Estado actual no es StockPolling (${state.runtimeType}). Abortando poll.");
      return;
    }

    final currentState = state as StockPolling;
    final oldEndDate = _calculateNearestEndDate(currentState.lastKnownStockData);
    debugPrint("[$methodName] Old nearestEndDate: $oldEndDate");

    try {
      debugPrint("[$methodName] Llamando a getStockAndWeather use case para actualizar...");
      final (newStockData, newWeatherData) = await getStockAndWeather();
      final newEndDate = _calculateNearestEndDate(newStockData);
      debugPrint("[$methodName] Datos actualizados recibidos. New nearestEndDate: $newEndDate");

      if (newEndDate != null && newEndDate != oldEndDate) {
        debugPrint("[$methodName] Cambio detectado en nearestEndDate. Actualizando a StockActive.");
        _pollingAttempt = 0;
        _pollingTimer?.cancel();
        debugPrint("[$methodName] Polling timer cancelado y contador de intentos reseteado.");
        _startPrimaryCountdown(newStockData);

        final activeState = StockActive(
          stockData: newStockData,
          itemDetails: currentState.itemDetails,
          weather: newWeatherData,
          nearestEndDate: newEndDate,
        );
        _logStateChange(activeState);
        emit(activeState);
      } else {
        debugPrint("[$methodName] No hubo cambio significativo en nearestEndDate o es nulo. Programando siguiente poll.");
        _scheduleNextPoll();
      }
    } catch (e, s) {
      debugPrint("[$methodName] Excepción durante el poll: $e\nStackTrace: $s. Programando siguiente poll.");
      _scheduleNextPoll(); // Si la llamada falla, reintentamos con el backoff.
    }
  }

  void _scheduleNextPoll() {
    final methodName = "$_className._scheduleNextPoll";
    _pollingAttempt++;
    final baseDelay = 10; // segundos
    final delay = (baseDelay * (1 + (_pollingAttempt * 0.5))).clamp(10, 60);
    debugPrint("[$methodName] Programando siguiente poll en $delay segundos (intento: $_pollingAttempt).");

    _pollingTimer?.cancel(); // Cancela timer anterior si existiera
    _pollingTimer = Timer(Duration(seconds: delay.toInt()), () {
      debugPrint("[$methodName] Timer de polling disparado. Añadiendo evento _PollForStockUpdate.");
      add(_PollForStockUpdate());
    });
  }

  void _startPrimaryCountdown(Map<String, List<StockItemEntity>> stockData) {
    final methodName = "$_className._startPrimaryCountdown";
    _primaryCountdownTimer?.cancel();
    debugPrint("[$methodName] Timer primario cancelado (si existía).");

    final nearestEndDate = _calculateNearestEndDate(stockData);
    // El log de nearestEndDate calculada se movió a _calculateNearestEndDate para reducir verbosidad aquí si no hay cambios.
    // Sin embargo, es útil loguearlo aquí también para el contexto de _startPrimaryCountdown.
    debugPrint("[$methodName] Nearest end date evaluada para el countdown: $nearestEndDate");


    if (nearestEndDate != null) {
      final durationUntilEnd = nearestEndDate.difference(DateTime.now());
      debugPrint("[$methodName] Duración hasta nearestEndDate: $durationUntilEnd");

      if (!durationUntilEnd.isNegative) {
        final timerDuration = durationUntilEnd + const Duration(seconds: 20);
        debugPrint("[$methodName] Iniciando timer primario con duración: $timerDuration. Se esperará hasta $nearestEndDate + 20s.");
        _primaryCountdownTimer = Timer(timerDuration, () {
          debugPrint("[$methodName] Timer primario disparado (espera por $nearestEndDate finalizada). Añadiendo evento _PrimaryTimerElapsed.");
          add(_PrimaryTimerElapsed());
        });
      } else {
        debugPrint("[$methodName] NearestEndDate ($nearestEndDate) ya pasó. No se inicia el timer primario. Se podría considerar iniciar polling directamente si es el comportamiento deseado.");
        // Si se quisiera iniciar polling inmediatamente en este caso:
        // if (state is StockActive || state is StockInitial) { // Evitar múltiples inicios de polling si ya está en StockPolling
        //   add(_PrimaryTimerElapsed()); // Esto simularía que el timer acaba de expirar
        // }
      }
    } else {
      debugPrint("[$methodName] No hay nearestEndDate (es nula). No se inicia el timer primario. El sistema podría depender del polling si está activo, o esperar nueva data.");
       // Si no hay fecha, y el estado es activo, podría ser una señal para empezar a pollear si no se está haciendo ya.
       // Esto es importante para el caso "No hay restocks activos"
      if (state is StockActive) {
         final currentState = state as StockActive;
         // Si no hay fecha de fin, y no estamos ya en polling, y no hay items (o los items no tienen fecha),
         // es un indicativo de que "no hay restocks activos" o los datos iniciales no tienen fechas.
         bool hasAnyEndDate = currentState.stockData.values.expand((list) => list).any((item) => item.endDate != null);
         if (!hasAnyEndDate) {
            debugPrint("[$methodName] No hay nearestEndDate y ningún item en el stock actual tiene fecha de finalización. Posiblemente 'No hay restocks activos'.");
         }
         // Considerar si se debe pasar a polling aquí si no hay fecha y no se está polleando.
         // Por ahora, solo se loguea. La lógica de _onPrimaryTimerElapsed se encargará del polling.
      }
    }
  }

  DateTime? _calculateNearestEndDate(
      Map<String, List<StockItemEntity>> stockData) {
    final methodName = "$_className._calculateNearestEndDate";
    // debugPrint("[$methodName] Calculando nearestEndDate para ${stockData.length} categorías de stock.");
    DateTime? nearest;
    stockData.values.expand((list) => list).forEach((item) {
      if (nearest == null || item.endDate.isBefore(nearest!)) {
        nearest = item.endDate;
      }
    });
    // debugPrint("[$methodName] NearestEndDate calculada: $nearest");
    return nearest;
  }

  @override
  Future<void> close() {
    final methodName = "$_className.close";
    debugPrint("[$methodName] Cerrando StockBloc...");
    _primaryCountdownTimer?.cancel();
    _pollingTimer?.cancel();
    debugPrint("[$methodName] Timers cancelados.");
    return super.close();
  }
}
