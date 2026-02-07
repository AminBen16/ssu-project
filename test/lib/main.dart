import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/communication_service.dart';
import 'package:test/services/auxiliary_services.dart';
import 'package:test/services/platform_channels.dart';
import 'package:test/services/platform_channels_web.dart';
import 'package:test/services/transport_manager.dart';
import 'package:test/services/message_storage.dart';
import 'package:test/services/local_database_service.dart';
import 'package:test/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize LocalDatabaseService with error handling for path_provider issues
  LocalDatabaseService? localDatabaseService;
  try {
    localDatabaseService = LocalDatabaseService();
    await localDatabaseService.initialize();
    print('LocalDatabaseService initialized successfully');
  } catch (e) {
    print('Failed to initialize LocalDatabaseService: $e');
    print('Continuing with in-memory storage only');
  }

  // Initialize communication services
  // Using InMemoryMessageStorage to ensure interface compliance.
  // In production, LocalDatabaseService should implement MessageStorage.
  final MessageStorage messageStorage =
      localDatabaseService as MessageStorage? ?? InMemoryMessageStorage();

  final localDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
  final encryptionKey = 'school-mesh-secret-key-2024';

  final transportManager = LocalTransportManager(localDeviceId);
  final peerDiscovery = LocalPeerDiscovery();

  // Initialize platform channels conditionally based on platform
  MeshPlatformChannels meshChannels;
  if (kIsWeb) {
    meshChannels = MeshPlatformChannelsWeb();
  } else {
    meshChannels = MeshPlatformChannelsImpl();
    await meshChannels.initialize();
  }

  // Create communication service instances
  final communicationService = CommunicationService(
    storage: messageStorage,
    transport: transportManager,
    discovery: peerDiscovery,
    localDeviceId: localDeviceId,
    encryptionKey: encryptionKey,
  );

  final emergencyMode = EmergencyMode(
    communicationService: communicationService,
    platformChannels: meshChannels,
  );

  final batteryOptimization = BatteryOptimizationService(
    meshChannels,
  );

  final failureHandling = FailureHandlingService(
    meshChannels,
  );

  // Initialize services
  await communicationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        Provider<CommunicationService>.value(value: communicationService),
        Provider<EmergencyMode>.value(value: emergencyMode),
        Provider<BatteryOptimizationService>.value(value: batteryOptimization),
        Provider<FailureHandlingService>.value(value: failureHandling),
        Provider<MessageStorage>.value(value: messageStorage),
        if (localDatabaseService != null)
          Provider<LocalDatabaseService>.value(value: localDatabaseService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeMode _parseThemeMode(String themeModeString) {
    switch (themeModeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the UserDataProvider when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserDataProvider>(context, listen: false).initialize();
    });

    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, child) {
        return MaterialApp(
          title: 'SSU - School System Uganda',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: userDataProvider.userProfile?.themeColor != null
                  ? Color(userDataProvider.userProfile!.themeColor!)
                  : Colors.blue,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: userDataProvider.userProfile?.themeColor != null
                  ? Color(userDataProvider.userProfile!.themeColor!)
                  : Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: userDataProvider.userProfile?.themeMode != null
              ? _parseThemeMode(userDataProvider.userProfile!.themeMode!)
              : ThemeMode.system,
          home: const AuthWrapper(),
          onGenerateRoute: (settings) {
            // Fallback for unknown routes
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Page Not Found')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Page Not Found',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The requested page could not be found.\nRoute: ${settings.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
