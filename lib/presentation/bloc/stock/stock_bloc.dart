import 'dart:async';
import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/entities/stock_item_entity.dart';
import 'package:grow_garden_tracker/domain/entities/weather_entity.dart';
import 'package:grow_garden_tracker/data/models/stock_item_model.dart';
import 'package:grow_garden_tracker/data/models/weather_model.dart';
import 'package:grow_garden_tracker/domain/usecases/get_all_items_info_usecase.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final GetAllItemsInfoUseCase _getAllItemsInfoUseCase;
  final String _className = "StockBloc"; // Para logging
  StreamSubscription<Map<String, dynamic>?>? _stockSubscription;
  StreamSubscription<Map<String, dynamic>?>? _errorSubscription;
  bool _isProcessingStockData =
      false; // Flag para evitar procesamiento concurrente

  StockBloc({
    required GetAllItemsInfoUseCase getAllItemsInfoUseCase,
  })  : _getAllItemsInfoUseCase = getAllItemsInfoUseCase,
        super(StockInitial()) {
    on<ListenToStockUpdates>(_onListenToStockUpdates);
    on<StopListeningToStockUpdates>(_onStopListeningToStockUpdates);
    on<_StockDataReceived>(_onStockDataReceived);
    on<_StockProcessingFailed>(
        (event, emit) => emit(StockError(event.errorMessage)));
  }

  void _cancelSubscriptions() {
    logI("[$_className] Cancelando suscripciones...");
    _stockSubscription?.cancel();
    _errorSubscription?.cancel();
    _stockSubscription = null;
    _errorSubscription = null;
  }

  void _onListenToStockUpdates(
    ListenToStockUpdates event,
    Emitter<StockState> emit,
  ) async {
    _cancelSubscriptions();
    final methodName = "$_className._onListenToStockUpdates";
    logI("[$methodName] Iniciando escucha de actualizaciones de stock...");

    emit(StockLoading());

    final service = FlutterBackgroundService();

    _stockSubscription = service.on('updateStock').listen((eventData) async {
      if (_isProcessingStockData) {
        logW(
            "[$methodName] Stock data processing already in progress, skipping new 'updateStock' event.");
        return;
      }
      _isProcessingStockData = true;
      try {
        if (eventData != null) {
          logD(
              "[$methodName] Datos de 'updateStock' recibidos del servicio: $eventData");
          final processedEvent = await _processServiceData(eventData);
          if (processedEvent is StockEvent) {
            add(processedEvent);
          }
        } else {
          logW("[$methodName] Evento 'updateStock' nulo recibido.");
        }
      } on AppException catch (e, s) {
        logE("[$methodName] AppException en _processServiceData",
            error: e, stackTrace: s);
        add(_StockProcessingFailed(e.toString()));
      } catch (e, s) {
        logE("[$methodName] Excepción genérica en _processServiceData",
            error: e, stackTrace: s);
        add(_StockProcessingFailed(
            "Error interno al procesar datos del stock: ${e.toString()}"));
      } finally {
        _isProcessingStockData = false;
      }
    }, onError: (error, stackTrace) {
      _isProcessingStockData = false;
      logE("[$methodName] ERROR en stream 'updateStock'",
          error: error, stackTrace: stackTrace);
      if (!emit.isDone)
        emit(StockError(
            "Error en la comunicación con el servicio de fondo (stock): ${error.toString()}"));
    });

    _errorSubscription = service.on('persistent_error').listen((eventData) {
      if (eventData != null && eventData['message'] != null) {
        logW(
            "[$methodName] 'persistent_error' recibido: ${eventData['message']}");
        if (!emit.isDone) emit(StockError(eventData['message']));
      } else {
        logW("[$methodName] Evento 'persistent_error' nulo o sin mensaje.");
      }
    }, onError: (error, stackTrace) {
      logE("[$methodName] ERROR en stream 'persistent_error'",
          error: error, stackTrace: stackTrace);
      if (!emit.isDone)
        emit(StockError(
            "Error en la comunicación con el servicio de fondo (errores): ${error.toString()}"));
    });

    try {
      if (await service.isRunning()) {
        logI(
            "[$methodName] El servicio está corriendo. Solicitando datos iniciales...");
        service.invoke('requestInitialData');
      } else {
        logW(
            "[$methodName] El servicio no está corriendo. Emitiendo StockServiceInactive.");
        if (!emit.isDone) emit(StockServiceInactive());
      }
    } catch (e, s) {
      logE(
          "[$methodName] ERROR al verificar el estado del servicio o al invocar 'requestInitialData'",
          error: e,
          stackTrace: s);
      if (!emit.isDone)
        emit(StockError(
            "No se pudo comunicar con el servicio de fondo: ${e.toString()}"));
    }
  }

  void _onStopListeningToStockUpdates(
    StopListeningToStockUpdates event,
    Emitter<StockState> emit,
  ) {
    final methodName = "$_className._onStopListeningToStockUpdates";
    logI("[$methodName] Deteniendo escucha de actualizaciones de stock.");
    _cancelSubscriptions();
    emit(StockServiceInactive());
  }

  Future<StockEvent?> _processServiceData(
      Map<String, dynamic> eventData) async {
    final methodName = "$_className._processServiceData";
    logD("[$methodName] Procesando datos recibidos del servicio: $eventData");

    final rawStock = Map<String, dynamic>.from(eventData['stock'] ?? {});
    final rawWeather = List<dynamic>.from(eventData['weather'] ?? []);

    final stockData = <String, List<StockItemEntity>>{};
    rawStock.forEach((key, value) {
      if (value is List) {
        try {
          stockData[key] = value
              .map((item) =>
                  StockItemModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        } catch (e, s) {
          logE(
              "[$methodName] ERROR al parsear un item de stock en la categoría '$key'. Item: $value",
              error: e,
              stackTrace: s);
        }
      }
    });

    final weatherData = <WeatherEntity>[];
    for (var item in rawWeather) {
      try {
        weatherData.add(WeatherModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (e, s) {
        logE("[$methodName] ERROR al parsear un item de clima. Item: $item",
            error: e, stackTrace: s);
      }
    }

    logD("[$methodName] Obteniendo detalles de items...");
    final itemDetails = await _getAllItemsInfoUseCase();
    logI(
        "[$methodName] Detalles de items obtenidos. Retornando _StockDataReceived event.");
    return _StockDataReceived(
        stockData: stockData, weather: weatherData, itemDetails: itemDetails);
  }

  void _onStockDataReceived(
    _StockDataReceived event,
    Emitter<StockState> emit,
  ) {
    emit(StockActive(
      stockData: event.stockData,
      itemDetails: event.itemDetails,
      weather: event.weather,
    ));
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
