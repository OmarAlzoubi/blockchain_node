import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/block_store.dart';
import 'models/client_store.dart';
import 'models/request_model/request_model.dart';

final container = ProviderContainer();
Future<void> main() async {
  final clients = ClientStore.instance;
  final blocks = BlockStore.instance;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final handler = Pipeline().addHandler(
    webSocketHandler(
      (WebSocketChannel socket) async {
        socket.stream.listen(
          (event) {
            final request = ConcreteRequest.fromJson(jsonDecode(event));
            request.when(
              connectionRequest: (client) {
                if (client.clientId == "uniqueId") {
                  final id = Uuid().v4();
                  clients.add(client.copyWith(clientId: id));
                  socket.sink.add(id);
                }
                if (!clients.contains(client)) {
                  clients.add(client);
                }
              },
              blockRequest: (client, blockId) {
                if (clients.contains(client)) {
                  print('$client has requested $blockId');
                  if (blocks.containsById(blockId)) {
                    print('$client will get $blockId');
                    socket.sink.add(blocks.getById(blockId));
                  } else {
                    socket.sink.add("Block $blockId does not exist");
                  }
                }
              },
              createBlock: (client, block) {
                if (clients.contains(client)) {
                  blocks.add(block);
                  socket.sink.add('Block Created');
                  socket.sink.add(block);
                }
              },
            );
          },
        );
      },
    ),
  );

  final server = await shelf_io.serve(
    handler,
    '127.0.0.1',
    port,
  );
  print('Serving at http://${server.address.host}:${server.port}');
}
