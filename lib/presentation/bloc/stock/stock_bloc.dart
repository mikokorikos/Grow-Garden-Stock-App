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

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final GetAllItemsInfoUseCase _getAllItemsInfoUseCase;
  StreamSubscription<Map<String, dynamic>?>? _stockSubscription;
  StreamSubscription<Map<String, dynamic>?>? _errorSubscription;
  StreamSubscription<Map<String, dynamic>?>? _alarmSubscription;

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

    emit(StockLoading());
    
    final service = FlutterBackgroundService();
    
    _stockSubscription = service.on('updateStock').listen((event) async {
      if (event != null) await _processServiceData(event);
    });

    _errorSubscription = service.on('persistent_error').listen((event) {
       if (event != null && event['message'] != null) {
         emit(StockError(event['message']));
       }
    });

    _alarmSubscription = service.on('sniperAlarm').listen((event) {
      if (event != null) {
        final items = List<String>.from(event['items'] ?? []);
        final colorHex = event['rarityColorHex'] as int?;
        if (items.isNotEmpty && colorHex != null) {
          emit(SniperAlarmTriggered(foundItems: items, rarityColor: Color(colorHex)));
        }
      }
    });

    if (await service.isRunning()) {
      service.invoke('requestInitialData');
    } else {
      emit(StockServiceInactive());
    }
  }

  // --- NUEVO MANEJADOR DE EVENTO ---
  void _onStopListeningToStockUpdates(
    StopListeningToStockUpdates event,
    Emitter<StockState> emit,
  ) {
    _cancelSubscriptions();
    emit(StockServiceInactive());
  }

  Future<void> _processServiceData(Map<String, dynamic> event) async {
    try {
      final rawStock = Map<String, dynamic>.from(event['stock'] ?? {});
      final rawWeather = List<dynamic>.from(event['weather'] ?? []);
      
      final stockData = <String, List<StockItemEntity>>{};
      rawStock.forEach((key, value) {
        if (value is List) {
          stockData[key] = value.map((item) => StockItemModel.fromJson(Map<String,dynamic>.from(item))).toList();
        }
      });

      final weatherData = rawWeather.map((item) => WeatherModel.fromJson(Map<String,dynamic>.from(item))).toList();
      final itemDetails = await _getAllItemsInfoUseCase();

      add(_StockDataReceived(stockData: stockData, weather: weatherData, itemDetails: itemDetails));
    } catch (e) {
      add(_StockProcessingFailed("Error al procesar los datos del stock: $e"));
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