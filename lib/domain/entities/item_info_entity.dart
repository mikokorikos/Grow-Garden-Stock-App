import 'package:equatable/equatable.dart';

class ItemInfoEntity extends Equatable {
  final String name;
  final String rarity;
  final String image;
  final String price;
  final String currency;
  final String description;

  const ItemInfoEntity({
    required this.name,
    required this.rarity,
    required this.image,
    required this.price,
    required this.currency,
    required this.description,
  });

  @override
  List<Object?> get props =>
      [name, rarity, image, price, currency, description];
}
