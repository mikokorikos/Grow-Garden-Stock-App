import 'dart:async';
import 'dart:io';

// Este es un programa de Dart puro, independiente de Flutter,
// para probar la conexión WebSocket de la forma más directa posible.

void main() async {
  final url = 'wss://websocket.joshlei.com/growagarden/';
  final headers = {
    // Usamos el mismo User-Agent para imitar un navegador,
    // eliminando posibles bloqueos del servidor.
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
  };

  print('[TEST] Iniciando prueba de conexión WebSocket...');
  print('[TEST] URL: $url');

  try {
    // 1. Intento de Conexión
    // Usamos el WebSocket nativo de dart:io, igual que en la última
    // versión de la app. Le damos 15 segundos para conectar.
    print('[TEST] Intentando conectar (timeout de 15s)...');
    final socket = await WebSocket.connect(url, headers: headers)
        .timeout(const Duration(seconds: 15));

    // Si el código llega aquí, la conexión fue exitosa.
    print('[TEST] ✅ CONEXIÓN ESTABLECIDA CON ÉXITO.');
    print('[TEST] Escuchando mensajes del servidor...');

    // 2. Escucha de Eventos
    // Nos suscribimos a los eventos del socket.
    final subscription = socket.listen(
      (message) {
        // Este bloque se ejecuta cada vez que llega un mensaje.
        print('----------------------------------------------------');
        print('[TEST] ✅ MENSAJE RECIBIDO:');
        print(message);
        print('----------------------------------------------------');
      },
      onError: (error) {
        // Este bloque se ejecuta si hay un error en la comunicación.
        print('[TEST] ❌ ERROR EN EL STREAM: $error');
      },
      onDone: () {
        // Este bloque se ejecuta cuando el servidor cierra la conexión.
        print('[TEST] 🚪 CONEXIÓN CERRADA POR EL SERVIDOR.');
      },
    );

    // 3. Mantener el Script Activo
    // Mantenemos el script corriendo por 60 segundos para recibir mensajes.
    print(
        '[TEST] El script se mantendrá activo por 60 segundos para recibir datos...');
    await Future.delayed(const Duration(seconds: 60));

    // 4. Cierre Limpio
    print('[TEST] Tiempo de prueba finalizado. Cerrando conexión.');
    await subscription.cancel();
    await socket.close();
  } on TimeoutException {
    print(
        '[TEST] ❌ ERROR: La conexión inicial superó el tiempo de espera de 15 segundos (Timeout).');
  } catch (e) {
    print('[TEST] ❌ EXCEPCIÓN INESPERADA AL CONECTAR: $e');
  } finally {
    print('[TEST] Prueba finalizada.');
    // Aseguramos que el script termine.
    exit(0);
  }
}
