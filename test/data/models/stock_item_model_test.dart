import 'package:flutter_test/flutter_test.dart';
import 'package:grow_garden_tracker/data/models/stock_item_model.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart'; // Para ParsingException

void main() {
  group('StockItemModel.fromJson', () {
    final DateTime mockDate = DateTime.fromMillisecondsSinceEpoch(1678886400000); // Ejemplo: 15 Mar 2023 12:00:00 GMT
    final int mockDateUnix = mockDate.millisecondsSinceEpoch ~/ 1000;

    test('debería parsear correctamente un JSON válido', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "item_id": "test_id_1",
        "display_name": "Test Item 1",
        "quantity": 100,
        "icon": "http://example.com/icon1.png",
        "end_date_unix": mockDateUnix,
      };
      // Act
      final result = StockItemModel.fromJson(jsonMap);
      // Assert
      expect(result.id, "test_id_1");
      expect(result.displayName, "Test Item 1");
      expect(result.quantity, 100);
      expect(result.iconUrl, "http://example.com/icon1.png");
      expect(result.endDate, mockDate);
    });

    test('debería usar valores por defecto para campos nulos', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "item_id": null,
        "display_name": null,
        "quantity": null,
        "icon": null,
        "end_date_unix": null,
      };
      // Act
      final result = StockItemModel.fromJson(jsonMap);
      // Assert
      expect(result.id, '');
      expect(result.displayName, 'N/A');
      expect(result.quantity, 0);
      expect(result.iconUrl, '');
      expect(result.endDate, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('debería manejar quantity como double y convertir a int', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "item_id": "test_id_2",
        "display_name": "Test Item 2",
        "quantity": 50.5, // quantity como double
        "icon": "http://example.com/icon2.png",
        "end_date_unix": mockDateUnix,
      };
      // Act
      final result = StockItemModel.fromJson(jsonMap);
      // Assert
      expect(result.quantity, 50); // Debería truncar a int
    });

    test('debería manejar end_date_unix como string numérico', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "item_id": "test_id_3",
        "display_name": "Test Item 3",
        "quantity": 75,
        "icon": "http://example.com/icon3.png",
        "end_date_unix": mockDateUnix.toString(), // end_date_unix como String
      };
      // Act
      final result = StockItemModel.fromJson(jsonMap);
      // Assert
      expect(result.endDate, mockDate);
    });

    test('debería convertir campos no-string a string con valores por defecto', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "item_id": 123, // item_id como int
        "display_name": true, // display_name como bool
        "quantity": 10,
        "icon": 456, // icon como int
        "end_date_unix": mockDateUnix,
      };
      // Act
      final result = StockItemModel.fromJson(jsonMap);
      // Assert
      expect(result.id, '123');
      expect(result.displayName, 'true');
      expect(result.iconUrl, '456');
    });

    test('debería lanzar ParsingException si un campo inesperado causa error (simulación)', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "item_id": "valid_id",
        "display_name": "Valid Name",
        // 'quantity' se fuerza a un tipo que cause error en toInt() después de '?? 0'
        // Esto es difícil de simular directamente porque '?? 0' ya lo maneja.
        // Pero si 'quantityAsNum.toInt()' fallara por alguna razón exótica no cubierta
        // o si otro campo tuviera un parseo más complejo que fallara.
        // Para el test, vamos a simular un error interno en el try-catch del fromJson
        // pasando un tipo incorrecto para end_date_unix que no sea manejado por tryParse
         "quantity": 10,
         "end_date_unix": {"unexpected_type": true}, // Esto causará un error
      };
      // Act & Assert
      expect(() => StockItemModel.fromJson(jsonMap), throwsA(isA<ParsingException>()));
    });

    test('debería usar valor por defecto para end_date_unix si es un string no numérico', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "item_id": "test_id_4",
        "display_name": "Test Item 4",
        "quantity": 10,
        "icon": "url",
        "end_date_unix": "not_a_number",
      };
      // Act
      final result = StockItemModel.fromJson(jsonMap);
      // Assert
      expect(result.endDate, DateTime.fromMillisecondsSinceEpoch(0));
    });

  });
}
