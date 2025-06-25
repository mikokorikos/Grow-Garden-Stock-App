import 'dart:async';
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { // Duration puede ser const
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
    return Container(
      padding: const EdgeInsets.all(12.0), // Puede ser const
      width: double.infinity,
      color: AppTheme.background.withOpacity(0.95), // No puede ser const
      child: _buildTimers(),
    );
  }

  Widget _buildTimers() {
    // La lógica se simplifica: solo nos importa el estado 'StockActive'.
    if (widget.state is! StockActive) {
      // Si no estamos en estado activo, no mostramos nada o un indicador.
      return const SizedBox( // Puede ser const
          height: 24, child: CupertinoActivityIndicator(radius: 8)); // CupertinoActivityIndicator puede ser const
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
      return const Text("No hay restocks activos.", // Puede ser const
          style: TextStyle(fontSize: 12)); // Puede ser const
    }

    return Wrap(
      spacing: 24.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: activeTimers.entries.map((entry) {
        final label = entry.key == 'eventshop'
            ? 'Evento'
            : entry.key[0].toUpperCase() + entry.key.substring(1);
        return Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), // Puede ser const
            Text(
              _formatDuration(entry.value),
              style: const TextStyle( // Puede ser const
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary, // AppTheme.primary es probablemente const
                  fontSize: 14),
            ),
          ],
        );
      }).toList(),
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
