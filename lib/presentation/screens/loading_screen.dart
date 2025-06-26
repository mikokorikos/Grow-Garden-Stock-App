import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:grow_garden_tracker/data/datasources/item_info_rest_data_source.dart';
import 'package:grow_garden_tracker/data/repositories/item_info_repository_impl.dart';
import 'package:grow_garden_tracker/presentation/screens/home_screen.dart';
import 'package:http/http.dart' as http;

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  // Controllers para diferentes animaciones
  late AnimationController _mainController;
  late AnimationController _beeController;
  late AnimationController _particleController;

  // Animaciones principales
  late Animation<double> _growthAnimation;
  late Animation<double> _beeAnimation;
  late Animation<double> _particleAnimation;

  // Estado para el texto y progreso
  String _statusMessage = "Despertando al jardín...";
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  void _initializeAnimations() {
    // El controlador principal ahora se manejará dinámicamente
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 600), // Duración de la transición de la barra
    );

    _beeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _growthAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOutCubic,
    );

    _beeAnimation = CurvedAnimation(
      parent: _beeController,
      curve: Curves.linear,
    );

    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );
  }

  void _startLoadingSequence() async {
    // Iniciar animaciones de ambiente
    _beeController.repeat();
    _particleController.repeat();

    // --- Lógica de Carga Real ---
    final client = http.Client();
    final itemInfoDataSource = ItemInfoRestDataSourceImpl(client: client);
    final itemInfoRepository =
        ItemInfoRepositoryImpl(itemInfoDataSource: itemInfoDataSource);

    try {
      // Paso 1: Descargar información de items y guardar en caché de datos (Hive)
      await _updateProgress(0.1, "Plantando semillas de datos...");
      final allItemsMap =
          await itemInfoRepository.getAllItemsInfo(forceRefresh: true);
      final allItems = allItemsMap.values.toList();
      await _updateProgress(0.4, "Catálogo de items cosechado...");
      await Future.delayed(const Duration(milliseconds: 300));

      // Paso 2: Descargar y guardar en caché de imágenes
      await _updateProgress(0.5, "Regando las imágenes...");
      final cacheManager = DefaultCacheManager();
      int totalImages = allItems.length;
      int cachedImages = 0;

      for (final item in allItems) {
        if (item.image.isNotEmpty) {
          try {
            await cacheManager.downloadFile(item.image, authHeaders: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
            });
          } catch (e) {
            debugPrint(
                "No se pudo cachear la imagen: ${item.image}. Error: $e");
          }
        }
        cachedImages++;
        final progress = 0.5 + (0.4 * (cachedImages / totalImages));
        await _updateProgress(
            progress, "Cosechando imágenes... ($cachedImages/$totalImages)");
      }

      // Paso 3: Finalización
      await _updateProgress(1.0, "¡El jardín está listo!");
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      await _updateProgress(1.0, "Error al preparar el jardín...");
      debugPrint("Error durante la pre-carga: $e");
      await Future.delayed(const Duration(seconds: 2));
    }

    // Navegar cuando termine
    if (mounted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // Función de ayuda para actualizar la UI
  Future<void> _updateProgress(double progress, String message) async {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _currentProgress = progress;
      });
      // Animar el controlador principal al nuevo valor de progreso
      await _mainController.animateTo(progress, curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _beeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFFE0F6FF), // Light sky
              Color(0xFFF0F8E8), // Light green
              Color(0xFF90EE90), // Light green bottom
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Nubes de fondo
            _buildClouds(),

            // Animación principal del jardín
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Contenedor principal de la animación
                  Container(
                    width: 300,
                    height: 300,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Stack(
                      children: [
                        // Jardín principal
                        AnimatedBuilder(
                          animation: _growthAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(300, 300),
                              painter: EnhancedGardenPainter(
                                progress: _growthAnimation.value,
                                particleProgress: _particleAnimation.value,
                              ),
                            );
                          },
                        ),

                        // Abejas animadas
                        AnimatedBuilder(
                          animation: _beeAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(300, 300),
                              painter: BeePainter(
                                progress: _beeAnimation.value,
                                gardenProgress: _growthAnimation.value,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Porcentaje con efecto brillante
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "${(_currentProgress * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Texto dinámico
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                      shadows: const [
                        Shadow(
                          color: Colors.white,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Partículas flotantes
            _buildFloatingParticles(),
          ],
        ),
      ),
    );
  }

  Widget _buildClouds() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CloudPainter(),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ParticlePainter(progress: _particleAnimation.value),
        );
      },
    );
  }
}

