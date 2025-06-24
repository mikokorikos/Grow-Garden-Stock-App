// Archivo: lib/data/models/stock_item_model.dart
import 'package:flutter/foundation.dart';
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
    // Log para ver el JSON crudo que se está parseando.
    debugPrint('[StockItemModel.fromJson] Parseando: $json');
    return StockItemModel(
      id: json['item_id'] ?? '',
      displayName: json['display_name'] ?? 'N/A',
      quantity: json['quantity'] ?? 0,
      iconUrl: json['icon'] ?? '',
      endDate: DateTime.fromMillisecondsSinceEpoch(
          (json['end_date_unix'] ?? 0) * 1000),
    );
  }
}
