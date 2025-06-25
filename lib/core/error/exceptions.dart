// Clase base para todas las excepciones personalizadas de la aplicación.
// Permite capturar cualquier excepción específica de la app con un solo `catch (e is AppException)`.
abstract class AppException implements Exception {
  final String _message;
  final String? _prefix; // Prefijo opcional para categorizar el error (ej. "Servidor: ")

  AppException([this._message = "", this._prefix]);

  @override
  String toString() {
    return "${_prefix ?? ''}$_message";
  }

  String get message => _message;
}

// Excepción para errores que ocurren durante la comunicación con un servidor remoto.
// Esto puede ser debido a errores HTTP (4xx, 5xx), problemas de conexión que no son de red, etc.
class ServerException extends AppException {
  ServerException([String message = "Error del servidor"]) : super(message, "Error del Servidor: ");
}

// Excepción para errores relacionados con la caché local (ej. SharedPreferences, SQLite).
class CacheException extends AppException {
  CacheException([String message = "Error de caché"]) : super(message, "Error de Caché: ");
}

// Excepción para errores que ocurren durante el parseo de datos (ej. JSON mal formado).
class ParsingException extends AppException {
  ParsingException([String message = "Error al procesar los datos"]) : super(message, "Error de Parseo: ");
}

// Excepción para errores de red (ej. sin conexión a internet, DNS no resuelto).
class NetworkException extends AppException {
  NetworkException([String message = "Error de red, verifica tu conexión"]) : super(message, "Error de Red: ");
}

// Excepción para errores cuando se espera un dato pero no se encuentra.
class NotFoundException extends AppException {
  NotFoundException([String message = "No se encontró el recurso solicitado"]) : super(message, "No Encontrado: ");
}

// Excepción genérica para errores de autenticación o autorización.
class UnauthorizedException extends AppException {
  UnauthorizedException([String message = "No autorizado"]) : super(message, "Error de Autorización: ");
}

// Excepción para errores durante operaciones de entrada/salida (I/O).
class IOException extends AppException {
  IOException([String message = "Error de entrada/salida"]) : super(message, "Error de I/O: ");
}