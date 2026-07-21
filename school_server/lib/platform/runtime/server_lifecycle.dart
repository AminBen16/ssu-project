import 'platform_runtime.dart';

/// Coordinates startup and shutdown of platform-level services.
///
/// This is intentionally separate from the HTTP server implementation so the
/// same lifecycle contract can later be used by HTTP, worker, and test
/// processes without duplicating initialization logic.
class ServerLifecycle {
  ServerLifecycle({PlatformRuntime? platformRuntime})
      : _platformRuntime = platformRuntime ?? PlatformRuntime.instance;

  final PlatformRuntime _platformRuntime;
  bool _started = false;

  bool get isStarted => _started;

  Future<void> start() async {
    if (_started) return;
    await _platformRuntime.initialize();
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    await _platformRuntime.dispose();
    _started = false;
  }
}
