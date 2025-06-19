import 'package:equatable/equatable.dart';

class ItemInfoEntity extends Equatable {
  final String name;
  final String category;
  final String rarity;
  final String image;
  final String buyPrice;
  final String sellValue;
  final bool tradeable;

  const ItemInfoEntity({
    required this.name,
    required this.category,
    required this.rarity,
    required this.image,
    required this.buyPrice,
    required this.sellValue,
    required this.tradeable,
  });

  @override
  List<Object?> get props =>
      [name, category, rarity, image, buyPrice, sellValue, tradeable];
}
