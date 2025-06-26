import 'dart:async';
import 'dart:ui'; // Para ImageFilter
import 'package:flutter/cupertino.dart';
import 'package:grow_garden_tracker/presentation/bloc/stock/stock_bloc.dart';
import '../../core/theme/app_theme.dart';

class HeaderStatusView extends StatefulWidget {
  final StockState state;
  const HeaderStatusView({super.key, required this.state});

  @override
  State<HeaderStatusView> createState() => _HeaderStatusViewState();
}

class _HeaderStatusViewState extends State<HeaderStatusView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Aplicamos un ClipRRect para que el BackdropFilter no se salga del contenedor si tiene bordes redondeados (aunque aquí no los tiene)
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Efecto blur sutil
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          width: double.infinity,
          // Usar el color de barra de AppTheme, que ya es translúcido
          decoration: BoxDecoration(
             color: AppTheme.glassBarBackgroundColor.withOpacity(0.85), // Asegurar opacidad
             border: Border(
               bottom: BorderSide(color: AppTheme.glassBorderColor.withOpacity(0.5), width: 0.5) // Borde sutil inferior
             )
          ),
          child: _buildTimers(),
        ),
      ),
    );
  }

  Widget _buildTimers() {
    if (widget.state is! StockActive) {
      return SizedBox(
        height: 36, // Altura consistente
        child: Center(
          child: Text(
            "Actualizando...",
            style: AppTheme.captionTextStyle.copyWith(color: AppTheme.darkTextColor.withOpacity(0.6)),
          ),
        ),
      );
    }

    final currentState = widget.state as StockActive;
    final stockData = currentState.stockData;
    final activeTimers = <String, Duration>{};

    stockData.forEach((category, items) {
      if (items.isNotEmpty) {
        items.sort((a, b) => a.endDate.compareTo(b.endDate));
        final duration = items.first.endDate.difference(DateTime.now());
        if (!duration.isNegative) {
          activeTimers[category] = duration;
        }
      }
    });

    if (activeTimers.isEmpty) {
      return SizedBox(
        height: 36, // Altura consistente
        child: Center(
          child: Text(
            "No hay restocks activos.",
            style: AppTheme.bodyTextStyle.copyWith(color: AppTheme.darkTextColor.withOpacity(0.8)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36, // Altura consistente para el contenido
      child: Center( // Centrar el Wrap horizontalmente
        child: Wrap(
          spacing: 20.0, // Espacio entre timers
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center, // Alinear verticalmente los items del Wrap
          children: activeTimers.entries.map((entry) {
            final label = entry.key == 'eventshop'
                ? 'Evento'
                : entry.key[0].toUpperCase() + entry.key.substring(1);
            return RichText(
              text: TextSpan(
                style: AppTheme.bodyTextStyle.copyWith(fontSize: 13, color: AppTheme.darkTextColor),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
                  TextSpan(
                    text: _formatDuration(entry.value),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAppColor, // Usar el color primario de la app
                        fontSize: 13.5), // Ligeramente más grande para destacar
                  ),
                ]
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
