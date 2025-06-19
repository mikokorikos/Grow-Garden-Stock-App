import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/item_info_entity.dart';
import '../../domain/entities/stock_item_entity.dart';
import 'glassmorphism_card.dart';

class StockItemCard extends StatefulWidget {
  final StockItemEntity stockItem;
  final ItemInfoEntity? itemInfo;

  const StockItemCard({
    super.key,
    required this.stockItem,
    this.itemInfo,
  });

  @override
  State<StockItemCard> createState() => _StockItemCardState();
}

class _StockItemCardState extends State<StockItemCard> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateRemainingTime());
  }

  @override
  void didUpdateWidget(covariant StockItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el item cambia (ej. por una actualización), reseteamos el contador.
    if (widget.stockItem.id != oldWidget.stockItem.id) {
      _updateRemainingTime();
    }
  }

  void _updateRemainingTime() {
    if (!mounted) return;
    final difference = widget.stockItem.endDate.difference(DateTime.now());
    setState(() {
      _remainingTime = difference.isNegative ? Duration.zero : difference;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(widget.itemInfo?.rarity);

    return GlassmorphismCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.network(
                widget.stockItem.iconUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const CupertinoActivityIndicator(),
                errorBuilder: (_, __, ___) =>
                    const Icon(CupertinoIcons.photo, size: 40),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.stockItem.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${widget.stockItem.quantity}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_remainingTime),
                  style: TextStyle(
                      fontSize: 12,
                      color: rarityColor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
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

  Color _getRarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return CupertinoColors.systemGrey;
      case 'uncommon':
        return CupertinoColors.systemGreen;
      case 'rare':
        return CupertinoColors.systemBlue;
      case 'legendary':
        return CupertinoColors.systemPurple;
      case 'mythical':
        return CupertinoColors.systemOrange;
      case 'divine':
        return CupertinoColors.systemYellow;
      default:
        return AppTheme.textColor;
    }
  }
}