// ===============================================
// TUS CLASES PAINTER (SIN CAMBIOS)
// ... Pega aquí tus 4 clases:
// EnhancedGardenPainter, BeePainter, CloudPainter, ParticlePainter
// ===============================================

// Painter principal del jardín mejorado
class EnhancedGardenPainter extends CustomPainter {
  final double progress;
  final double particleProgress;

  EnhancedGardenPainter(
      {required this.progress, required this.particleProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final groundY = size.height * 0.8;

    // Configuración de pinceles
    final earthPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8B4513), Color(0xFF654321)],
      ).createShader(Rect.fromLTWH(0, groundY, size.width, size.height * 0.2))
      ..style = PaintingStyle.fill;

    final grassPaint = Paint()
      ..color = Color(0xFF228B22)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Dibujar tierra con textura
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, groundY, size.width, size.height * 0.2),
        const Radius.circular(10),
      ),
      earthPaint,
    );

    // Dibujar césped
    _drawGrass(canvas, size, grassPaint, groundY);

    // Dibujar múltiples plantas
    _drawPlant(
        canvas, size, centerX - 60, groundY, progress, 0.8, Color(0xFF228B22));
    _drawPlant(
        canvas, size, centerX, groundY, progress, 1.0, Color(0xFF32CD32));
    _drawPlant(
        canvas, size, centerX + 60, groundY, progress, 0.9, Color(0xFF006400));

    // Dibujar flores
    if (progress > 0.7) {
      _drawFlowers(canvas, size, centerX, groundY, progress);
    }

    // Dibujar sol
    _drawSun(canvas, size, progress);
  }

  void _drawGrass(Canvas canvas, Size size, Paint paint, double groundY) {
    final random = Random(42); // Seed fijo para consistencia
    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i + random.nextDouble() * 10;
      final height = 8 + random.nextDouble() * 6;
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x - 2 + random.nextDouble() * 4, groundY - height),
        paint,
      );
    }
  }

  void _drawPlant(Canvas canvas, Size size, double x, double groundY,
      double progress, double scale, Color stemColor) {
    final stemPaint = Paint()
      ..color = stemColor
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = stemColor.withGreen((stemColor.green * 0.8).round())
      ..style = PaintingStyle.fill;

    // Calcular altura del tallo
    final stemProgress = (progress / 0.6).clamp(0.0, 1.0);
    if (stemProgress > 0) {
      final stemHeight = size.height * 0.4 * stemProgress * scale;
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x, groundY - stemHeight),
        stemPaint,
      );

      // Dibujar hojas
      if (progress > 0.3) {
        final leafProgress = ((progress - 0.3) / 0.4).clamp(0.0, 1.0);
        _drawLeaves(canvas, x, groundY - stemHeight * 0.6, leafProgress * scale,
            leafPaint);
        _drawLeaves(canvas, x, groundY - stemHeight * 0.8,
            leafProgress * scale * 0.8, leafPaint);
      }
    }
  }

  void _drawLeaves(
      Canvas canvas, double x, double y, double size, Paint paint) {
    final path = Path();
    path.moveTo(x, y);
    path.quadraticBezierTo(
        x - 15 * size, y - 5 * size, x - 20 * size, y - 15 * size);
    path.quadraticBezierTo(x - 10 * size, y - 20 * size, x, y - 10 * size);
    path.quadraticBezierTo(
        x + 10 * size, y - 20 * size, x + 20 * size, y - 15 * size);
    path.quadraticBezierTo(x + 15 * size, y - 5 * size, x, y);
    canvas.drawPath(path, paint);
  }

  void _drawFlowers(Canvas canvas, Size size, double centerX, double groundY,
      double progress) {
    final flowerProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

    // Diferentes tipos de flores
    _drawFlower(canvas, centerX - 40, groundY - 80, flowerProgress, Colors.red);
    _drawFlower(
        canvas, centerX + 40, groundY - 85, flowerProgress, Colors.yellow);
    _drawFlower(canvas, centerX, groundY - 90, flowerProgress, Colors.pink);
  }

  void _drawFlower(
      Canvas canvas, double x, double y, double progress, Color color) {
    final petalPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final radius = 8 * progress;

    // Dibujar pétalos
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (pi / 180);
      final petalX = x + cos(angle) * radius;
      final petalY = y + sin(angle) * radius;
      canvas.drawCircle(Offset(petalX, petalY), radius * 0.6, petalPaint);
    }

    // Centro de la flor
    canvas.drawCircle(Offset(x, y), radius * 0.5, centerPaint);
  }

  void _drawSun(Canvas canvas, Size size, double progress) {
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.2), radius: 30))
      ..style = PaintingStyle.fill;

    final sunProgress = (progress / 0.5).clamp(0.0, 1.0);
    final sunRadius = 25 * sunProgress;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      sunRadius,
      sunPaint,
    );

    // Rayos del sol
    if (sunProgress > 0.5) {
      final rayPaint = Paint()
        ..color = Color(0xFFFFD700)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = (i * 45) * (pi / 180);
        final startX = size.width * 0.8 + cos(angle) * (sunRadius + 5);
        final startY = size.height * 0.2 + sin(angle) * (sunRadius + 5);
        final endX = size.width * 0.8 + cos(angle) * (sunRadius + 15);
        final endY = size.height * 0.2 + sin(angle) * (sunRadius + 15);

        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para abejas animadas
class BeePainter extends CustomPainter {
  final double progress;
  final double gardenProgress;

  BeePainter({required this.progress, required this.gardenProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (gardenProgress < 0.5) return; // Las abejas aparecen cuando hay flores

    final bodyPaint = Paint()
      ..color = Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final stripePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final wingPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Dibujar múltiples abejas con diferentes trayectorias
    _drawBee(
        canvas, size, progress, 0.3, 0.4, bodyPaint, stripePaint, wingPaint);
    _drawBee(canvas, size, progress + 0.3, 0.7, 0.3, bodyPaint, stripePaint,
        wingPaint);
    _drawBee(canvas, size, progress + 0.6, 0.5, 0.6, bodyPaint, stripePaint,
        wingPaint);
  }

  void _drawBee(Canvas canvas, Size size, double animProgress, double pathX,
      double pathY, Paint bodyPaint, Paint stripePaint, Paint wingPaint) {
    // Trayectoria en forma de 8
    final normalizedProgress = animProgress % 1.0;
    final angle = normalizedProgress * 2 * pi;

    final centerX = size.width * pathX;
    final centerY = size.height * pathY;

    final x = centerX + cos(angle) * 50 + cos(angle * 2) * 20;
    final y = centerY + sin(angle) * 30 + sin(angle * 2) * 15;

    // Cuerpo de la abeja
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 12, height: 8),
      bodyPaint,
    );

    // Rayas
    canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), stripePaint);
    canvas.drawLine(Offset(x - 3, y - 2), Offset(x + 3, y - 2), stripePaint);
    canvas.drawLine(Offset(x - 3, y + 2), Offset(x + 3, y + 2), stripePaint);

    // Alas (con efecto de aleteo)
    final wingOffset = sin(animProgress * 20) * 2;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(x - 3, y - 3 + wingOffset), width: 6, height: 4),
      wingPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(x + 3, y - 3 - wingOffset), width: 6, height: 4),
      wingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para nubes de fondo
class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    _drawCloud(canvas, size.width * 0.2, size.height * 0.15, 40, cloudPaint);
    _drawCloud(canvas, size.width * 0.7, size.height * 0.1, 35, cloudPaint);
    _drawCloud(canvas, size.width * 0.1, size.height * 0.25, 30, cloudPaint);
  }

  void _drawCloud(Canvas canvas, double x, double y, double size, Paint paint) {
    canvas.drawCircle(Offset(x, y), size, paint);
    canvas.drawCircle(Offset(x + size * 0.8, y), size * 0.8, paint);
    canvas.drawCircle(Offset(x - size * 0.8, y), size * 0.8, paint);
    canvas.drawCircle(Offset(x, y - size * 0.6), size * 0.9, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter para partículas flotantes
class ParticlePainter extends CustomPainter {
  final double progress;

  ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final sparkPaint = Paint()
      ..color = Color(0xFFFFD700).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final random = Random(123);

    // Partículas flotantes
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = baseY - (progress * 100) + (i * 20);

      if (y > -20 && y < size.height + 20) {
        canvas.drawCircle(
          Offset(x, y % (size.height + 40)),
          2 + random.nextDouble() * 2,
          i % 3 == 0 ? sparkPaint : particlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
