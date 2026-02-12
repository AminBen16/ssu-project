import 'dart:developer' as developer;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service to manage the backend Dart server process for desktop applications
class BackendServerService {
  Process? _serverProcess;
  bool _isRunning = false;
  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  /// Stream of server logs
  Stream<String> get logs => _logController.stream;

  /// Stream of server status changes
  Stream<bool> get status => _statusController.stream;

  /// Whether the server is currently running
  bool get isRunning => _isRunning;

  /// Start the backend server
  Future<bool> startServer() async {
    if (_isRunning) {
      developer.log('Server is already running');
      return true;
    }

    try {
      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final serverDir = path.join(appDir.path, 'school_server');

      // Check if server directory exists
      if (!Directory(serverDir).existsSync()) {
        developer.log('Server directory not found: $serverDir');
        return false;
      }

      // Path to the server executable
      final serverExecutable = _getServerExecutablePath(serverDir);

      if (serverExecutable == null) {
        developer.log('Server executable not found');
        return false;
      }

      // Configure database path for desktop
      final dbPath = path.join(appDir.path, 'school_server.db');

      // Start the server process
      _serverProcess = await Process.start(
        serverExecutable,
        ['--database-path', dbPath],
        workingDirectory: serverDir,
      );

      _isRunning = true;
      _statusController.add(true);

      // Listen to stdout
      _serverProcess!.stdout.transform(utf8.decoder).listen((data) {
        _logController.add('STDOUT: $data');
        developer.log('Server STDOUT: $data');
      });

      // Listen to stderr
      _serverProcess!.stderr.transform(utf8.decoder).listen((data) {
        _logController.add('STDERR: $data');
        developer.log('Server STDERR: $data');
      });

      // Listen to process exit
      _serverProcess!.exitCode.then((exitCode) {
        _isRunning = false;
        _statusController.add(false);
        _logController.add('Server exited with code: $exitCode');
        developer.log('Server exited with code: $exitCode');
      });

      // Wait a bit for server to start
      await Future.delayed(const Duration(seconds: 2));

      developer.log('Backend server started successfully');
      return true;
    } catch (e) {
      developer.log('Failed to start backend server: $e');
      _isRunning = false;
      _statusController.add(false);
      return false;
    }
  }

  /// Stop the backend server
  Future<void> stopServer() async {
    if (!_isRunning || _serverProcess == null) {
      return;
    }

    try {
      // Send SIGTERM to gracefully stop the server
      _serverProcess!.kill(ProcessSignal.sigterm);

      // Wait for process to exit
      await _serverProcess!.exitCode.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Force kill if it doesn't exit gracefully
          _serverProcess!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      _isRunning = false;
      _statusController.add(false);
      developer.log('Backend server stopped');
    } catch (e) {
      developer.log('Error stopping server: $e');
    }
  }

  /// Get the path to the server executable based on platform
  String? _getServerExecutablePath(String serverDir) {
    if (Platform.isWindows) {
      return path.join(serverDir, 'bin', 'server.exe');
    } else if (Platform.isMacOS || Platform.isLinux) {
      return path.join(serverDir, 'bin', 'server');
    }
    return null;
  }

  /// Dispose of resources
  void dispose() {
    stopServer();
    _logController.close();
    _statusController.close();
  }
}
