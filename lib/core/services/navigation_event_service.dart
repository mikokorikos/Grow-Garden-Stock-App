import 'dart:async';
import 'dart:convert'; // Necesario para jsonEncode/Decode si se usa en payload
import 'package:flutter/cupertino.dart'; // Para Color, si se pasa

enum NavigationEventType { showSniperAlarm }

class NavigationEvent {
  final NavigationEventType type;
  final dynamic data;

  NavigationEvent(this.type, {this.data});
}

class NavigationEventService {
  static final NavigationEventService _instance = NavigationEventService._internal();
  factory NavigationEventService() => _instance;
  NavigationEventService._internal();

  final StreamController<NavigationEvent> _navStreamController = StreamController<NavigationEvent>.broadcast();
  Stream<NavigationEvent> get navStream => _navStreamController.stream;

  void fireEvent(NavigationEventType type, {dynamic data}) {
    _navStreamController.add(NavigationEvent(type, data: data));
  }

  void dispose() {
    _navStreamController.close();
  }
}
