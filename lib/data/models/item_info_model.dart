import '../../domain/entities/item_info_entity.dart';
import '../../core/utils/logger.dart'; // Importar logger
import '../../core/error/exceptions.dart'; // Importar ParsingException

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
    final className = "ItemInfoModel";
    try {
      // logV('[$className.fromJson] Parseando item: ${json['display_name']}');

      String rarityValue = 'Común'; // Default
      if (json['rarity'] != null && json['rarity'].toString().isNotEmpty) {
        rarityValue = json['rarity'].toString();
      }

      String priceValue = '0'; // Default
      if (json['price'] != null) {
          priceValue = json['price'].toString();
      }

      return ItemInfoModel(
        name: json['display_name']?.toString() ?? 'Nombre Desconocido',
        rarity: rarityValue,
        image: json['icon']?.toString() ?? '', // Asumimos que 'icon' es la URL de la imagen
        price: priceValue,
        currency: json['currency']?.toString() ?? 'Sheckles',
        description: json['description']?.toString() ?? 'Sin descripción.',
      );
    } catch (e, s) {
      logE('[$className.fromJson] Error al parsear ItemInfoModel. JSON: $json', error: e, stackTrace: s);
      throw ParsingException('Error al parsear ItemInfoModel: ${e.toString()}');
    }
  }
}
