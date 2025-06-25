import 'dart:ui';
import 'package:flutter/cupertino.dart';

class SniperAlarmDialog extends StatefulWidget {
  final List<String> foundItems;
  final Color rarityColor;

  const SniperAlarmDialog({
    super.key,
    required this.foundItems,
    required this.rarityColor,
  });

  @override
  State<SniperAlarmDialog> createState() => _SniperAlarmDialogState();
}

class _SniperAlarmDialogState extends State<SniperAlarmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Variable para controlar la posición y opacidad del slider
  double _dragValue = 0.0;
  double _dragPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un BackdropFilter para desenfocar el fondo
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        // El color de fondo se basa en la rareza del item encontrado
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              widget.rarityColor.withOpacity(0.6),
              widget.rarityColor.withOpacity(0.9),
            ],
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Spacer(flex: 2),
              // Icono animado para llamar la atención
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: CupertinoColors.white,
                  size: 100,
                  shadows: [
                    Shadow(color: CupertinoColors.black, blurRadius: 15)
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Título de la alarma
              const Text(
                '¡ITEM ENCONTRADO!',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(color: CupertinoColors.black, blurRadius: 5)
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Lista de items encontrados
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  widget.foundItems.join(', '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // Slider para descartar la alarma
              _buildSlideToDismiss(context),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideToDismiss(BuildContext context) {
    return GestureDetector(
      // Detecta el movimiento horizontal
      onHorizontalDragUpdate: (details) {
        setState(() {
          // Actualiza la posición del slider, limitándola al ancho del contenedor
          final screenWidth = MediaQuery.of(context).size.width;
          _dragPosition =
              (_dragPosition + details.delta.dx).clamp(0.0, screenWidth * 0.6);
        });
      },
      // Se llama cuando el usuario suelta el dedo
      onHorizontalDragEnd: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Si el slider ha recorrido más del 50% del camino, se cierra la alarma
        if (_dragPosition > screenWidth * 0.3) {
          Navigator.of(context).pop();
        } else {
          // Si no, vuelve a su posición inicial con una animación
          setState(() {
            _dragPosition = 0.0;
          });
        }
      },
      child: Container(
        width: 250,
        height: 60,
        decoration: BoxDecoration(
          color: CupertinoColors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                'Deslizar para descartar',
                style: TextStyle(
                  color: CupertinoColors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              left: _dragPosition,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.white,
                ),
                child: const Icon(
                  CupertinoIcons.chevron_right_2,
                  color: CupertinoColors.black,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
