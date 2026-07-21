import '../events/events.dart';

/// Owns process-wide platform services that must be initialized once when the
/// server starts and disposed when the server shuts down.
class PlatformRuntime {
  PlatformRuntime._();

  static final PlatformRuntime instance = PlatformRuntime._();

  late final EventBus eventBus;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    eventBus = EventBus();
    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;

    await eventBus.dispose();
    _initialized = false;
  }
}
