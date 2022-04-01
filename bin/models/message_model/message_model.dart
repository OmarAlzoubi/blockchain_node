import 'package:freezed_annotation/freezed_annotation.dart';

import '../block_model/block_model.dart';
import '../host_model/host_model.dart';
part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class Message with _$Message {
  const factory Message.blockLookupRequest(
    List<Host> exceptions,
    String blockId,
  ) = _MessageBlockLookupRequest;

  const factory Message.blockLookUpResponse(
    Block block,
  ) = _MessageBlockLookUpResponse;

  const factory Message.addBlock(
    Block block,
  ) = _MessageAddBlock;

  const factory Message.getBlock(
    String blockId,
  ) = _MessageGetBlock;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
