import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../user_data/user_data.dart';
part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const Transaction._();
  String get hash => sha256
      .convert(
        utf8.encode(jsonEncode(toJson())),
      )
      .toString();

  const factory Transaction.addVoter({
    required String transactionId,
    required String timestamp,
    required UserData voterData,
    @Default(0) int voteCredit,
  }) = _AddVoterTransaction;
  const factory Transaction.addCandidate({
    required String transactionId,
    required String timestamp,
    required UserData candidateData,
    required String party,
    @Default(0) int voteCredit,
    @Default(0) int voteCount,
  }) = _AddCandidateTransaction;
  const factory Transaction.vote({
    required String transactionId,
    required String timestamp,
    required String candidateId,
    required String voterId,
  }) = _VoteTransaction;
  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
