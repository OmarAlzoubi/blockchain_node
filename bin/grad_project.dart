import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'helpers.dart';
import 'models/block_store.dart';
import 'models/client_store.dart';
import 'models/host_model/host_model.dart';
import 'models/message_model/message_model.dart';
import 'models/socket_store.dart';

void webSocketHandeler(String socketId) {
  SocketStore.addListener(
    socketId,
    (e) {
      final message = Message.fromJson(jsonDecode(e));
      message.whenOrNull(
        blockLookUpResponse: (block) {
          BlockStore.add(block);
        },
      );
    },
  );
}

Future getBlockRequestHandeler(Uri uri, HttpResponse response) async {
  final params = uri.queryParameters;
  final blockId = params['blockId'];
  if (blockId != null) {
    if (BlockStore.contains(blockId)) {
      final block = BlockStore.get(blockId)!;
      final blockAsJson = jsonEncode(block);
      response.write(blockAsJson);
    } else {
      final message = Message.blockLookupRequest([], blockId);
      SocketStore.broadcast(message);
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
        final block = BlockStore.get(blockId)!;
        final blockAsJson = jsonEncode(block);
        response.write(blockAsJson);
      } else {
        response.write('block-not-found');
      }
      await response.close();
    }
  }
}

Future<void> initializeApp(ParsingResults args) async {
  SocketStore.initialize();
  await BlockStore.initialize(
    args.blocksFolderName,
  );
  await HostStore.initialize(
    args.hostsFileName,
    Host('127.0.0.1', args.port),
  );
}

Future<void> main(List<String> args) async {
  final parsedArgs = parseArguments(args);

  final httpSocket = await ServerSocket.bind(
    '127.0.0.1',
    parsedArgs.port,
  );
  final server = HttpServer.listenOn(httpSocket);
  runZonedGuarded(
    () async {
      await for (final request in server) {
        final uri = request.uri;
        if (uri.path == '/ws') {
          final shouldUpgrade = WebSocketTransformer.isUpgradeRequest(request);
          if (shouldUpgrade) {
            final ws = await WebSocketTransformer.upgrade(request);
            final id = SocketStore.add(ws);
            webSocketHandeler(id);
          }
        } else {
          final method = request.method;
          if (method == 'GET') {
            if (uri.path == '/getBlock') {
              print('got a get request');
              await getBlockRequestHandeler(uri, request.response);
            }

            await request.response.close();
          }
        }
      }
    },
    (err, st) {
      print(err);
      print(st);
    },
  );
  await initializeApp(parsedArgs);
  print('serving ${server.address.address}:${server.port}');
}
