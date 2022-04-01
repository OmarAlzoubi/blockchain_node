import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:rxdart/subjects.dart';

import 'block_model/block_model.dart';

class BlockStore {
  static bool isInitialzed = false;

  static late final String _folderName;

  static final _blocks = BehaviorSubject<Map<String, Block>>.seeded({});
  static Stream<Map<String, Block>> get stream => _blocks.stream;
  static UnmodifiableMapView<String, Block> get blocks => UnmodifiableMapView(
        _blocks.value,
      );

  static Future<void> initialize(String folderName) async {
    _folderName = folderName;
    final blocksDirectory = Directory(folderName);
    final blocks = <String, Block>{};
    if (await blocksDirectory.exists()) {
      await for (final entry in blocksDirectory.list()) {
        final file = File(entry.path);
        final fileAsString = await file.readAsString();
        final decodedJson = jsonDecode(fileAsString);
        final block = Block.fromJson(decodedJson);
        blocks[block.blockId] = block;
      }
      _blocks.add(blocks);
    } else {
      await blocksDirectory.create();
    }
    isInitialzed = true;
  }

  static Block? get(String blockId) {
    return _blocks.value[blockId];
  }

  static Future<void> add(Block block) async {
    if (!contains(block.blockId)) {
      final newBlocks = _blocks.value;
      newBlocks[block.blockId] = block;

      _blocks.add(newBlocks);

      final blocksDirectory = Directory(_folderName);
      if (await blocksDirectory.exists()) {
        final blockFile = await File(
          '${blocksDirectory.path}/${block.blockId}.json',
        ).create();
        final blockJson = block.toJson();
        final encodedBlock = jsonEncode(blockJson);
        await blockFile.writeAsString(encodedBlock);
      }
    }
  }

  static bool contains(String blockId) {
    return _blocks.value.containsKey(blockId) && _blocks.value[blockId] != null;
  }

  static void dispose() {
    _blocks.close();
  }
}
