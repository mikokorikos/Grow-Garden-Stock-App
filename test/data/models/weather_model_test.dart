import 'package:flutter_test/flutter_test.dart';
import 'package:grow_garden_tracker/data/models/weather_model.dart';
import 'package:grow_garden_tracker/core/error/exceptions.dart';

void main() {
  group('WeatherModel.fromJson', () {
    test('debería parsear correctamente un JSON válido', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "weather_name": "Sunny",
        "active": true,
        "icon": "http://example.com/sunny.png",
      };
      // Act
      final result = WeatherModel.fromJson(jsonMap);
      // Assert
      expect(result.name, "Sunny");
      expect(result.isActive, true);
      expect(result.iconUrl, "http://example.com/sunny.png");
    });

    test('debería usar valores por defecto para campos nulos', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "weather_name": null,
        "active": null,
        "icon": null,
      };
      // Act
      final result = WeatherModel.fromJson(jsonMap);
      // Assert
      expect(result.name, 'N/A');
      expect(result.isActive, false);
      expect(result.iconUrl, '');
    });

    test('debería parsear "active" como true para string "true" (insensible a mayúsculas)', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {"active": "TrUe"};
      // Act
      final result = WeatherModel.fromJson(jsonMap);
      // Assert
      expect(result.isActive, true);
    });

    test('debería parsear "active" como false para string "false"', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {"active": "false"};
      // Act
      final result = WeatherModel.fromJson(jsonMap);
      // Assert
      expect(result.isActive, false);
    });

    test('debería parsear "active" como true para número 1', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {"active": 1};
      // Act
      final result = WeatherModel.fromJson(jsonMap);
      // Assert
      expect(result.isActive, true);
    });

    test('debería parsear "active" como false para número 0', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {"active": 0};
      // Act
      final result = WeatherModel.fromJson(jsonMap);
      // Assert
      expect(result.isActive, false);
    });

    test('debería parsear "active" como false para string no booleano y número no 0/1', () {
      // Arrange
      final Map<String, dynamic> jsonMap1 = {"active": "not_bool"};
      final Map<String, dynamic> jsonMap2 = {"active": 2};
      // Act
      final result1 = WeatherModel.fromJson(jsonMap1);
      final result2 = WeatherModel.fromJson(jsonMap2);
      // Assert
      expect(result1.isActive, false);
      expect(result2.isActive, false);
    });

    test('debería convertir campos no-string a string con valores por defecto', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        "weather_name": 123,
        "active": true,
        "icon": true,
      };
      // Act
      final result = WeatherModel.fromJson(jsonMap);
      // Assert
      expect(result.name, '123');
      expect(result.iconUrl, 'true');
    });

    test('debería lanzar ParsingException si un campo inesperado causa error', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
         // Forzamos un error haciendo que 'active' sea un tipo no manejable por la lógica de conversión
         "active": {"complex_object": true},
      };
      // Act & Assert
      expect(() => WeatherModel.fromJson(jsonMap), throwsA(isA<ParsingException>()));
    });
  });
}
