import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../block_model/block_model.dart';
import '../host_model/host_model.dart';
part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class Message with _$Message {
  Message._();
  factory Message.blockLookupRequest(
    List<Host> exceptions,
    String blockId,
  ) = _MessageBlockLookupRequest;

  factory Message.blockLookUpResponse(
    Block block,
  ) = _MessageBlockLookUpResponse;

  factory Message.addBlock(
    Block block,
  ) = _MessageAddBlock;

  factory Message.getBlock(
    String blockId,
  ) = _MessageGetBlock;

  factory Message.fromJson(dynamic json) => _$MessageFromJson(jsonDecode(json));
  String get asJson => jsonEncode(this);
}
