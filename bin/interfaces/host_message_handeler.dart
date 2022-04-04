import '../models/block_model/block_model.dart';
import '../models/host_model/host_model.dart';

abstract class IHostMessageHandeler {
  /// Handels incoming requests for a specific [blockId]
  void getBlock(String blockId);

  /// Handels requests that need to add a [Block] to [HostStore]
  void addBlock(Block block);

  /// Triggered by get [getBlock] if [HostStore] does not know
  /// about [blockId]
  ///
  /// [exceptions] is the list of [Host]s that will be forwarded
  /// to other node to prevent circular requests.
  void blockLookUpRequest(List<Host> exceptions, String blockId);

  /// Tirggered by [blockLookUpRequest] when a block has been found.
  void blockLookUpResponse(Block block);

  /// Resource clean up
  void dispose();
}
