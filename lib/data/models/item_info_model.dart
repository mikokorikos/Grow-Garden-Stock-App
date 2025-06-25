import 'package:flutter/foundation.dart';
import '../../domain/entities/item_info_entity.dart';

class ItemInfoModel extends ItemInfoEntity {
  const ItemInfoModel({
    required super.name,
    required super.rarity,
    required super.image,
    required super.price,
    required super.currency,
    required super.description,
  });

  factory ItemInfoModel.fromJson(Map<String, dynamic> json) {
    // El debugPrint es útil para ver qué se está parseando
    // debugPrint('[ItemInfoModel.fromJson] Parseando item: ${json['display_name']}');

    return ItemInfoModel(
      // *** AQUÍ ESTÁ LA CORRECCIÓN CLAVE ***
      // Leemos de 'display_name' en lugar de 'name'.
      name: json['display_name'] ?? 'Nombre Desconocido',

      // Asignamos valores por defecto si los campos son nulos o vacíos en la API
      rarity: (json['rarity'] == null || (json['rarity'] as String).isEmpty)
          ? 'Común'
          : json['rarity'],

      image: json['icon'] ?? '',
      price: json['price']?.toString() ?? '0',
      currency: json['currency'] ?? 'Sheckles',
      description: json['description'] ?? '',
    );
  }
}
