import 'dart:async';

import 'package:test/services/communication/messaging_interface.dart';

/// Manager for multiple transport layers
class DefaultTransportManager implements TransportManager {
  final List<TransportLayer> _transports;
  final StreamController<String> _combinedDataController =
      StreamController<String>.broadcast();

  DefaultTransportManager(this._transports);

  @override
  Stream<String> get dataStream => _combinedDataController.stream;

  @override
  Future<void> start() async {
    for (final transport in _transports) {
      await transport.initialize();
      await transport.start();
      transport.dataStream.listen((data) {
        _combinedDataController.add(data);
      });
    }
  }

  @override
  Future<void> stop() async {
    for (final transport in _transports) {
      await transport.stop();
    }
    await _combinedDataController.close();
  }

  @override
  Future<void> sendData(String data) async {
    bool sent = false;
    for (final transport in _transports) {
      if (await transport.isAvailable()) {
        try {
          await transport.sendData(data, 'all');
          sent = true;
          return;
        } catch (e) {
          continue;
        }
      }
    }
    if (!sent) {
      throw Exception('No transport available');
    }
  }

  @override
  Future<NetworkStatus> getNetworkStatus() async {
    for (final transport in _transports) {
      if (await transport.isAvailable()) {
        return transport.status;
      }
    }
    return NetworkStatus.offline;
  }
}
