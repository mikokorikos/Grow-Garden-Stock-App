import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Para Colors y Material
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:grow_garden_tracker/core/theme/app_theme.dart';

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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  double _dragPosition = 0.0;
  final double _dismissThresholdFactor = 0.4; // Factor para el umbral de deslizamiento

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Duración más larga para suavidad
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticInOut, // Curva más elegante
          reverseCurve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDismiss() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Usar un color base para el glow si el rarityColor es muy oscuro
    final Color effectiveGlowColor = widget.rarityColor.computeLuminance() < 0.3
        ? AppTheme.lightTextColor // Un color claro para el glow si el fondo es oscuro
        : widget.rarityColor;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Blur más intenso
      child: Material( // Envolver con Material para asegurar que los efectos de texto funcionen
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                widget.rarityColor.withOpacity(0.5), // Más sutil el inicio
                widget.rarityColor.withOpacity(0.8), // Más sutil el final
              ],
              radius: 1.5, // Radio mayor para un gradiente más suave
              center: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: effectiveGlowColor.withOpacity(0.5 * (_glowAnimation.value / 8.0)),
                              blurRadius: _glowAnimation.value * 2.5,
                              spreadRadius: _glowAnimation.value * 0.5,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    CupertinoIcons.sparkles, // Icono más premium
                    color: AppTheme.lightTextColor,
                    size: 110, // Ligeramente más grande
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0,4))
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  '¡ITEM ENCONTRADO!',
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineStyle.copyWith(
                    color: AppTheme.lightTextColor,
                    fontSize: 28, // Ligeramente más grande
                    fontWeight: FontWeight.w700, // Un poco más bold
                    shadows: [
                       Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0,2))
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    widget.foundItems.join(', '),
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyTextStyle.copyWith(
                      color: AppTheme.lightTextColor.withOpacity(0.9),
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                       shadows: [
                         Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0,1))
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                _buildSlideToDismiss(context),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideToDismiss(BuildContext context) {
    final double sliderWidth = MediaQuery.of(context).size.width * 0.7;
    final double thumbSize = 58.0;
    final double maxDragPosition = sliderWidth - thumbSize;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragPosition = (_dragPosition + details.delta.dx)
              .clamp(0.0, maxDragPosition);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragPosition / maxDragPosition > _dismissThresholdFactor) {
          _onDismiss();
        } else {
          setState(() {
            _dragPosition = 0.0; // Snap back
          });
        }
      },
      child: Container(
        width: sliderWidth,
        height: thumbSize,
        decoration: BoxDecoration(
          color: AppTheme.darkTextColor.withOpacity(0.2), // Fondo más oscuro para contraste
          borderRadius: BorderRadius.circular(thumbSize / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: 1.0 - (_dragPosition / maxDragPosition * 1.5).clamp(0.0, 1.0),
              duration: const Duration(milliseconds: 100),
              child: Text(
                'Deslizar para descartar',
                style: AppTheme.bodyTextStyle.copyWith(
                  color: AppTheme.lightTextColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeOut,
              left: _dragPosition,
              child: Container(
                width: thumbSize - 4, // Ligeramente más pequeño que el track
                height: thumbSize - 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightTextColor, // Color del thumb
                  boxShadow: [
                     BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                    )
                  ]
                ),
                child: Icon(
                  CupertinoIcons.chevron_right, // Icono más simple
                  color: widget.rarityColor.computeLuminance() < 0.3 ? AppTheme.darkTextColor : widget.rarityColor,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
