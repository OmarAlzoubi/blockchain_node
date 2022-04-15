import 'package:freezed_annotation/freezed_annotation.dart';

import '../block/block.dart';
import '../host_model/host_model.dart';
import '../transaction/transaction.dart';
part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class Message with _$Message {
  Message._();
  factory Message.blockLookupRequest(
    List<Host> exceptions,
    String hash,
  ) = _MessageBlockLookupRequest;

  factory Message.blockLookUpResponse(
    Block block,
  ) = _MessageBlockLookUpResponse;

  factory Message.addBlock(
    Block block,
  ) = _MessageAddBlock;

  factory Message.transaction(
    Transaction transaction,
  ) = _MessageTransaction;

  factory Message.getBlock(
    String hash,
  ) = _MessageGetBlock;

  factory Message.fromJson(dynamic json) => _$MessageFromJson(json);
}
