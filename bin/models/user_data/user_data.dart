import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user_data.freezed.dart';
part 'user_data.g.dart';

@freezed
class UserData with _$UserData {
  const UserData._();
  String get hash => sha256
      .convert(
        utf8.encode(jsonEncode(toJson())),
      )
      .toString();
  const factory UserData({
    required String id,
    required String ssid,
    required String name,
    required String email,
    required String gender,
    required String address,
    required String dateOfBirth,
    required String phoneNumber,
  }) = _UserData;
  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
