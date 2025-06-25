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
      duration: const Duration(milliseconds: 800), // const
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // No puede ser const por ImageFilter.blur
      child: Container(
        decoration: BoxDecoration( // No puede ser const por widget.rarityColor
          gradient: RadialGradient( // No puede ser const por widget.rarityColor
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
              const Spacer(flex: 2), // const
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: const Icon( // const
                  CupertinoIcons.sparkles,
                  color: CupertinoColors.white, // CupertinoColors.white es const
                  size: 100,
                  shadows: [ // Lista puede ser const
                    Shadow(color: CupertinoColors.black, blurRadius: 15) // Shadow puede ser const
                  ],
                ),
              ),
              const SizedBox(height: 20), // const
              const Text( // const
                '¡ITEM ENCONTRADO!',
                style: TextStyle( // const
                  color: CupertinoColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  shadows: [ // Lista puede ser const
                    Shadow(color: CupertinoColors.black, blurRadius: 5) // Shadow puede ser const
                  ],
                ),
              ),
              const SizedBox(height: 10), // const
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // const
                child: Text(
                  widget.foundItems.join(', '),
                  textAlign: TextAlign.center,
                  style: const TextStyle( // const
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Spacer(flex: 3), // const
              _buildSlideToDismiss(context),
              const Spacer(flex: 1), // const
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideToDismiss(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          final screenWidth = MediaQuery.of(context).size.width;
          _dragPosition =
              (_dragPosition + details.delta.dx).clamp(0.0, screenWidth * 0.6);
        });
      },
      onHorizontalDragEnd: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (_dragPosition > screenWidth * 0.3) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _dragPosition = 0.0;
          });
        }
      },
      child: Container(
        width: 250,
        height: 60,
        decoration: BoxDecoration( // No puede ser const por withOpacity
          color: CupertinoColors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(30), // No es const
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                'Deslizar para descartar',
                style: TextStyle( // No puede ser const por withOpacity
                  color: CupertinoColors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50), // const
              left: _dragPosition,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration( // const
                  shape: BoxShape.circle,
                  color: CupertinoColors.white,
                ),
                child: const Icon( // const
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
