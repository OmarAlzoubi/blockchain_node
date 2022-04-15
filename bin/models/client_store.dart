import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../blockchain.dart';
import 'host_model/host_model.dart';
import 'message_model/message_model.dart';
import 'socket_store.dart';

/// A singleton class, abstracts dealing with host files
///
/// [isInitialized] is a flag that tells whether the initiallization
/// step is compelete, [thisHost] stores the host file of the
/// current node
class HostStore {
  static bool isInitialzed = false;

  static Future<void> initialize(
    String hostsFileName,
    Host thisHost,
  ) async {
    /// Load the hosts from the host file
    final file = File(hostsFileName);

    if (await file.exists()) {
      final fileAsString = await file.readAsString();

      final hostsListJson = jsonDecode(fileAsString);

      for (final hostJson in hostsListJson) {
        final host = Host.fromJson(hostJson);
        try {
          print('connecting to ${host.ip}:${host.port}');
          Random r = Random();
          String key = base64.encode(
            List<int>.generate(
              8,
              (_) => r.nextInt(255),
            ),
          );

          final client = HttpClient();
          final request = await client.get(
            host.ip,
            host.port,
            '/ws',
          );
          request.headers.add('Connection', 'upgrade');
          request.headers.add('Upgrade', 'websocket');
          request.headers.add(
            'sec-websocket-version',
            '13',
          ); // insert the correct version here
          request.headers.add('sec-websocket-key', key);
          final response = await request.close();
          final socket = await response.detachSocket();

          final ws = WebSocket.fromUpgradedSocket(
            socket,
            serverSide: false,
          );
          final id = SocketStore.add(ws);
          SocketStore.addListener(id, (e) {
            final decodedMessage = jsonDecode(e);
            final message = Message.fromJson(decodedMessage);
            message.whenOrNull(
              blockLookupRequest: (ex, bid) {
                if (BlockChain().contains(bid)) {
                  final block = BlockChain().get(bid)!;
                  final reply = Message.blockLookUpResponse(block);
                  final replyAsJson = jsonEncode(reply);
                  ws.add(replyAsJson);
                }
              },
            );
          });
        } catch (e, st) {
          print(e);
          print(st);
        }
      }

      /// Set the initialization flag
      isInitialzed = true;
    } else {
      print('Hosts file does not exist!');
      exit(1);
    }
  }
}
