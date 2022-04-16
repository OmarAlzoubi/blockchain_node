import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'blockchain.dart';
import 'helpers.dart';
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
        blockLookUpResponse: (block) async {
          await BlockChain().add(block);
        },
        addBlock: (block) async {
          await BlockChain().add(block);
        },
        transaction: (transaction) async {
          await BlockChain().addTransaction(transaction);
        },
        propagateBlockChange: (oldBlock, newBlock) async {
          if (BlockChain().contains(oldBlock.hash)) {
            await BlockChain().propagateBlockChange(oldBlock, newBlock);
          }
        },
      );
    },
  );
}

Future getBlockRequestHandeler(
  HttpRequest request,
  HttpResponse response,
) async {
  final params = request.uri.queryParameters;
  final hash = params['hash'];
  final blockChain = BlockChain();
  if (hash != null) {
    if (blockChain.contains(hash)) {
      final block = blockChain.get(hash)!;
      final blockAsJson = jsonEncode(block);
      response.write(blockAsJson);
    } else {
      final message = Message.blockLookupRequest([], hash);
      SocketStore.broadcast(message);
      final completer = Completer();
      bool timedOut = false;
      Stream.fromFuture(
        blockChain.hashStream.firstWhere(
          (element) => element.containsKey(hash),
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
        final block = blockChain.get(hash)!;
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
  BlockChain(
    blocksFolderName: args.blocksFolderName,
  );
  await HostStore.initialize(
    args.hostsFileName,
    Host('127.0.0.1', args.port),
  );
}

Future<void> main(List<String> args) async {
  final parsedArgs = parseArguments(args);

  final httpSocket = await ServerSocket.bind(
    '0.0.0.0',
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
            print('got a get request');
            if (uri.path == '/getBlock') {
              await getBlockRequestHandeler(request, request.response);
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
