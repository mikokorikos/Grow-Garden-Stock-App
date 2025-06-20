import '../../domain/entities/weather_entity.dart';

class WeatherModel extends WeatherEntity {
  const WeatherModel({
    required super.name,
    required super.isActive,
    required super.iconUrl,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      name: json['weather_name'] ?? 'N/A',
      isActive: json['active'] ?? false,
      iconUrl: json['icon'] ?? '',
    );
  }
}
