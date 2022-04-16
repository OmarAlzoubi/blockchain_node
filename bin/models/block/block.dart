import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../transaction/transaction.dart';
part 'block.freezed.dart';

part 'block.g.dart';

@freezed
class Block with _$Block {
  const Block._();

  bool isBlockInFileSystemSync({
    String folderName = "blocks",
  }) {
    final file = File('$folderName/$hash.json');
    return file.existsSync();
  }

  static Block? loadBlockSync({
    required String filePath,
  }) {
    final file = File(filePath);
    if (file.existsSync()) {
      final fileAsString = file.readAsStringSync();
      final block = Block.fromJson(jsonDecode(fileAsString));
      return block;
    }
    return null;
  }

  Future<void> saveBlockSync({
    String folderName = "blocks",
  }) async {
    final blocksDir = Directory(folderName);
    if (!blocksDir.existsSync()) {
      blocksDir.createSync();
    }
    final file = File('$folderName/$hash.json');
    file.createSync();
    file.writeAsStringSync(jsonEncode(toJson()));
  }

  Future<void> saveBlock({
    String folderName = "blocks",
  }) async {
    final blocksDir = Directory(folderName);
    if (!await blocksDir.exists()) {
      await blocksDir.create();
    }
    final file = File('$folderName/$hash.json');
    await file.create();
    await file.writeAsString(jsonEncode(toJson()));
  }

  Future<void> deleteBlock({
    String folderName = "blocks",
  }) async {
    final file = File('$folderName/$hash.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Block addTransaction(Transaction transaction) {
    final Block newBlock = mapOrNull(
      transactional: (block) {
        return block.copyWith(
          transactions: {...block.transactions, transaction},
        );
      },
    )!;

    return newBlock;
  }

  String get hash => sha256
      .convert(
        utf8.encode(jsonEncode(toJson())),
      )
      .toString();
  const factory Block.genesis({
    required String previousHash,
    required String timestamp,
    required int voteCost,
    required int maximumVotingCredit,
    @Default(true) bool closed,
  }) = _GenesisBlock;

  const factory Block.transactional({
    required String previousHash,
    required String timestamp,
    @Default(false) bool closed,
    @Default({}) Set<Transaction> transactions,
  }) = _TransactionalBlock;

  factory Block.fromJson(dynamic json) => _$BlockFromJson(json);
}
