import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'messaging_interface.dart'; // Import the messaging_interface.dart

class WebSocketTransportManager implements TransportManager {
  final String _url;
  WebSocketChannel? _channel;
  final _dataController = StreamController<String>.broadcast();
  final _networkStatusController = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.offline;
  final Logger _logger = Logger();

  WebSocketTransportManager({
    required String url,
    required String authToken,
  })  : _url = url;

  @override
  Future<void> start() async {
    _logger.i('Starting WebSocketTransportManager...');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      _currentStatus = NetworkStatus.connecting;
      _networkStatusController.add(NetworkStatus.connecting);

      _channel!.stream.listen(
        (data) {
          _dataController.add(data as String);
        },
        onDone: () {
          _logger.w('WebSocket channel closed. Attempting reconnect...');
          _currentStatus = NetworkStatus.offline;
          _networkStatusController.add(NetworkStatus.offline);
          _reconnect();
        },
        onError: (error) {
          _logger.e('WebSocket error: $error. Attempting reconnect...');
          _currentStatus = NetworkStatus.error;
          _networkStatusController.add(NetworkStatus.error);
          _reconnect();
        },
        cancelOnError: true,
      );

      _currentStatus = NetworkStatus.online;
      _networkStatusController.add(NetworkStatus.online);
      _logger.i('WebSocket connection established to $_url');
    } catch (e) {
      _logger.e('Failed to connect to WebSocket: $e');
      _currentStatus = NetworkStatus.offline;
      _networkStatusController.add(NetworkStatus.offline);
      _reconnect();
    }
  }

  @override
  Future<void> stop() async {
    _logger.i('Stopping WebSocketTransportManager...');
    try {
      await _channel?.sink.close();
      _currentStatus = NetworkStatus.offline;
      _networkStatusController.add(NetworkStatus.offline);
      _logger.i('WebSocket channel closed.');
    } catch (e) {
      _logger.e('Error stopping WebSocket: $e');
    }
  }

  @override
  Future<void> sendData(String data) async {
    if (_channel != null && _currentStatus == NetworkStatus.online) {
      try {
        _channel!.sink.add(data);
        _logger.d('Data sent: $data');
      } catch (e) {
        _logger.e('Failed to send data: $e');
        throw Exception('Failed to send data: $e');
      }
    } else {
      _logger.w('Attempted to send data while WebSocket is not connected.');
      throw Exception('WebSocket not connected.');
    }
  }

  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  Future<NetworkStatus> getNetworkStatus() async {
    // A more robust implementation would ping the server or check connectivity status regularly.
    // For now, we'll return the last known status.
    // Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;
    return _currentStatus;
  }

  void _reconnect() {
    // Implement a backoff strategy for reconnection
    Future.delayed(const Duration(seconds: 5), () {
      if (_currentStatus != NetworkStatus.online) {
        _logger.i('Attempting to reconnect WebSocket...');
        start();
      }
    });
  }
}
