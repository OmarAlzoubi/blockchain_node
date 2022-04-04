import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'interfaces/impl/host_message_handeler.dart';
import 'models/block_store.dart';
import 'models/client_store.dart';
import 'models/message_model/message_model.dart';

class MRouter {
  static const _webSocket = '/';
  static const _getBlock = '/getBlock/<blockId>';

  late final Router router;
  MRouter() {
    router = Router();
    router.get(_webSocket, webSocketRouteHandeler);
    router.get(_getBlock, getBlockRouteHandeler);
  }

  Future<Response> webSocketRouteHandeler(Request request) async {
    return webSocketHandler(
      (WebSocketChannel socket) {
        final hostId = request.headers['host']!;
        final handeler = HostMessageHandeler(socket, hostId);
        HostStore.add(hostId, handeler);
      },
    ).call(request);
  }

  Future<Response> getBlockRouteHandeler(
    Request request,
    String blockId,
  ) async {
    if (BlockStore.contains(blockId)) {
      final block = BlockStore.get(blockId)!;
      return Response.ok(block.asJson);
    } else {
      HostStore.broadcastMessage(
        Message.blockLookupRequest([], blockId),
      );
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
        final block = BlockStore.get(blockId)!;
        return Response.ok(block.asJson);
      }

      return Response.ok('block-not-found');
    }
  }
}
