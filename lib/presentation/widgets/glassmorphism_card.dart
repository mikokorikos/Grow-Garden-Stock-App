import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:glassmorphism/glassmorphism.dart';
import 'package:grow_garden_tracker/core/theme/app_theme.dart';

class GlassmorphismCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double blur;
  final double borderStrength;
  final EdgeInsetsGeometry padding;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16.0, // Ligeramente menos redondeado para un look más iOS
    this.blur = 10.0, // Un blur más sutil
    this.borderStrength = 1.0, // Borde más fino
    this.padding = const EdgeInsets.all(12.0),
  });

  @override
  State<GlassmorphismCard> createState() => _GlassmorphismCardState();
}

class _GlassmorphismCardState extends State<GlassmorphismCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
      HapticFeedback.lightImpact(); // Haptic feedback sutil
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.98 : 1.0; // Efecto de presión

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: GlassmorphicContainer(
          width: double.infinity,
          height: double.infinity,
          borderRadius: widget.borderRadius,
          blur: widget.blur,
          alignment: Alignment.center,
          border: widget.borderStrength,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.glassBackgroundColor, // Usar color de AppTheme
              AppTheme.glassBackgroundColor.withOpacity(0.5), // Más sutil
            ],
            stops: const [0.1, 1],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.glassBorderColor, // Usar color de AppTheme
              AppTheme.glassBorderColor.withOpacity(0.5), // Más sutil
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // InkWell se mantiene para el efecto ripple si se desea,
              // pero el onTap principal es manejado por GestureDetector para el haptic feedback y la animación.
              // Si no se quiere ripple, se puede quitar InkWell y manejar el onTap directamente en GestureDetector.
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: widget.onTap != null ? () {
                // El onTap de InkWell se llama aquí para mantener el ripple si está presente.
                // El HapticFeedback y la lógica principal ya están en GestureDetector.
                if(!_isPressed && widget.onTap != null) { // Prevenir doble llamada si el tap es muy rápido
                   widget.onTap!();
                   HapticFeedback.lightImpact();
                }
              } : null,
              splashColor: AppTheme.primaryAppColor.withOpacity(0.1),
              highlightColor: AppTheme.primaryAppColor.withOpacity(0.05),
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
