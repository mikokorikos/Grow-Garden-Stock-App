import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 1.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.05),
        ],
        stops: const [0.1, 1], // Ya era const
      ),
      borderGradient: LinearGradient( // No puede ser const por withOpacity
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.1),
        ],
      ),
      child: Material(
        color: Colors.transparent, // Colors.transparent puede ser const
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0), // No es const por el método
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Puede ser const
            child: child,
          ),
        ),
      ),
    );
  }
}
