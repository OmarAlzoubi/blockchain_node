import 'package:freezed_annotation/freezed_annotation.dart';
part 'host_model.freezed.dart';
part 'host_model.g.dart';

@freezed
class Host with _$Host {
  const factory Host(
    String hostId,
    String ip,
    String port,
  ) = _Host;
  factory Host.fromJson(Map<String, dynamic> json) => _$HostFromJson(json);
}
