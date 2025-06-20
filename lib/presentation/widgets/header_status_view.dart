// Archivo: lib/presentation/widgets/header_status_view.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
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
  Duration _countdown = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    // Este timer solo se encarga de actualizar la UI del reloj cada segundo.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void didUpdateWidget(covariant HeaderStatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el estado cambia (ej. de Polling a Active), recalculamos el countdown.
    if (widget.state != oldWidget.state) {
      _updateCountdown();
    }
  }

  void _updateCountdown() {
    if (!mounted) return;

    Duration newCountdown = Duration.zero;
    if (widget.state is StockActive) {
      final nearestEndDate = (widget.state as StockActive).nearestEndDate;
      if (nearestEndDate != null) {
        final difference = nearestEndDate.difference(DateTime.now());
        newCountdown = difference.isNegative ? Duration.zero : difference;
      }
    }
    setState(() {
      _countdown = newCountdown;
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
      color: AppTheme.background.withOpacity(0.9),
      child: Column(
        children: [
          _buildStatusMessage(),
          const SizedBox(height: 4),
          Text(
            _formatDuration(_countdown),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (widget.state is StockPolling) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(radius: 8.0),
          SizedBox(width: 8),
          Text("Buscando nuevo stock...",
              style: TextStyle(color: CupertinoColors.systemOrange)),
        ],
      );
    }
    if (widget.state is StockActive) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.check_mark_circled_solid,
              color: CupertinoColors.systemGreen, size: 16),
          SizedBox(width: 8),
          Text("Stock Activo", style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
    }
    return const SizedBox
        .shrink(); // No mostramos nada si no hay estado activo/polling
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
