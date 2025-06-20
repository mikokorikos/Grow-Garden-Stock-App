// Archivo: lib/data/models/stock_item_model.dart
import 'dart:developer' as developer;
import '../../domain/entities/stock_item_entity.dart';

class StockItemModel extends StockItemEntity {
  const StockItemModel({
    required super.id,
    required super.displayName,
    required super.quantity,
    required super.iconUrl,
    required super.endDate,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    developer.log('Parsing StockItem from JSON: $json', name: 'StockItemModel');
    return StockItemModel(
      id: json['item_id'] ?? '',
      displayName: json['display_name'] ?? 'N/A',
      quantity: json['quantity'] ?? 0,
      iconUrl: json['icon'] ?? '',
      // El timestamp de la API viene en segundos, lo convertimos a milisegundos
      endDate: DateTime.fromMillisecondsSinceEpoch(
          (json['end_date_unix'] ?? 0) * 1000),
    );
  }
}
