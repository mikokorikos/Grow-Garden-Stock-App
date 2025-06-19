import 'package:equatable/equatable.dart';

class StockItemEntity extends Equatable {
  final String id;
  final String displayName;
  final int quantity;
  final String iconUrl;
  final DateTime endDate;

  const StockItemEntity({
    required this.id,
    required this.displayName,
    required this.quantity,
    required this.iconUrl,
    required this.endDate,
  });

  @override
  List<Object?> get props => [id, displayName, quantity, iconUrl, endDate];
}
