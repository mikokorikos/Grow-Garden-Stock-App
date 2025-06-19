import '../../domain/entities/item_info_entity.dart';

class ItemInfoModel extends ItemInfoEntity {
  const ItemInfoModel({
    required super.name,
    required super.category,
    required super.rarity,
    required super.image,
    required super.buyPrice,
    required super.sellValue,
    required super.tradeable,
  });

  factory ItemInfoModel.fromJson(Map<String, dynamic> json) {
    return ItemInfoModel(
      name: json['name'] ?? 'N/A',
      category: json['category'] ?? 'N/A',
      rarity: json['metadata']?['tier'] ?? json['rarity'] ?? 'N/A',
      image: json['image'] ?? '',
      buyPrice: json['metadata']?['buyPrice']?.toString() ?? 'N/A',
      sellValue: json['metadata']?['sellValue']?.toString() ?? 'N/A',
      tradeable: json['metadata']?['tradeable'] ?? false,
    );
  }
}
