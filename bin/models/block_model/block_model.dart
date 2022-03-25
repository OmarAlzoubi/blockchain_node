import 'package:freezed_annotation/freezed_annotation.dart';
part 'block_model.freezed.dart';

part 'block_model.g.dart';

@freezed
class Block with _$Block {
  const factory Block(
    String hash,
    String blockId,
    String blockData,
  ) = _Block;
  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
}
