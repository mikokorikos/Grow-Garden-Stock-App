// Archivo: lib/presentation/widgets/header_status_view.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/stock_item_entity.dart';
import '../bloc/stock/stock_bloc.dart';

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
    // Este timer solo existe para refrescar la UI cada segundo.
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
    // ... (El código del estado de conexión no cambia)
    return const SizedBox.shrink(); // Simplificado para enfocarnos en el timer
  }

  Widget _buildTimers() {
    if (widget.state is! StockActive && widget.state is! StockPolling) {
      return const CupertinoActivityIndicator(radius: 8);
    }

    // Prioridad 1: Mostrar mensaje de reintento si está disponible en StockPolling
    if (widget.state is StockPolling) {
      final pollingState = widget.state as StockPolling;
      if (pollingState.message != null && pollingState.message!.isNotEmpty) {
        return Text(
          pollingState.message!,
          style: const TextStyle(fontSize: 12, color: AppTheme.primary),
          textAlign: TextAlign.center,
        );
      }
    }

    // Obtener stockData según el estado actual
    final stockData = widget.state is StockActive
        ? (widget.state as StockActive).stockData
        : (widget.state is StockPolling // Asegurarse de que es StockPolling antes de castear
            ? (widget.state as StockPolling).lastKnownStockData
            : <String, List<StockItemEntity>>{}); // Fallback a mapa vacío si no es ni Active ni Polling

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

    // Prioridad 2: Si no hay mensaje de reintento y no hay timers activos, mostrar "No hay restocks activos"
    if (activeTimers.isEmpty) {
      // Evitar mostrar "No hay restocks activos" si ya estamos mostrando un mensaje de sondeo.
      // Esto se maneja con la comprobación de pollingState.message más arriba.
      // Si llegamos aquí y state es StockPolling pero sin mensaje, es un caso que no debería ocurrir
      // si el BLoC siempre establece un mensaje. Pero por si acaso:
      if (widget.state is StockPolling && (widget.state as StockPolling).message != null) {
        // Ya se manejó arriba, no hacer nada aquí para evitar duplicar texto.
        // O, si el mensaje es la única fuente de verdad cuando se está sondeando:
        return const SizedBox.shrink();
      }
      return const Text("No hay restocks activos.",
          style: TextStyle(fontSize: 12));
    }

    // Mostramos un Wrap para que los timers se ajusten si no caben en una línea.
    // Prioridad 3: Mostrar los timers activos
    return Wrap(
      spacing: 24.0, // Espacio horizontal entre timers
      runSpacing: 8.0, // Espacio vertical si hay más de una línea
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
