import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/block_model/block_model.dart';
import '../../models/block_store.dart';
import '../../models/client_store.dart';
import '../../models/host_model/host_model.dart';
import '../../models/message_model/message_model.dart';
import '../host_message_handeler.dart';

/// Wraps a [WebSocketChannel] to handle supported socket operations
///
/// implements [IHostMessageHandeler]
@immutable
class HostMessageHandeler extends IHostMessageHandeler {
  /// The ip address of the device on the other side of the [WebSocketChannel].
  final String hostId;

  /// The communication channel between two nodes.
  final WebSocketChannel socket;

  /// The subscription of the listener on [socket]'s stream
  late final StreamSubscription<dynamic>? _socketListener;

  /// Constructs a [HostMessageHandeler] based on a
  /// [WebSocketChannel] and the other ends ip address
  HostMessageHandeler(this.socket, this.hostId) {
    /// Registers the listener on [socket]
    _socketListener = socket.stream.listen(
      (message) {
        final decodedMessage = Message.fromJson(message);

        /// Register the handelers implemented from [IHostMessageHandeler]
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
        print(err);
        print(st);
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
    /// Checks if [BlockStore] knows [blockId] because
    /// Overriding a prexisting block is undesirable.
    if (BlockStore.contains(blockId)) {
      final block = BlockStore.get(blockId)!;

      /// Since the block is found we need to trigger a [blockLookUpResponse]
      final response = Message.blockLookUpResponse(block);
      socket.sink.add(response.asJson);
    } else {
      /// Add the current [Host] as an exception so that other nodes
      /// don't fall into a circular request chain
      final newExceptions = [...exceptions, HostStore.thisHost];

      /// We prepare another [blockLookUpRequest] since the block
      /// does not exist in [Host] and forward it to other nodes
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
      /// The block is found
      final block = BlockStore.get(blockId)!;
      socket.sink.add(block.asJson);
    } else {
      /// We prepare another [blockLookUpRequest] since the block
      /// does not exist in [Host] and forward it to other nodes
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
