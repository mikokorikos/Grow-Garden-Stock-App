// Archivo: lib/core/api/api_constants.dart
class ApiConstants {
  // Al añadir 'static', podemos acceder a estas variables desde cualquier
  // parte de la app usando ApiConstants.baseUrl, sin necesidad de crear
  // una instancia de la clase.

  static const String baseUrl = 'https://api.joshlei.com/v2/growagarden';
  static const String stockEndpoint = '/stock';
  static const String weatherEndpoint = '/weather';
  static const String itemInfoEndpoint = '/info';
}
