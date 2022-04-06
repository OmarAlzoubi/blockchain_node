import 'package:freezed_annotation/freezed_annotation.dart';
part 'host_model.freezed.dart';
part 'host_model.g.dart';

/// Represents the network information about a node
///
/// [ip] is the ip address and [port]
/// is the port that the server is hosted ong
@freezed
class Host with _$Host {
  const factory Host(
    String ip,
    int port,
  ) = _Host;
  factory Host.fromJson(Map<String, dynamic> json) => _$HostFromJson(json);
}
