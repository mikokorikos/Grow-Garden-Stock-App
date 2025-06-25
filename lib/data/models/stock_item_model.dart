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
    debugPrint('[StockItemModel.fromJson] Parseando: $json');
    
    // --- LÓGICA DE CORRECCIÓN ---
    // El campo 'quantity' puede llegar como int o double desde la API.
    // Lo leemos como 'num' que es la clase padre de ambos (int y double).
    // Luego, lo convertimos a int de forma segura con .toInt().
    // Si es nulo, le asignamos 0 por defecto.
    final num quantityAsNum = json['quantity'] ?? 0;

    return StockItemModel(
      id: json['item_id'] ?? '',
      displayName: json['display_name'] ?? 'N/A',
      quantity: quantityAsNum.toInt(), // Convertimos a int de forma segura
      iconUrl: json['icon'] ?? '',
      endDate: DateTime.fromMillisecondsSinceEpoch(
          (json['end_date_unix'] ?? 0) * 1000),
    );
  }
}