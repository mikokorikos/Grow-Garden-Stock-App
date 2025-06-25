import '../../domain/entities/stock_item_entity.dart';
import '../../core/utils/logger.dart'; // Importar logger
import '../../core/error/exceptions.dart'; // Importar ParsingException (si no está ya)


class StockItemModel extends StockItemEntity {
  const StockItemModel({
    required super.id,
    required super.displayName,
    required super.quantity,
    required super.iconUrl,
    required super.endDate,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    final className = "StockItemModel";
    try {
      // logV('[$className.fromJson] Parseando: $json'); // Nivel Verbose/Trace para logs muy detallados

      // Validación de campos críticos. Si 'item_id' es absolutamente esencial y no tiene un default válido.
      // if (json['item_id'] == null || (json['item_id'] is String && json['item_id'].isEmpty)) {
      //   throw ParsingException("El campo 'item_id' es nulo o vacío en StockItemModel.");
      // }

      final num quantityAsNum = json['quantity'] ?? 0;
      final int endDateUnix = (json['end_date_unix'] ?? 0) is int
          ? json['end_date_unix']
          : int.tryParse(json['end_date_unix'].toString()) ?? 0;


      return StockItemModel(
        id: json['item_id']?.toString() ?? '', // Asegurar que sea String
        displayName: json['display_name']?.toString() ?? 'N/A', // Asegurar que sea String
        quantity: quantityAsNum.toInt(),
        iconUrl: json['icon']?.toString() ?? '', // Asegurar que sea String
        endDate: DateTime.fromMillisecondsSinceEpoch(endDateUnix * 1000),
      );
    } catch (e, s) {
      logE('[$className.fromJson] Error al parsear StockItemModel. JSON: $json', error: e, stackTrace: s);
      throw ParsingException('Error al parsear StockItemModel: ${e.toString()}');
    }
  }
}