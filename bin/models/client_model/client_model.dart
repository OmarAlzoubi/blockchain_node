import 'package:freezed_annotation/freezed_annotation.dart';
part 'client_model.freezed.dart';
part 'client_model.g.dart';

@freezed
class Client with _$Client {
  const factory Client(String clientId) = _Client;
  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
}
