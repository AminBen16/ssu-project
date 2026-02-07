package com.example.test

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Initialize MeshService and pass the binary messenger
        MeshService.getInstance(flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Optionally, stop the service or clean up resources
        // For a service running in background, you might not want to stop it here
    }
}