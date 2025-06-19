import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/api/api_constants.dart';
import '../models/stock_item_model.dart';

abstract class StockWebSocketDataSource {
  Stream<Map<String, List<StockItemModel>>> getStockUpdates();
}

class StockWebSocketDataSourceImpl implements StockWebSocketDataSource {
  final WebSocketChannel channel;

  StockWebSocketDataSourceImpl()
      : channel =
            WebSocketChannel.connect(Uri.parse(ApiConstants.webSocketUrl));

  @override
  Stream<Map<String, List<StockItemModel>>> getStockUpdates() {
    return channel.stream.map((message) {
      final data = json.decode(message) as Map<String, dynamic>;
      final stockMap = <String, List<StockItemModel>>{};

      data.forEach((key, value) {
        if (value is List && key.endsWith('_stock')) {
          final categoryName = key.replaceAll('_stock', '');
          stockMap[categoryName] =
              value.map((item) => StockItemModel.fromJson(item)).toList();
        }
      });

      return stockMap;
    });
  }
}
