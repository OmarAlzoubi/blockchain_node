import 'package:args/args.dart';

class ParsingResults {
  final int port;
  final String hostsFileName;
  final String blocksFolderName;

  const ParsingResults({
    required this.port,
    required this.hostsFileName,
    required this.blocksFolderName,
  });
}

ParsingResults parseArguments(List<String> args) {
  final parser = ArgParser();
  parser.addOption('port', abbr: 'p', defaultsTo: '8080');
  parser.addOption('hosts', abbr: 'h', defaultsTo: 'hosts.json');
  parser.addOption('blocks', abbr: 'b', defaultsTo: 'blocks');
  final parserResults = parser.parse(args);
  return ParsingResults(
    port: int.parse(parserResults['port']),
    hostsFileName: parserResults['hosts'] as String,
    blocksFolderName: parserResults['blocks'] as String,
  );
}
