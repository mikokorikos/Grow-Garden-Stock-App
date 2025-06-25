import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SniperRepository {
  static const _sniperListKey = 'sniper_list';

  Future<void> saveSniperList(List<String> itemIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_sniperListKey, itemIds);
      debugPrint(
          '[SniperRepository] Lista de sniper guardada con ${itemIds.length} items.');
    } catch (e) {
      debugPrint('[SniperRepository] Error al guardar la lista: $e');
    }
  }

  Future<List<String>> loadSniperList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_sniperListKey);
      if (savedList != null) {
        debugPrint(
            '[SniperRepository] Lista de sniper cargada con ${savedList.length} items.');
        return savedList;
      }
      return [];
    } catch (e) {
      debugPrint('[SniperRepository] Error al cargar la lista: $e');
      return [];
    }
  }
}
