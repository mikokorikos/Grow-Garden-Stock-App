// Archivo: lib/data/models/weather_model.dart
import '../../domain/entities/weather_entity.dart';
import '../../core/utils/logger.dart'; // Importar logger
import '../../core/error/exceptions.dart'; // Importar ParsingException


class WeatherModel extends WeatherEntity {
  const WeatherModel({
    required super.name,
    required super.isActive,
    required super.iconUrl,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final className = "WeatherModel";
    try {
      // logV('[$className.fromJson] Parseando: $json');

      // El campo 'active' podría venir como booleano o como string "true"/"false" o int 0/1.
      // Hacemos un parseo más robusto.
      bool isActiveValue = false; // Default
      if (json['active'] != null) {
        if (json['active'] is bool) {
          isActiveValue = json['active'];
        } else if (json['active'] is String) {
          isActiveValue = json['active'].toLowerCase() == 'true';
        } else if (json['active'] is num) {
          isActiveValue = json['active'] == 1;
        }
      }

      return WeatherModel(
        name: json['weather_name']?.toString() ?? 'N/A',
        isActive: isActiveValue,
        iconUrl: json['icon']?.toString() ?? '',
      );
    } catch (e, s) {
      logE('[$className.fromJson] Error al parsear WeatherModel. JSON: $json', error: e, stackTrace: s);
      throw ParsingException('Error al parsear WeatherModel: ${e.toString()}');
    }
  }
}
