import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart'; // Importar logger
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/usecases/get_all_items_info_usecase.dart';
import 'sniper_event.dart';
import 'sniper_state.dart';

class SniperBloc extends Bloc<SniperEvent, SniperState> {
  final GetAllItemsInfoUseCase _getAllItemsInfoUseCase;
  final SniperRepository _sniperRepository;
  final String _className = "SniperBloc"; // Para logging

  SniperBloc({
    required GetAllItemsInfoUseCase getAllItemsInfoUseCase,
    required SniperRepository sniperRepository,
  })  : _getAllItemsInfoUseCase = getAllItemsInfoUseCase,
        _sniperRepository = sniperRepository,
        super(SniperInitial()) {
    on<LoadSniperData>(_onLoadSniperData);
    on<ToggleSniperItem>(_onToggleSniperItem);
  }

  Future<void> _onLoadSniperData(
    LoadSniperData event,
    Emitter<SniperState> emit,
  ) async {
    final methodName = "$_className._onLoadSniperData";
    logI("[$methodName] Cargando datos de sniper...");
    emit(SniperLoading());
    try {
      logD("[$methodName] Obteniendo información de todos los items y lista de sniper en paralelo...");
      // Ambas llamadas pueden lanzar AppException o CacheException (para sniperRepository)
      final results = await Future.wait([
        _getAllItemsInfoUseCase(), // Puede lanzar ServerException, NetworkException, ParsingException
        _sniperRepository.loadSniperList(), // Puede lanzar CacheException
      ]);

      // Es importante verificar los tipos después de Future.wait si no estás seguro.
      // Sin embargo, _getAllItemsInfoUseCase ya devuelve Map<String, ItemInfoEntity>
      // y _sniperRepository.loadSniperList() devuelve List<String>.
      final allItemsMap = results[0] as Map<String, ItemInfoEntity>;
      final selectedIds = (results[1] as List<String>).toSet();
      final allItems = allItemsMap.values.toList();

      final groupedItems = <String, List<ItemInfoEntity>>{
        'Seeds & Produce': [], 'Gear & Tools': [], 'Eggs': [], 'Cosmetics & Decor': [], 'Events & Special': [],
      };

      for (final item in allItems) {
        final name = item.name.toLowerCase();
        final rarity = item.rarity.toLowerCase();

        if (name.contains('egg')) { groupedItems['Eggs']!.add(item); } 
        else if (name.contains('sprinkler') || name.contains('trowel') || name.contains('wrench') || name.contains('tool') || name.contains('can') || name.contains('spray')) { groupedItems['Gear & Tools']!.add(item); } 
        else if (name.contains('gnome') || name.contains('crate') || name.contains('statue') || name.contains('bench') || name.contains('pillar') || name.contains('fence') || name.contains('lamp')) { groupedItems['Cosmetics & Decor']!.add(item); } 
        else if (rarity == 'divine' || rarity == 'prismatic' || rarity == 'mythical') { groupedItems['Events & Special']!.add(item); }
        else { groupedItems['Seeds & Produce']!.add(item); }
      }
      
      groupedItems.forEach((key, value) => value.sort((a, b) => a.name.compareTo(b.name)));
      groupedItems.removeWhere((key, value) => value.isEmpty);

      logI("[$methodName] Datos de sniper cargados y procesados exitosamente. ${allItems.length} items en total, ${selectedIds.length} seleccionados.");
      emit(SniperLoaded(
        allItemsByCategory: groupedItems,
        selectedItemIds: selectedIds,
      ));
    } on AppException catch (e, s) {
      logE("[$methodName] AppException al cargar datos de sniper: ${e.message}", error: e, stackTrace: s);
      emit(SniperError("Error al cargar datos de sniper: ${e.message}"));
    } catch (e, s) {
      logE("[$methodName] Excepción no controlada al cargar datos de sniper", error: e, stackTrace: s);
      emit(SniperError("Ocurrió un error inesperado al cargar los items: ${e.toString()}"));
    }
  }

  Future<void> _onToggleSniperItem(
    ToggleSniperItem event,
    Emitter<SniperState> emit,
  ) async {
    final methodName = "$_className._onToggleSniperItem";
    if (state is SniperLoaded) {
      final currentState = state as SniperLoaded;
      final currentSelectedIds = Set<String>.from(currentState.selectedItemIds);

      if (event.isSelected) {
        currentSelectedIds.add(event.itemId);
        logD("[$methodName] Item ${event.itemId} añadido a la lista de sniper.");
      } else {
        currentSelectedIds.remove(event.itemId);
        logD("[$methodName] Item ${event.itemId} removido de la lista de sniper.");
      }
      
      emit(currentState.copyWith(selectedItemIds: currentSelectedIds));
      
      final updatedList = currentSelectedIds.toList();
      try {
        await _sniperRepository.saveSniperList(updatedList);
        logI("[$methodName] Lista de sniper (${updatedList.length} items) guardada en el repositorio.");

        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          logD("[$methodName] Enviando lista de sniper actualizada (${updatedList.length} items) al servicio de fondo...");
          service.invoke('updateSniperList', {'sniper_list': updatedList});
        } else {
          logW("[$methodName] El servicio de fondo no está corriendo. No se envió la lista de sniper.");
        }
      } on CacheException catch (e,s) {
        logE("[$methodName] CacheException al guardar la lista de sniper. La UI puede mostrar un estado no persistido para ${event.itemId}.", error: e, stackTrace: s);
        emit(SniperError("Error al guardar tu selección de sniper: ${e.message}. Por favor, intenta de nuevo."));
      } catch (e, s) {
        logE("[$methodName] Excepción no controlada al guardar/enviar lista de sniper para ${event.itemId}.", error: e, stackTrace: s);
        emit(SniperError("Ocurrió un error inesperado al actualizar tu selección: ${e.toString()}"));
      }
    } else {
      logW("[$methodName] Se intentó hacer toggle para ${event.itemId} pero el estado no es SniperLoaded. Estado actual: $state");
    }
  }

  @override
  Future<void> close() {
    logI("[$_className] close() llamado.");
    return super.close();
  }
}
