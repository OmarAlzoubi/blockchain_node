import 'package:freezed_annotation/freezed_annotation.dart';

import '../block/block.dart';
import '../host_model/host_model.dart';
import '../transaction/transaction.dart';
part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class Message with _$Message {
  const Message._();
  const factory Message.blockLookupRequest(
    List<Host> exceptions,
    String hash,
  ) = _MessageBlockLookupRequest;

  const factory Message.blockLookUpResponse(
    Block block,
  ) = _MessageBlockLookUpResponse;

  const factory Message.addBlock(
    Block block,
  ) = _MessageAddBlock;

  const factory Message.transaction(
    Transaction transaction,
  ) = _MessageTransaction;

  const factory Message.getBlock(
    String hash,
  ) = _MessageGetBlock;

  const factory Message.propagateBlockChange(
    Block oldBlock,
    Block newBlock,
  ) = _MessagePropagateBlockChange;

  factory Message.fromJson(dynamic json) => _$MessageFromJson(json);
}
