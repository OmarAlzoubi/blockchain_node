import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'interfaces/impl/host_message_handeler.dart';
import 'models/block_store.dart';
import 'models/client_store.dart';
import 'models/host_model/host_model.dart';
import 'models/message_model/message_model.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser();
  parser.addOption('port', abbr: 'p', defaultsTo: '8080');
  parser.addOption('hosts', abbr: 'h', defaultsTo: 'hosts.json');
  parser.addOption('blocks', abbr: 'b', defaultsTo: 'blocks');
  final parserResults = parser.parse(args);
  final port = int.parse(parserResults['port']);
  final hostsFileName = parserResults['hosts'] as String;
  final blocksFolderName = parserResults['blocks'] as String;

  final router = Router();

  router.get(
    '/getBlock/<blockId>',
    (Request request, String blockId) async {
      if (BlockStore.contains(blockId)) {
        final block = BlockStore.get(blockId)!;
        return Response.ok(jsonEncode(block));
      } else {
        HostStore.broadcastMessage(Message.blockLookupRequest([], blockId));
        final completer = Completer();
        bool timedOut = false;
        Stream.fromFuture(
          BlockStore.stream.firstWhere(
            (element) => element.containsKey(blockId),
          ),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: (_) {
            if (!completer.isCompleted) {
              timedOut = true;
              completer.complete();
            }
          },
        ).listen(
          (event) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );

        await completer.future;
        if (!timedOut) {
          print(BlockStore.blocks);
          return Response.ok(jsonEncode(BlockStore.get(blockId)));
        }

        return Response.ok('block-not-found');
      }
    },
  );
  router.get(
    '/',
    (Request request) {
      return webSocketHandler(
        (WebSocketChannel socket) {
          final hostId = request.headers['host']!;
          final handeler = HostMessageHandeler(socket, hostId);
          HostStore.add(hostId, handeler);
        },
      ).call(request);
    },
  );

  final server = await shelf_io.serve(
    router,
    '127.0.0.1',
    port,
  );
  await BlockStore.initialize(blocksFolderName);
  await HostStore.initialize(
    hostsFileName,
    Host(
      'ws://${server.address}:${server.port}',
      server.address.address,
      server.port.toString(),
    ),
  );

  print('Serving at http://${server.address.host}:${server.port}');
}
