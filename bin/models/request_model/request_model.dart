import 'package:freezed_annotation/freezed_annotation.dart';

import '../block_model/block_model.dart';
import '../client_model/client_model.dart';
part 'request_model.freezed.dart';
part 'request_model.g.dart';

abstract class RequestModel {
  Client get client;
}

@freezed
class ConcreteRequest with _$ConcreteRequest {
  @Implements<RequestModel>()
  const factory ConcreteRequest.connectionRequest(
    Client client,
  ) = _ConcreteRequestConnectionRequest;
  @Implements<RequestModel>()
  const factory ConcreteRequest.createBlock(
    Client client,
    Block block,
  ) = _ConcreteRequestCreateBlock;

  @Implements<RequestModel>()
  const factory ConcreteRequest.blockRequest(
    Client client,
    String blockId,
  ) = _ConcreteRequestBlockRequest;
  factory ConcreteRequest.fromJson(Map<String, dynamic> json) =>
      _$ConcreteRequestFromJson(json);
}
