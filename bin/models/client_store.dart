import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';

import '../interfaces/impl/host_message_handeler.dart';
import 'host_model/host_model.dart';
import 'message_model/message_model.dart';

/// A singleton class, abstracts dealing with host files
///
/// [isInitialized] is a flag that tells whether the initiallization
/// step is compelete, [thisHost] stores the host file of the
/// current node
class HostStore {
  static bool isInitialzed = false;
  static late final Host thisHost;

  /// Stores the state of the store
  static final _hosts =
      BehaviorSubject<Map<String, HostMessageHandeler>>.seeded(
    {},
  );

  static Future<void> initialize(
    String hostsFileName,
    Host host,
  ) async {
    thisHost = host;

    /// Load the hosts from the host file
    final file = File(hostsFileName);

    if (await file.exists()) {
      final fileAsString = await file.readAsString();

      final hostsListJson = jsonDecode(fileAsString);

      for (final hostJson in hostsListJson) {
        final host = Host.fromJson(hostJson);

        /// Try to establish a socket connection with the other end
        final socket = IOWebSocketChannel.connect(
          Uri.parse(host.hostId),
          headers: {'host': '${thisHost.ip}:${thisHost.port}'},
        );
        add(
          '${host.ip}:${host.port}',
          HostMessageHandeler(socket, '${host.ip}:${host.port}'),
        );
      }

      /// Set the initialization flag
      isInitialzed = true;
    } else {
      print('Hosts file does not exist!');
      exit(1);
    }
  }

  static UnmodifiableMapView<String, HostMessageHandeler> get hosts {
    return UnmodifiableMapView(_hosts.value);
  }

  /// Adds a host to the store
  static Future<void> add(
    String hostId,
    HostMessageHandeler handeler,
  ) async {
    final newHosts = _hosts.value;
    newHosts[hostId] = handeler;
    _hosts.add(newHosts);
  }

  /// Sends [message] to all connected [WebSocketChannels]
  static void broadcastMessage(Message message) {
    hosts.forEach(
      (host, handeler) {
        handeler.socket.sink.add(message.asJson);
      },
    );
  }

  /// Sends [message] to all connected [WebSocketChannel]s except
  /// the ones in [exceptions]
  static void broadcastMessageToExcept(
    Message message,
    List<Host> exceptions,
  ) {
    hosts.forEach(
      (hostId, handeler) {
        bool found = false;
        for (final ex in exceptions) {
          if (ex.hostId == hostId) {
            found = true;
          }
        }
        if (!found) {
          handeler.socket.sink.add(message.asJson);
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
