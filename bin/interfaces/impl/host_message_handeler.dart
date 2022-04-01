import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/block_model/block_model.dart';
import '../../models/block_store.dart';
import '../../models/client_store.dart';
import '../../models/host_model/host_model.dart';
import '../../models/message_model/message_model.dart';
import '../host_message_handeler.dart';

class HostMessageHandeler extends IHostMessageHandeler {
  WebSocketChannel socket;
  final String hostId;
  StreamSubscription<dynamic>? _socketListener;

  HostMessageHandeler(this.socket, this.hostId) {
    _socketListener = socket.stream.listen(
      (message) {
        final decodedMessage = Message.fromJson(jsonDecode(message));
        decodedMessage.when(
          getBlock: getBlock,
          addBlock: addBlock,
          blockLookupRequest: blockLookUpRequest,
          blockLookUpResponse: blockLookUpResponse,
        );
      },
      onDone: () {
        print('ws has closed');
        print(socket.closeReason);
        _socketListener?.cancel();
      },
      onError: (err, st) {
        print('an error occured');
        _socketListener?.cancel();
      },
    );
  }

  @override
  void blockLookUpResponse(Block block) async {
    BlockStore.add(block);
  }

  @override
  void blockLookUpRequest(List<Host> exceptions, String blockId) {
    if (BlockStore.contains(blockId)) {
      final block = BlockStore.get(blockId)!;
      final message = Message.blockLookUpResponse(block);
      final encodedMessage = jsonEncode(message);

      socket.sink.add(encodedMessage);
    } else {
      final newExceptions = [...exceptions, HostStore.thisHost];
      final message = Message.blockLookupRequest(
        newExceptions,
        blockId,
      );
      HostStore.broadcastMessageToExcept(message, newExceptions);
    }
  }

  @override
  void getBlock(String blockId) {
    if (BlockStore.contains(blockId)) {
      final block = BlockStore.get(blockId);
      final encodedBlock = jsonEncode(block);

      socket.sink.add(encodedBlock);
    } else {
      HostStore.broadcastMessage(
        Message.blockLookupRequest([HostStore.thisHost], blockId),
      );
    }
  }

  @override
  void addBlock(Block block) {
    BlockStore.add(block);
  }

  @override
  void dispose() {
    _socketListener?.cancel();
  }
}
