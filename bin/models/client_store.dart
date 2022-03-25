import 'package:freezed_annotation/freezed_annotation.dart';

import 'client_model/client_model.dart';

class ClientStore {
  ClientStore._();
  static ClientStore? _instance;
  static ClientStore get instance {
    _instance ??= ClientStore._();
    return _instance!;
  }

  final _clients = <Client>{
    Client("testClient"),
  };
  UnmodifiableSetView<Client> get clients => UnmodifiableSetView(_clients);

  bool add(Client client) {
    if (contains(client)) {
      return false;
    } else {
      _clients.add(client);
      return true;
    }
  }

  bool contains(Client client) {
    return _clients.contains(client);
  }

  bool containsById(String id) {
    for (final client in _clients) {
      if (client.clientId == id) return true;
    }
    return false;
  }

  Client getById(String clientId) {
    return _clients.firstWhere((element) => element.clientId == clientId);
  }
}
