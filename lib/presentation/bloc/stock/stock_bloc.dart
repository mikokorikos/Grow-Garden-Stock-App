// Archivo: lib/presentation/bloc/stock/stock_bloc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart';

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
    debugPrint(
        "[$constructorMethodName] StockBloc Inicializado. Estado inicial: $state");

    on<FetchInitialData>(_onFetchInitialData);
    on<_PrimaryTimerElapsed>(_onPrimaryTimerElapsed);
    on<_PollForStockUpdate>(_onPollForStockUpdate);
  }

  get _primaryCoundownTimer => null;

  void _logEvent(StockEvent event) {
    debugPrint("[$_className] ==> Evento Recibido: ${event.runtimeType}");
  }

  void _logStateChange(StockState newState) {
    debugPrint(
        "[$_className] <== Emitiendo Nuevo Estado: ${newState.runtimeType}");
  }

  Future<void> _onFetchInitialData(
      FetchInitialData event, Emitter<StockState> emit) async {
    _logEvent(event);
    final methodName = "$_className._onFetchInitialData";
    debugPrint("[$methodName] Iniciando proceso de carga de datos iniciales.");

    _logStateChange(StockLoading());
    emit(StockLoading());
    try {
      debugPrint("[$methodName] 1. Llamando a GetAllItemsInfoUseCase...");
      final itemDetails = await getAllItemsInfo();
      debugPrint(
          "[$methodName]    ...GetAllItemsInfoUseCase completado. Items: ${itemDetails.length}");

      debugPrint("[$methodName] 2. Llamando a GetStockAndWeatherUseCase...");
      final (stockData, weatherData) = await getStockAndWeather();
      debugPrint(
          "[$methodName]    ...GetStockAndWeatherUseCase completado. Stock: ${stockData.keys.length} categorías, Weather: ${weatherData.length} registros.");

      _startPrimaryCountdown(stockData);

      final newState = StockActive(
        stockData: stockData,
        itemDetails: itemDetails,
        weather: weatherData,
        nearestEndDate: _calculateNearestEndDate(stockData),
      );
      _logStateChange(newState);
      emit(newState);
      debugPrint(
          "[$methodName] Proceso de carga inicial finalizado. Estado StockActive emitido.");
    } on ServerException catch (e, s) {
      debugPrint("[$methodName] ERROR: ServerException: $e\nStackTrace: $s");
      final errorState = StockError("No se pudo conectar con el servidor.");
      _logStateChange(errorState);
      emit(errorState);
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR: Excepción inesperada: $e\nStackTrace: $s");
      final errorState =
          StockError("Ocurrió un error inesperado: ${e.toString()}");
      _logStateChange(errorState);
      emit(errorState);
    }
  }

  Future<void> _onPrimaryTimerElapsed(
      _PrimaryTimerElapsed event, Emitter<StockState> emit) async {
    _logEvent(event);
    final methodName = "$_className._onPrimaryTimerElapsed";
    debugPrint(
        "[$methodName] El contador principal ha finalizado. El stock activo (si lo había) ha expirado.");

    if (state is StockActive) {
      // *** AQUÍ ESTÁ TU SOLUCIÓN IMPLEMENTADA ***
      // Se reinicia el contador de intentos para que el próximo sondeo sea inmediato.
      debugPrint(
          "[$methodName] Reiniciando contador de intentos de sondeo a 0.");
      _pollingAttempt = 0;

      final currentState = state as StockActive;
      debugPrint(
          "[$methodName] Transicionando de StockActive a StockPolling para buscar nuevo stock.");
      final pollingState = StockPolling(
        lastKnownStockData: currentState.stockData,
        itemDetails: currentState.itemDetails,
        lastKnownWeather: currentState.weather,
      );
      _logStateChange(pollingState);
      emit(pollingState);
      add(_PollForStockUpdate());
    } else {
      debugPrint(
          "[$methodName] Advertencia: El timer finalizó, pero el estado no era StockActive (${state.runtimeType}). No se transiciona a polling.");
    }
  }

  Future<void> _onPollForStockUpdate(
      _PollForStockUpdate event, Emitter<StockState> emit) async {
    _logEvent(event);
    final methodName = "$_className._onPollForStockUpdate";
    debugPrint(
        "[$methodName] Iniciando sondeo de actualización (intento: $_pollingAttempt)...");

    if (state is! StockPolling) {
      debugPrint(
          "[$methodName] Abortando sondeo: El estado actual ya no es StockPolling (${state.runtimeType}).");
      return;
    }

    final currentState = state as StockPolling;
    final oldStockData = currentState.lastKnownStockData;

    try {
      debugPrint(
          "[$methodName] Llamando a GetStockAndWeatherUseCase para actualizar...");
      final (newStockData, newWeatherData) = await getStockAndWeather();

      debugPrint(
          "[$methodName] Realizando comparación profunda (deep equality) entre el stock viejo y el nuevo.");
      final bool areStocksEqual =
          const DeepCollectionEquality().equals(oldStockData, newStockData);

      if (!areStocksEqual) {
        debugPrint(
            "[$methodName] ¡Cambio detectado en el stock! Actualizando a StockActive.");
        _pollingAttempt = 0;
        _pollingTimer?.cancel();

        final newEndDate = _calculateNearestEndDate(newStockData);
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
        debugPrint(
            "[$methodName] Sin cambios detectados en el stock. Programando siguiente sondeo.");
        _scheduleNextPoll();
      }
    } catch (e, s) {
      debugPrint(
          "[$methodName] ERROR durante el sondeo: $e\nStackTrace: $s. Reintentando...");
      _scheduleNextPoll();
    }
  }

  void _scheduleNextPoll() {
    final methodName = "$_className._scheduleNextPoll";
    _pollingAttempt++;
    final baseDelay = 10;
    final delay = (baseDelay * (1 + (_pollingAttempt * 0.5))).clamp(10, 60);
    debugPrint(
        "[$methodName] Programando siguiente sondeo en $delay segundos (intento: $_pollingAttempt).");

    _pollingTimer?.cancel();
    _pollingTimer = Timer(Duration(seconds: delay.toInt()), () {
      debugPrint(
          "[$methodName] Timer de sondeo disparado. Añadiendo evento _PollForStockUpdate.");
      add(_PollForStockUpdate());
    });
  }

  void _startPrimaryCountdown(Map<String, List<StockItemEntity>> stockData) {
    final methodName = "$_className._startPrimaryCountdown";
    _primaryCountdownTimer?.cancel();

    final nearestEndDate = _calculateNearestEndDate(stockData);
    debugPrint(
        "[$methodName] Evaluando nearestEndDate para el countdown: $nearestEndDate");

    if (nearestEndDate != null) {
      final durationUntilEnd = nearestEndDate.difference(DateTime.now());
      if (!durationUntilEnd.isNegative) {
        final timerDuration = durationUntilEnd + const Duration(seconds: 20);
        debugPrint(
            "[$methodName] Iniciando timer primario con duración: $timerDuration (hasta $nearestEndDate + 20s).");
        _primaryCountdownTimer = Timer(timerDuration, () {
          debugPrint(
              "[$methodName] Timer primario disparado. Añadiendo evento _PrimaryTimerElapsed.");
          add(_PrimaryTimerElapsed());
        });
      } else {
        debugPrint(
            "[$methodName] NearestEndDate ($nearestEndDate) ya pasó. Disparando _PrimaryTimerElapsed inmediatamente.");
        add(_PrimaryTimerElapsed());
      }
    } else {
      debugPrint(
          "[$methodName] No hay nearestEndDate. No se inicia timer primario.");
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
    final methodName = "$_className.close";
    debugPrint("[$methodName] Cerrando StockBloc y cancelando timers...");
    _primaryCoundownTimer?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
