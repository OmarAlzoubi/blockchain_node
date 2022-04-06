import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'dart:io';

import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'message_model/message_model.dart';

class SocketSubscription {
  late final StreamSubscription subscription;
  final Map<String, Function> listeners;

  SocketSubscription() : listeners = {};
  void setSubScription(StreamSubscription subscription) {
    this.subscription = subscription;
  }

  String addListener(Function listener) {
    final id = Uuid().v4();
    listeners[id] = listener;
    return id;
  }

  void call(dynamic event) {
    for (final listener in listeners.values) {
      listener(event);
    }
  }

  void removeListener(String id) {
    listeners.remove(id);
  }

  void dispose() {
    subscription.cancel();
    listeners.clear();
  }
}

class SocketStore {
  static late final BehaviorSubject<UnmodifiableMapView<String, WebSocket>>
      _sockets;
  static late final Map<String, SocketSubscription> _subscriptions;

  static void initialize() {
    _sockets = BehaviorSubject.seeded(UnmodifiableMapView({}));
    _subscriptions = {};
  }

  static void remove(String id) {
    removeListeners(id);
    final copy = {..._sockets.value};
    copy.remove(id);
    _sockets.add(UnmodifiableMapView(copy));
  }

  static String? addListener(String id, Function listener) {
    if (_sockets.value.containsKey(id)) {
      return _subscriptions[id]!.addListener(listener);
    }
    return null;
  }

  static void removeListeners(String id) {
    _subscriptions.remove(id);
  }

  static WebSocket? get(String id) {
    return _sockets.value[id];
  }

  static String add(WebSocket socket) {
    final copy = {..._sockets.value};
    final uuid = Uuid().v4();
    copy[uuid] = socket;
    _subscriptions[uuid] = SocketSubscription();
    final subscription = socket.listen((event) {
      _subscriptions[uuid]?.call(event);
    });
    _subscriptions[uuid]!.setSubScription(subscription);
    _sockets.add(UnmodifiableMapView(copy));
    return uuid;
  }

  static void broadcast(Message message) {
    final messageAsJson = jsonEncode(message);
    for (final socket in _sockets.value.values) {
      socket.add(messageAsJson);
    }
  }

  static void sendMessageTo(dynamic message, String id) {
    _sockets.value[id]?.add(message);
  }
}
