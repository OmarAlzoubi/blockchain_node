import 'dart:async';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'helpers.dart';
import 'models/block_store.dart';
import 'models/client_store.dart';
import 'models/host_model/host_model.dart';
import 'router.dart';

Future<void> main(List<String> args) async {
  final parsedArgs = parseArguments(args);

  final router = MRouter();

  final server = await shelf_io.serve(
    router.router,
    '127.0.0.1',
    parsedArgs.port,
  );

  await BlockStore.initialize(parsedArgs.blocksFolderName);
  await HostStore.initialize(
    parsedArgs.hostsFileName,
    Host(
      'ws://127.0.0.1:${parsedArgs.port}',
      '127.0.0.1',
      parsedArgs.port.toString(),
    ),
  );
  print('Serving at http://${server.address.host}:${server.port}');
}
