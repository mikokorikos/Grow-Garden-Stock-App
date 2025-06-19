// Archivo: lib/presentation/bloc/stock/stock_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/exceptions.dart';
import '../../../domain/entities/item_info_entity.dart';
import '../../../domain/entities/stock_item_entity.dart';
import '../../../domain/usecases/get_all_items_info_usecase.dart';
import '../../../domain/usecases/listen_to_stock_updates_usecase.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final GetAllItemsInfoUseCase getAllItemsInfo;
  final ListenToStockUpdatesUseCase listenToStockUpdates;
  StreamSubscription? _stockSubscription;

  StockBloc({
    required this.getAllItemsInfo,
    required this.listenToStockUpdates,
  }) : super(StockInitial()) {
    on<SubscriptionRequested>(_onSubscriptionRequested);
    on<_StockUpdateReceived>(_onStockUpdateReceived);
  }

  Future<void> _onSubscriptionRequested(
    SubscriptionRequested event,
    Emitter<StockState> emit,
  ) async {
    await _stockSubscription?.cancel();
    emit(StockLoadingDetails());

    try {
      final itemDetails = await getAllItemsInfo();

      // Una vez tenemos los detalles, empezamos a escuchar el WebSocket.
      _stockSubscription = listenToStockUpdates().listen(
        (stockData) {
          add(_StockUpdateReceived(stockData));
        },
        onError: (error) => emit(
            const StockError("Error en la conexión con el servidor de stock.")),
      );

      // Emitimos un estado inicial con los detalles pero sin datos de stock aún.
      emit(StockListening(stockData: const {}, itemDetails: itemDetails));
    } on ServerException {
      emit(const StockError(
          "No se pudieron cargar los detalles de los artículos."));
    } catch (e) {
      emit(const StockError("Ocurrió un error inesperado."));
    }
  }

  void _onStockUpdateReceived(
    _StockUpdateReceived event,
    Emitter<StockState> emit,
  ) {
    if (state is StockListening) {
      final currentState = state as StockListening;
      // Emitimos un nuevo estado con el nuevo stock, pero manteniendo los detalles que ya teníamos.
      emit(StockListening(
          stockData: event.stockData, itemDetails: currentState.itemDetails));
    }
  }

  @override
  Future<void> close() {
    _stockSubscription?.cancel();
    return super.close();
  }
}
