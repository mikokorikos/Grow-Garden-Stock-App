import 'dart:async';
import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/entities/stock_item_entity.dart';
import 'package:grow_garden_tracker/domain/entities/weather_entity.dart';
import 'package:grow_garden_tracker/data/models/stock_item_model.dart';
import 'package:grow_garden_tracker/data/models/weather_model.dart';
import 'package:grow_garden_tracker/domain/usecases/get_all_items_info_usecase.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart'; // Importar logger

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final GetAllItemsInfoUseCase _getAllItemsInfoUseCase;
  final String _className = "StockBloc"; // Para logging
  StreamSubscription<Map<String, dynamic>?>? _stockSubscription;
  StreamSubscription<Map<String, dynamic>?>? _errorSubscription;
  StreamSubscription<Map<String, dynamic>?>? _alarmSubscription;
  bool _isProcessingStockData = false; // Flag para evitar procesamiento concurrente

  StockBloc({
    required GetAllItemsInfoUseCase getAllItemsInfoUseCase,
  })  : _getAllItemsInfoUseCase = getAllItemsInfoUseCase,
        super(StockInitial()) {
    on<ListenToStockUpdates>(_onListenToStockUpdates);
    // --- AÑADE EL MANEJADOR PARA EL NUEVO EVENTO ---
    on<StopListeningToStockUpdates>(_onStopListeningToStockUpdates);
    on<_StockDataReceived>(_onStockDataReceived);
    on<_StockProcessingFailed>((event, emit) => emit(StockError(event.errorMessage)));
  }

  // --- NUEVO MÉTODO PARA CANCELAR SUSCRIPCIONES ---
  void _cancelSubscriptions() {
    logI("[$_className] Cancelando suscripciones...");
    _stockSubscription?.cancel();
    _errorSubscription?.cancel();
    _alarmSubscription?.cancel();
    _stockSubscription = null;
    _errorSubscription = null;
    _alarmSubscription = null;
  }

  void _onListenToStockUpdates(
    ListenToStockUpdates event,
    Emitter<StockState> emit,
  ) async {
    // Primero, cancela cualquier suscripción existente para empezar de cero.
    _cancelSubscriptions();
    final methodName = "$_className._onListenToStockUpdates";
    logI("[$methodName] Iniciando escucha de actualizaciones de stock...");

    emit(StockLoading());
    
    final service = FlutterBackgroundService();
    
    // Suscripción a actualizaciones de stock
    _stockSubscription = service.on('updateStock').listen(
      (eventData) async {
        if (_isProcessingStockData) {
          logW("[$methodName] Stock data processing already in progress, skipping new 'updateStock' event.");
          return;
        }
        _isProcessingStockData = true;
        try {
          if (eventData != null) {
            logD("[$methodName] Datos de 'updateStock' recibidos del servicio: $eventData");
            await _processServiceData(eventData, emit);
          } else {
            logW("[$methodName] Evento 'updateStock' nulo recibido.");
          }
        } finally {
          _isProcessingStockData = false;
        }
      },
      onError: (error, stackTrace) {
        _isProcessingStockData = false; // Asegurar que el flag se resetea en caso de error en el stream
        logE("[$methodName] ERROR en stream 'updateStock'", error: error, stackTrace: stackTrace);
        emit(StockError("Error en la comunicación con el servicio de fondo (stock): ${error.toString()}"));
      }
    );

    // Suscripción a errores persistentes del servicio
    _errorSubscription = service.on('persistent_error').listen(
      (eventData) { // Renombrado event a eventData
       if (eventData != null && eventData['message'] != null) {
         logW("[$methodName] 'persistent_error' recibido: ${eventData['message']}");
         emit(StockError(eventData['message']));
       } else {
         logW("[$methodName] Evento 'persistent_error' nulo o sin mensaje.");
       }
      },
      onError: (error, stackTrace) {
        logE("[$methodName] ERROR en stream 'persistent_error'", error: error, stackTrace: stackTrace);
        emit(StockError("Error en la comunicación con el servicio de fondo (errores): ${error.toString()}"));
      }
    );

    // Suscripción a alarmas de sniper
    _alarmSubscription = service.on('sniperAlarm').listen(
      (eventData) { // Renombrado event a eventData
      if (eventData != null) {
        final items = List<String>.from(eventData['items'] ?? []);
        final colorHex = eventData['rarityColorHex'] as int?;
        if (items.isNotEmpty && colorHex != null) {
          logI("[$methodName] 'sniperAlarm' recibido para items: $items");
          emit(SniperAlarmTriggered(foundItems: items, rarityColor: Color(colorHex)));
        } else {
          logW("[$methodName] Evento 'sniperAlarm' incompleto: items o colorHex faltantes. Data: $eventData");
        }
      } else {
        logW("[$methodName] Evento 'sniperAlarm' nulo recibido.");
      }
      },
      onError: (error, stackTrace) {
        logE("[$methodName] ERROR en stream 'sniperAlarm'", error: error, stackTrace: stackTrace);
        emit(StockError("Error en la comunicación con el servicio de fondo (alarma): ${error.toString()}"));
      }
    );

    // Solicitar datos iniciales si el servicio está corriendo
    try {
      if (await service.isRunning()) {
        logI("[$methodName] El servicio está corriendo. Solicitando datos iniciales...");
        service.invoke('requestInitialData');
      } else {
        logW("[$methodName] El servicio no está corriendo. Emitiendo StockServiceInactive.");
        emit(StockServiceInactive());
      }
    } catch (e, s) {
        logE("[$methodName] ERROR al verificar el estado del servicio o al invocar 'requestInitialData'", error: e, stackTrace: s);
        emit(StockError("No se pudo comunicar con el servicio de fondo: ${e.toString()}"));
    }
  }

  // --- NUEVO MANEJADOR DE EVENTO ---
  void _onStopListeningToStockUpdates(
    StopListeningToStockUpdates event,
    Emitter<StockState> emit,
  ) {
    final methodName = "$_className._onStopListeningToStockUpdates";
    logI("[$methodName] Deteniendo escucha de actualizaciones de stock.");
    _cancelSubscriptions();
    emit(StockServiceInactive()); // O quizás StockInitial() si es más apropiado
  }

  Future<void> _processServiceData(Map<String, dynamic> eventData, Emitter<StockState> emit) async { // Renombrado event a eventData
    final methodName = "$_className._processServiceData";
    logD("[$methodName] Procesando datos recibidos del servicio: $eventData");
    try {
      final rawStock = Map<String, dynamic>.from(eventData['stock'] ?? {});
      final rawWeather = List<dynamic>.from(eventData['weather'] ?? []);
      
      final stockData = <String, List<StockItemEntity>>{};
      rawStock.forEach((key, value) {
        if (value is List) {
          try {
            stockData[key] = value.map((item) => StockItemModel.fromJson(Map<String,dynamic>.from(item))).toList();
          } catch (e,s) {
            logE("[$methodName] ERROR al parsear un item de stock en la categoría '$key'. Item: $value", error: e, stackTrace: s);
          }
        }
      });

      final weatherData = <WeatherEntity>[];
      for (var item in rawWeather) {
        try {
          weatherData.add(WeatherModel.fromJson(Map<String,dynamic>.from(item)));
        } catch (e,s) {
          logE("[$methodName] ERROR al parsear un item de clima. Item: $item", error: e, stackTrace: s);
        }
      }

      logD("[$methodName] Obteniendo detalles de items...");
      final itemDetails = await _getAllItemsInfoUseCase();
      logI("[$methodName] Detalles de items obtenidos. Emitiendo _StockDataReceived.");
      _onStockDataReceived(_StockDataReceived(stockData: stockData, weather: weatherData, itemDetails: itemDetails), emit);

    } on AppException catch (e, s) {
      logE("[$methodName] AppException durante el procesamiento de datos o llamada a use case: ${e.message}", error: e, stackTrace: s);
      emit(StockError(e.toString()));
    } catch (e, s) {
      logE("[$methodName] Excepción genérica durante el procesamiento de datos", error: e, stackTrace: s);
      emit(StockError("Error interno al procesar datos del stock: ${e.toString()}"));
    }
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
    _cancelSubscriptions(); // Asegúrate de llamar al nuevo método aquí también
    return super.close();
  }
}