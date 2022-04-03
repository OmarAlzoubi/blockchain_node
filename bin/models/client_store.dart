import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';

import '../interfaces/impl/host_message_handeler.dart';
import 'block_store.dart';
import 'host_model/host_model.dart';
import 'message_model/message_model.dart';

class HostStore {
  static bool isInitialzed = false;
  HostStore._();
  static final _hosts =
      BehaviorSubject<Map<String, HostMessageHandeler>>.seeded(
    {},
  );
  static late final Host thisHost;

  static Future<void> initialize(String hostsFileName, Host host) async {
    assert(BlockStore.isInitialzed, 'BlockStore has not been initialized!');
    thisHost = host;
    final file = File(hostsFileName);

    if (await file.exists()) {
      final fileAsString = await file.readAsString();

      final hostsListJson = jsonDecode(fileAsString);

      for (final hostJson in hostsListJson) {
        final host = Host.fromJson(hostJson);

        final socket = IOWebSocketChannel.connect(
          Uri.parse(host.hostId),
          headers: {'host': '${thisHost.ip}:${thisHost.port}'},
        );
        add(
          '${host.ip}:${host.port}',
          HostMessageHandeler(socket, '${host.ip}:${host.port}'),
        );
      }

      isInitialzed = true;
    } else {
      print('Hosts file does not exist!');
      exit(1);
    }
  }

  static UnmodifiableMapView<String, HostMessageHandeler> get hosts =>
      UnmodifiableMapView(_hosts.value);

  static Future<void> add(String hostId, HostMessageHandeler handeler) async {
    final newHosts = _hosts.value;
    newHosts[hostId] = handeler;
    _hosts.add(newHosts);
  }

  static void broadcastMessage(Message message) {
    hosts.forEach(
      (host, handeler) {
        handeler.socket.sink.add(jsonEncode(message));
        //socket?.sink.add(jsonEncode(message));
      },
    );
  }

  static void broadcastMessageToExcept(
    Message message,
    List<Host> exceptions,
  ) {
    hosts.forEach(
      (hostId, socket) {
        bool found = false;
        for (final ex in exceptions) {
          if (ex.hostId == hostId) {
            found = true;
          }
        }
        if (!found) {
          //socket?.sink.add(jsonEncode(message));
        }
      },
    );
  }

  static bool containsById(String hostId) {
    if (_hosts.value.containsKey(hostId)) {
      return true;
    }
    return false;
  }

  static HostMessageHandeler getById(String hostId) {
    return _hosts.value[hostId]!;
  }
}
