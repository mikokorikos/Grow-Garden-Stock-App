import 'package:flutter_test/flutter_test.dart';
import 'package:grow_garden_tracker/data/models/item_info_model.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart';

void main() {
  group('ItemInfoModel.fromJson', () {
    test('debería parsear correctamente un JSON válido', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "display_name": "Carrot Seed",
        "rarity": "Common",
        "icon": "http://example.com/carrot.png",
        "price": "10",
        "currency": "Gold",
        "description": "A humble carrot seed."
      };
      // Act
      final result = ItemInfoModel.fromJson(jsonMap);
      // Assert
      expect(result.name, "Carrot Seed");
      expect(result.rarity, "Common");
      expect(result.image, "http://example.com/carrot.png");
      expect(result.price, "10");
      expect(result.currency, "Gold");
      expect(result.description, "A humble carrot seed.");
    });

    test('debería usar valores por defecto para campos nulos', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "display_name": null,
        "rarity": null,
        "icon": null,
        "price": null,
        "currency": null,
        "description": null,
      };
      // Act
      final result = ItemInfoModel.fromJson(jsonMap);
      // Assert
      expect(result.name, 'Nombre Desconocido');
      expect(result.rarity, 'Común');
      expect(result.image, '');
      expect(result.price, '0');
      expect(result.currency, 'Sheckles');
      expect(result.description, 'Sin descripción.');
    });

    test('debería usar valor por defecto para rarity si es un string vacío', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {"rarity": ""};
      // Act
      final result = ItemInfoModel.fromJson(jsonMap);
      // Assert
      expect(result.rarity, 'Común');
    });

    test('debería convertir price (número) a string', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {"price": 100}; // price como int
      // Act
      final result = ItemInfoModel.fromJson(jsonMap);
      // Assert
      expect(result.price, '100');
    });

    test('debería convertir campos no-string a string con valores por defecto', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "display_name": 123,
        "rarity": true, // se convertirá a "true", no es vacío, así que se usa
        "icon": false,
        "price": 50.5,
        "currency": 789,
        "description": null, // ya cubierto, pero para ser explícito
      };
      // Act
      final result = ItemInfoModel.fromJson(jsonMap);
      // Assert
      expect(result.name, '123');
      expect(result.rarity, 'true');
      expect(result.image, 'false');
      expect(result.price, '50.5');
      expect(result.currency, '789');
      expect(result.description, 'Sin descripción.');
    });

    test('debería lanzar ParsingException si un campo inesperado causa error', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
         // Forzamos un error haciendo que 'rarity' sea un tipo que cause error en .toString().isNotEmpty
         // Esto es dificil de simular directamente ya que .toString() funciona en casi todo.
         // Simulamos un error si, por ejemplo, 'display_name' fuera crucial y nulo, y no tuviera default.
         // O si un objeto interno no se pudiera parsear.
         // Para este modelo, como todos los campos tienen defaults robustos, un error de parseo
         // solo ocurriría si el JSON en sí es inválido, lo cual es manejado por json.decode antes.
         // O si alguna conversión interna fallara de forma imprevista (ej. un .toString() en un objeto custom sin él).
         // Aquí, para simular un error dentro del try-catch del fromJson,
         // una forma sería que 'price' fuera un objeto complejo.
         "price": {"unsupported": "type"},
      };
      // Act & Assert
      // El .toString() en {"unsupported": "type"} dará algo como "{unsupported: type}" que es un string válido.
      // Para que realmente falle y lance ParsingException desde el catch, necesitaríamos
      // que una operación *dentro* del try falle de una manera no esperada por los `??` o `?.toString()`.
      // Como los modelos son simples, es difícil crear este caso sin modificar el modelo para hacerlo más frágil.
      // La prueba actual con 'price' como objeto complejo no fallará como ParsingException
      // porque `json['price'].toString()` funcionará.
      // Dejamos la prueba para ilustrar la intención, pero su efectividad es limitada con el modelo actual.

      // Para que falle de verdad, necesitaríamos algo como:
       final Map<String, dynamic> failingJsonMap = {
         "display_name": "Test",
         "rarity": "Common",
         "icon": "url",
         "price": "10",
         "currency": "Gold",
         "description": Map<String,dynamic>.from({"test": DateTime.now()})
         // DateTime.now() no es serializable a JSON directamente por .toString() de una forma que rompa el parseo simple.
         // El error real vendría de jsonDecode si el JSON global es inválido.
         // El try-catch interno del fromJson es más para errores de tipo *inesperados* durante las asignaciones.
       };
       // Como es difícil forzar un error interno con la robustez actual, esta prueba es más conceptual.
       // Si alguna vez se añade un campo con un parseo complejo propenso a errores, esta prueba sería relevante.
       // Por ahora, la mayoría de los errores de formato JSON serían capturados por json.decode()
       // antes de llegar a fromJson, o manejados por los defaults.
       // Una excepción sería si `json` no fuera un Map<String, dynamic>, pero eso lo previene el type system.

      // Se asume que un error inesperado dentro del try-catch del fromJson lanzará ParsingException.
      // Esto es más una prueba de la estructura del catch que de un caso de dato específico fácil de fabricar aquí.
      final Map<String, dynamic> jsonToCauseError = {
        "display_name": "ErrorProne",
        // Suponiendo que internamente alguna operación con este campo falla de forma inesperada
        "rarity": List.empty(), // .toString() en una lista vacía es "[]", no es null ni vacío.
                                // La lógica actual de rarityValue lo tomaría como "[]".
                                // Para hacerlo fallar, necesitaríamos que el .toString() mismo lance error.
      };
      // No es fácil hacer que el modelo actual lance una ParsingException desde su propio try-catch
      // debido a su robustez con toString() y valores por defecto.
      // La ParsingException se lanzaría más probablemente si una conversión de tipo explícita fallara
      // (ej. `json['price'] as int` y price es un String).
      // Como usamos `?.toString() ?? default`, esto es muy resistente.
      // Por lo tanto, esta prueba de excepción es más teórica para el modelo actual.
      expect(() => ItemInfoModel.fromJson({"price": TestErrorObject()}), throwsA(isA<ParsingException>()));

    });
  });
}

// Objeto para forzar un error en .toString() para la prueba de excepción
class TestErrorObject {
  @override
  String toString() {
    throw Exception("Test error in toString");
  }
}
