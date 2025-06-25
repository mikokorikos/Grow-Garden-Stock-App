import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/usecases/get_all_items_info_usecase.dart';
import 'sniper_event.dart';
import 'sniper_state.dart';

class SniperBloc extends Bloc<SniperEvent, SniperState> {
  final GetAllItemsInfoUseCase _getAllItemsInfoUseCase;
  final SniperRepository _sniperRepository;

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
    emit(SniperLoading());
    try {
      final results = await Future.wait([
        _getAllItemsInfoUseCase(),
        _sniperRepository.loadSniperList(),
      ]);

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

      emit(SniperLoaded(
        allItemsByCategory: groupedItems,
        selectedItemIds: selectedIds,
      ));
    } catch (e) {
      emit(SniperError("No se pudieron cargar los items: ${e.toString()}"));
    }
  }

  Future<void> _onToggleSniperItem(
    ToggleSniperItem event,
    Emitter<SniperState> emit,
  ) async {
    if (state is SniperLoaded) {
      final currentState = state as SniperLoaded;
      final currentSelectedIds = Set<String>.from(currentState.selectedItemIds);

      if (event.isSelected) {
        currentSelectedIds.add(event.itemId);
      } else {
        currentSelectedIds.remove(event.itemId);
      }
      
      emit(currentState.copyWith(selectedItemIds: currentSelectedIds));
      
      final updatedList = currentSelectedIds.toList();
      await _sniperRepository.saveSniperList(updatedList);

      // --- ¡AQUÍ ESTÁ LA NUEVA COMUNICACIÓN EN TIEMPO REAL! ---
      // Después de guardar, envía la lista actualizada al servicio.
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('updateSniperList', {'sniper_list': updatedList});
      }
    }
  }
}
