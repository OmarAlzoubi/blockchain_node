import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:rxdart/subjects.dart';

import 'block_model/block_model.dart';

/// A singleton class, abstracts dealing with block files
///
/// [isInitialized] is a flag that tells whether the initiallization
class BlockStore {
  static bool isInitialzed = false;

  /// The name of the folder where blocks are stored
  static late final String _folderName;

  /// The current state of the store
  static final _blocks = BehaviorSubject<Map<String, Block>>.seeded({});
  static Stream<Map<String, Block>> get stream => _blocks.stream;
  static UnmodifiableMapView<String, Block> get blocks => UnmodifiableMapView(
        _blocks.value,
      );

  /// Loads all blocks in [folderName]
  static Future<void> initialize(String folderName) async {
    /// Set the initialization flag
    isInitialzed = true;
    _folderName = folderName;

    final blocksDirectory = Directory(folderName);
    final blocks = <String, Block>{};
    if (await blocksDirectory.exists()) {
      await for (final entry in blocksDirectory.list()) {
        final file = File(entry.path);
        final fileAsString = await file.readAsString();
        final block = Block.fromJson(fileAsString);
        blocks[block.blockId] = block;
      }
      _blocks.add(blocks);
    } else {
      await blocksDirectory.create();
    }
  }

  static Block? get(String blockId) {
    return _blocks.value[blockId];
  }

  /// Adds block to store and saves a copy to storage
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
        await blockFile.writeAsString(block.asJson);
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
