import 'package:equatable/equatable.dart';

class WeatherEntity extends Equatable {
  final String name;
  final bool isActive;
  final String iconUrl;

  const WeatherEntity({
    required this.name,
    required this.isActive,
    required this.iconUrl,
  });

  @override
  List<Object?> get props => [name, isActive, iconUrl];
}
