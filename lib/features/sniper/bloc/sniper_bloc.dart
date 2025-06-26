import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart';
import 'package:grow_garden_tracker/core/utils/logger.dart';
import 'package:grow_garden_tracker/domain/entities/item_info_entity.dart';
import 'package:grow_garden_tracker/domain/usecases/get_all_items_info_usecase.dart';
import 'sniper_event.dart';
import 'sniper_state.dart';

class SniperBloc extends Bloc<SniperEvent, SniperState> {
  final GetAllItemsInfoUseCase _getAllItemsInfoUseCase;
  final SniperRepository _sniperRepository;
  final String _className = "SniperBloc";

  SniperBloc({
    required GetAllItemsInfoUseCase getAllItemsInfoUseCase,
    required SniperRepository sniperRepository,
  })  : _getAllItemsInfoUseCase = getAllItemsInfoUseCase,
        _sniperRepository = sniperRepository,
        super(SniperInitial()) {
    on<LoadSniperData>(_onLoadSniperData);
    on<ToggleSniperItem>(_onToggleSniperItem);

    // === INICIO DE LA CORRECCIÓN ===
    // Esta es la línea que faltaba. Le dice al BLoC qué hacer
    // cuando recibe un evento de tipo "SearchItems".
    on<SearchItems>(_onSearchItems);
    // === FIN DE LA CORRECCIÓN ===
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
        'Seeds & Produce': [],
        'Gear & Tools': [],
        'Eggs': [],
        'Cosmetics & Decor': [],
        'Events & Special': [],
      };

      for (final item in allItems) {
        final name = item.name.toLowerCase();
        final rarity = item.rarity.toLowerCase();

        if (name.contains('egg')) {
          groupedItems['Eggs']!.add(item);
        } else if (name.contains('sprinkler') ||
            name.contains('trowel') ||
            name.contains('wrench') ||
            name.contains('tool') ||
            name.contains('can') ||
            name.contains('spray')) {
          groupedItems['Gear & Tools']!.add(item);
        } else if (name.contains('gnome') ||
            name.contains('crate') ||
            name.contains('statue') ||
            name.contains('bench') ||
            name.contains('pillar') ||
            name.contains('fence') ||
            name.contains('lamp')) {
          groupedItems['Cosmetics & Decor']!.add(item);
        } else if (rarity == 'divine' ||
            rarity == 'prismatic' ||
            rarity == 'mythical') {
          groupedItems['Events & Special']!.add(item);
        } else {
          groupedItems['Seeds & Produce']!.add(item);
        }
      }

      groupedItems.forEach(
          (key, value) => value.sort((a, b) => a.name.compareTo(b.name)));
      groupedItems.removeWhere((key, value) => value.isEmpty);

      logI("[$_className] Datos de sniper cargados y procesados exitosamente.");

      emit(SniperLoaded(
        allItemsByCategory: groupedItems,
        filteredItemsByCategory: groupedItems,
        selectedItemIds: selectedIds,
      ));
    } on AppException catch (e, s) {
      logE("[$_className] AppException al cargar datos de sniper: ${e.message}",
          error: e, stackTrace: s);
      emit(SniperError("Error al cargar datos de sniper: ${e.message}"));
    } catch (e, s) {
      logE("[$_className] Excepción no controlada al cargar datos de sniper",
          error: e, stackTrace: s);
      emit(SniperError(
          "Ocurrió un error inesperado al cargar los items: ${e.toString()}"));
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

      // Creamos una copia del estado filtrado para no perder la búsqueda actual
      final currentFilteredState = currentState.filteredItemsByCategory;

      emit(currentState.copyWith(
          selectedItemIds: currentSelectedIds,
          filteredItemsByCategory: currentFilteredState));

      final updatedList = currentSelectedIds.toList();
      try {
        await _sniperRepository.saveSniperList(updatedList);
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('updateSniperList', {'sniper_list': updatedList});
        }
      } catch (e) {
        emit(SniperError("Error al guardar tu selección: ${e.toString()}"));
      }
    }
  }

  void _onSearchItems(SearchItems event, Emitter<SniperState> emit) {
    if (state is! SniperLoaded) return;

    final currentState = state as SniperLoaded;
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(currentState.copyWith(
          filteredItemsByCategory: currentState.allItemsByCategory));
      return;
    }

    final originalMap = currentState.allItemsByCategory;
    final filteredMap = <String, List<ItemInfoEntity>>{};

    originalMap.forEach((category, items) {
      final filteredItems = items.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();

      if (filteredItems.isNotEmpty) {
        filteredMap[category] = filteredItems;
      }
    });

    emit(currentState.copyWith(filteredItemsByCategory: filteredMap));
  }
}
