import 'dart:collection';

import 'block_model/block_model.dart';

class BlockStore {
  BlockStore._();
  static BlockStore? _instance;
  static BlockStore get instance {
    _instance ??= BlockStore._();
    return _instance!;
  }

  final _blocks = <Block>{};
  UnmodifiableSetView<Block> get blocks => UnmodifiableSetView(_blocks);

  bool add(Block client) {
    if (contains(client)) {
      return false;
    } else {
      _blocks.add(client);
      return true;
    }
  }

  bool contains(Block client) {
    return _blocks.contains(client);
  }

  bool containsById(String blockId) {
    for (final client in _blocks) {
      if (client.blockId == blockId) return true;
    }
    return false;
  }

  Block getById(String blockId) {
    return _blocks.firstWhere((element) => element.blockId == blockId);
  }
}
