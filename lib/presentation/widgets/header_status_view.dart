// Archivo: lib/presentation/widgets/header_status_view.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/stock/stock_bloc.dart';

class HeaderStatusView extends StatefulWidget {
  final StockState state;
  const HeaderStatusView({super.key, required this.state});

  @override
  State<HeaderStatusView> createState() => _HeaderStatusViewState();
}

class _HeaderStatusViewState extends State<HeaderStatusView> {
  Timer? _timer;
  Set<String> _lastActiveTimers = {};

  @override
  void initState() {
    super.initState();
    debugPrint(
        "[HeaderStatusView.initState] Inicializando y creando timer periódico de 1s.");
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    debugPrint(
        "[HeaderStatusView.dispose] Widget destruido. Cancelando timer.");
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No se añade log aquí porque se llamaría cada segundo, es demasiado ruidoso.
    // La lógica de logging está en _buildTimers.
    return Container(
      padding: const EdgeInsets.all(12.0),
      width: double.infinity,
      color: AppTheme.background.withOpacity(0.95),
      child: Column(
        children: [
          _buildStatusMessage(),
          const SizedBox(height: 8),
          _buildTimers(),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return const SizedBox.shrink();
  }

  Widget _buildTimers() {
    if (widget.state is! StockActive && widget.state is! StockPolling) {
      return const CupertinoActivityIndicator(radius: 8);
    }

    final stockData = widget.state is StockActive
        ? (widget.state as StockActive).stockData
        : (widget.state as StockPolling).lastKnownStockData;

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

    // --- LÓGICA DE LOGGING COMBINADA ---
    debugPrint("--- [HeaderStatusView] Pulso de Timers Visuales ---");
    if (activeTimers.isNotEmpty) {
      activeTimers.forEach((category, duration) {
        final label = category[0].toUpperCase() + category.substring(1);
        debugPrint(
            "  -> [PULSO] Categoría: $label, Tiempo Restante: ${_formatDuration(duration)}");
      });
    } else {
      debugPrint("  -> [PULSO] No hay timers visuales activos.");
    }

    final currentActiveTimersSet = activeTimers.keys.toSet();
    final expiredTimers = _lastActiveTimers.difference(currentActiveTimersSet);

    if (expiredTimers.isNotEmpty) {
      debugPrint("--- [HeaderStatusView] Evento de Expiración Detectado ---");
      for (final expiredCategory in expiredTimers) {
        final label =
            expiredCategory[0].toUpperCase() + expiredCategory.substring(1);
        debugPrint(
            "  -> [EVENTO] El timer VISUAL para la categoría '$label' ha finalizado.");
      }
    }
    _lastActiveTimers = currentActiveTimersSet;
    // --- FIN DE LA LÓGICA DE LOGGING ---

    if (activeTimers.isEmpty) {
      return const Text("No hay restocks activos.",
          style: TextStyle(fontSize: 12));
    }

    return Wrap(
      spacing: 24.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: activeTimers.entries.map((entry) {
        final label = entry.key[0].toUpperCase() + entry.key.substring(1);
        return Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              _formatDuration(entry.value),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
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
