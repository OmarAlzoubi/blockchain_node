import '../models/block_model/block_model.dart';
import '../models/host_model/host_model.dart';

abstract class IHostMessageHandeler {
  void getBlock(String blockId);
  void addBlock(Block block);

  void blockLookUpResponse(Block block);
  void blockLookUpRequest(List<Host> exceptions, String blockId);
  void dispose();
}
