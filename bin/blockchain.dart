import 'dart:io';

import 'package:rxdart/rxdart.dart';

import 'models/block/block.dart';
import 'models/message_model/message_model.dart';
import 'models/socket_store.dart';
import 'models/transaction/transaction.dart';

typedef BlockChainMap = Map<Block, Set<Block>>;
typedef HashBlockMap = Map<String, Block>;

class BlockChain {
  late final BehaviorSubject<BlockChainMap> blockchainMap;
  Stream<BlockChainMap> get stream => blockchainMap.stream;

  final _blockchainMemo = BehaviorSubject<HashBlockMap>.seeded({});
  Stream<HashBlockMap> get hashStream => _blockchainMemo.stream;

  Iterable<Block> get blocks => blockchainMap.value.keys;

  static final genesisBLock = Block.genesis(
    previousHash: "0",
    timestamp: "1650018092",
    voteCost: 1,
    maximumVotingCredit: 1000,
  );

  static BlockChain? _instance;

  final String folderName;

  factory BlockChain({String? blocksFolderName}) {
    if (_instance == null) {
      if (!genesisBLock.isBlockInFileSystemSync()) {
        genesisBLock.saveBlockSync(folderName: blocksFolderName!);
      }
      final blocksDir = Directory(blocksFolderName ?? "blocks");
      final BlockChainMap blockChain = {};
      final blocks = <Block>[];
      if (blocksDir.existsSync()) {
        for (final entity in blocksDir.listSync()) {
          final block = Block.loadBlockSync(filePath: entity.path)!;
          blocks.add(block);
          blockChain[block] = {};
        }
        for (final outerBlock in blocks) {
          final outerHash = outerBlock.hash;

          for (final innerBlock in blocks) {
            if (innerBlock == outerBlock) continue;
            final innerPrevHash = innerBlock.previousHash;
            if (innerPrevHash == outerHash) {
              blockChain[outerBlock]!.add(innerBlock);
            }
          }
        }

        _instance = BlockChain._(blockChain, blocksFolderName!);
        return _instance!;
      } else {
        print('Blocks directory does not exist');
        exit(1);
      }
    } else {
      return _instance!;
    }
  }
  BlockChain._(
    BlockChainMap nodes,
    this.folderName,
  ) {
    blockchainMap = BehaviorSubject<BlockChainMap>.seeded(nodes);
    stream.listen(calculateHashMap);
  }
  void calculateHashMap(BlockChainMap map) {
    _blockchainMemo.sink.add({});
    final HashBlockMap newHashes = {};
    //print('isBlockChainMap null in calculateHash? ${map == null}');
    for (final entry in map.entries) {
      newHashes[entry.key.hash] = entry.key;
    }
    _blockchainMemo.sink.add(newHashes);
  }

  Future<void> propagateBlockChange(Block oldBlock, Block newBlock) async {
    final blockChainCopy = blockchainMap.value;

    final dependants = blockChainCopy[oldBlock] ?? {};

    blockChainCopy.remove(oldBlock);

    blockChainCopy[newBlock] = {};

    await newBlock.saveBlock(folderName: folderName);
    await oldBlock.deleteBlock(folderName: folderName);

    for (final dependant in dependants) {
      final newDependenant = oldBlock.copyWith(
        previousHash: newBlock.hash,
      );
      await propagateBlockChange(dependant, newDependenant);
      blockChainCopy[newBlock]!.add(newDependenant);
    }
    blockchainMap.add(blockChainCopy);
    //print('new Blockchain" $blockChainCopy');
  }

  Future<void> addTransaction(Transaction transaction) async {
    for (final block in blocks) {
      // We're looking for an open block
      if (block.closed) continue;
      // Since a block's hash changes every time a transaction is added
      // We need to propagate the change to all blocks
      final newBlock = block.addTransaction(transaction);
      await propagateBlockChange(block, newBlock);
      SocketStore.broadcast(Message.propagateBlockChange(block, newBlock));
      return;
    }
  }

  void replaceBlock(Block oldBlock, Block newBlock) {}
  bool contains(String hash) {
    return _blockchainMemo.value.containsKey(hash);
  }

  bool notContains(String hash) => !contains(hash);

  Block? get(String hash) {
    return _blockchainMemo.value[hash];
  }

  Future<void> add(Block block) async {
    final newBlocks = blockchainMap.value;
    newBlocks[block] = {};
    blockchainMap.add(newBlocks);

    await block.saveBlock(folderName: folderName);
  }

  Set<Block>? operator [](Block hash) {
    return blockchainMap.value[hash];
  }

  void operator []=(Block hash, Set<Block> val) {
    blockchainMap.value[hash] = val;
  }

  @override
  String toString() {
    return blockchainMap.value.toString();
  }
}
