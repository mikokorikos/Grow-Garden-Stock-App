import 'package:logger/logger.dart';

// Configuración del Logger
// Se puede personalizar el printer, output, level, etc.
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 1, // Número de métodos de la pila de llamadas a mostrar
    errorMethodCount: 8, // Número de métodos de la pila para errores
    lineLength: 120, // Ancho de la línea
    colors: true, // Colores en la consola
    printEmojis: true, // Imprimir emojis para los niveles de log
    printTime: true, // Imprimir hora del log
  ),
  // Se puede cambiar el nivel mínimo de log para producción vs desarrollo
  // Por ejemplo, Level.warning para producción, Level.debug para desarrollo.
  // filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(), // Esto requeriría importar 'package:flutter/foundation.dart';
  filter: DevelopmentFilter(), // Por ahora, siempre en modo desarrollo para ver todos los logs
);

// Ejemplo de cómo se podría usar un filtro más avanzado si kDebugMode estuviera disponible
// class MyFilter extends LogFilter {
//   @override
//   bool shouldLog(LogEvent event) {
//     if (kReleaseMode) { // Asumiendo que kReleaseMode está disponible
//       return event.level.index >= Level.warning.index;
//     }
//     return true;
//   }
// }

void logD(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.d(message, error: error, stackTrace: stackTrace);
}

void logI(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.i(message, error: error, stackTrace: stackTrace);
}

void logW(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.w(message, error: error, stackTrace: stackTrace);
}

void logE(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.e(message, error: error, stackTrace: stackTrace);
}

void logV(String message, {dynamic error, StackTrace? stackTrace}) {
  // 'v' es para verbose, el nivel más bajo en el paquete logger
  logger.t(message, error: error, stackTrace: stackTrace); // 't' es el alias de 'trace' que es el más bajo
}

// Si quieres un nivel WTF (What a Terrible Failure)
void logWtf(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.f(message, error: error, stackTrace: stackTrace); // 'f' es para fatal
}
