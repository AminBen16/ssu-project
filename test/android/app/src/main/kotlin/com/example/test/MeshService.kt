package com.example.test

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pGroup
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.UUID
import java.util.concurrent.Executors

// Unique UUID for Bluetooth SPP service
private val BLUETOOTH_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB") // Standard SPP UUID
private const val SERVICE_NAME = "FlutterMeshService" // For Bluetooth SPP

// Notification Channel ID for Foreground Service
private const val NOTIFICATION_CHANNEL_ID = "MeshServiceChannel"
private const val NOTIFICATION_ID = 1337

// Wi-Fi Direct service discovery settings
private const val WIFI_P2P_SERVICE_PORT = 8888 // Port for Wi-Fi Direct socket communication

class MeshService : Service() {
    private val CHANNEL = "com.school.mesh/methods"
    private val PEER_CHANNEL = "com.school.mesh/peers"
    private val DATA_CHANNEL = "com.school.mesh/data"
    private val STATUS_CHANNEL = "com.school.mesh/status"

    private lateinit var flutterEngine: FlutterEngine
    private lateinit var methodChannel: MethodChannel
    private var peerEventSink: EventChannel.EventSink? = null
    private var dataEventSink: EventChannel.EventSink? = null
    private var statusEventSink: EventChannel.EventSink? = null

    // Android System Managers
    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var wifiP2pManager: WifiP2pManager? = null
    private var wifiP2pChannel: WifiP2pManager.Channel? = null

    // Mesh State
    private var isMeshInitialized = false
    private var isDiscovering = false
    private var isBackgroundModeEnabled = false

    // Peer and Connection Management
    private val discoveredPeersFlutter = mutableListOf<DiscoveredPeer>() // Peers sent to Flutter
    private val knownWifiP2pDevices = mutableListOf<WifiP2pDevice>() // Raw Wifi P2P devices
    private val activeConnections = mutableMapOf<String, ConnectionThread>() // peerId -> ConnectionThread
    private val executorService = Executors.newCachedThreadPool() // For running network tasks

    // Bluetooth Server Socket Listener
    private var bluetoothAcceptThread: BluetoothAcceptThread? = null

    // Wi-Fi Direct Server Socket Listener (for Group Owner)
    private var wifiP2pGroupOwnerThread: WifiP2pGroupOwnerThread? = null
    private var wifiP2pIsGroupOwner = false
    private var wifiP2pGroupOwnerAddress: InetAddress? = null


    // Broadcast Receivers
    private val meshBroadcastReceiver = object : BroadcastReceiver() {
        @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothAdapter.ACTION_STATE_CHANGED -> {
                    val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                    updateMeshStatus(
                        activeTransport = getCurrentMeshStatus().activeTransport,
                        isEnabled = state == BluetoothAdapter.STATE_ON || isWifiP2pEnabled()
                    )
                    Log.d("MeshService", "Bluetooth state changed: $state")
                }
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    device?.let {
                        if (checkBluetoothPermissions(context)) {
                            val peer = DiscoveredPeer(
                                deviceId = it.address,
                                deviceName = it.name ?: "Unknown Bluetooth Device",
                                transportType = "bluetooth",
                                isConnected = false,
                                signalStrength = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, 0).toInt(),
                                lastSeen = System.currentTimeMillis()
                            )
                            addDiscoveredPeer(peer)
                        }
                    }
                }
                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                    updateMeshStatus(
                        activeTransport = getCurrentMeshStatus().activeTransport,
                        isEnabled = state == WifiP2pManager.WIFI_P2P_STATE_ENABLED || (bluetoothAdapter?.isEnabled == true)
                    )
                    Log.d("MeshService", "Wi-Fi Direct state changed: $state")
                }
                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    wifiP2pManager?.requestPeers(wifiP2pChannel) { peers ->
                        peers?.deviceList?.forEach { device ->
                            Log.d("MeshService", "Discovered Wi-Fi Direct Peer: ${device.deviceName} (${device.deviceAddress})")
                            // Add to known devices, but don't immediately send to Flutter until connected or needed
                            if (!knownWifiP2pDevices.any { it.deviceAddress == device.deviceAddress }) {
                                knownWifiP2pDevices.add(device)
                            }
                            val peer = DiscoveredPeer(
                                deviceId = device.deviceAddress,
                                deviceName = device.deviceName,
                                transportType = "wifi_direct",
                                isConnected = false,
                                signalStrength = 0, // Wi-Fi direct doesn't provide RSSI directly
                                lastSeen = System.currentTimeMillis()
                            )
                            addDiscoveredPeer(peer)
                        }
                    }
                }
                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    val networkInfo = intent.getParcelableExtra<android.net.NetworkInfo>(WifiP2pManager.EXTRA_NETWORK_INFO)
                    if (networkInfo?.isConnected == true) {
                        wifiP2pManager?.requestConnectionInfo(wifiP2pChannel) { info ->
                            Log.d("MeshService", "Wi-Fi Direct connection info: isGroupOwner=${info.isGroupOwner}, groupOwnerAddress=${info.groupOwnerAddress}")
                            wifiP2pIsGroupOwner = info.isGroupOwner
                            wifiP2pGroupOwnerAddress = info.groupOwnerAddress

                            if (info.groupFormed && info.isGroupOwner) {
                                wifiP2pGroupOwnerThread?.cancel() // Cancel previous if any
                                wifiP2pGroupOwnerThread = WifiP2pGroupOwnerThread()
                                executorService.submit(wifiP2pGroupOwnerThread)
                                updateMeshStatus(activeTransport = "wifi_direct")
                            } else if (info.groupFormed) {
                                // Client connects to group owner
                                val peerAddress = info.groupOwnerAddress.hostAddress
                                Log.d("MeshService", "Wi-Fi Direct Client connecting to: $peerAddress")
                                // Need to find the WifiP2pDevice that has this address as its group owner address
                                val connectedDevice = knownWifiP2pDevices.firstOrNull { it.deviceName == info.groupOwnerAddress.hostAddress } // This might need refinement to correctly identify the peerId
                                if (connectedDevice != null) {
                                    connectToWifiP2pClient(connectedDevice.deviceAddress, info.groupOwnerAddress)
                                } else {
                                    // Fallback if not found in known devices (e.g., if we initiated connection to an unknown GO)
                                    connectToWifiP2pClient(info.groupOwnerAddress.hostAddress, info.groupOwnerAddress)
                                }

                                updateMeshStatus(activeTransport = "wifi_direct")
                            }
                        }
                    } else {
                        Log.d("MeshService", "Wi-Fi Direct Disconnected or not connected.")
                        updateMeshStatus(activeTransport = "none")
                        // Clear active Wi-Fi Direct connections
                        activeConnections.values.filter { it.connectionType == "wifi_direct" }.forEach {
                            it.cancel() // This removes it from activeConnections map
                        }
                        wifiP2pGroupOwnerThread?.cancel()
                        wifiP2pGroupOwnerThread = null
                        wifiP2pIsGroupOwner = false
                        wifiP2pGroupOwnerAddress = null
                    }
                }
                WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                    val device = intent.getParcelableExtra<WifiP2pDevice>(WifiP2pManager.EXTRA_WIFI_P2P_DEVICE)
                    Log.d("MeshService", "This device changed: ${device?.deviceName} status ${device?.status}")
                }
            }
        }
    }

    companion object {
        @Volatile
        private var INSTANCE: MeshService? = null

        fun getInstance(flutterEngine: FlutterEngine): MeshService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: MeshService().apply {
                    this.flutterEngine = flutterEngine
                    INSTANCE = this
                }
            }
        }

        fun getInstance(): MeshService? {
            return INSTANCE
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("MeshService", "Service created.")
        bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter
        wifiP2pManager = getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
        wifiP2pChannel = wifiP2pManager?.initialize(this, mainLooper, null)

        // Setup notification channel for foreground service
        setupNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("MeshService", "Service onStartCommand.")
        // If the service is explicitly started, ensure it stays running
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("MeshService", "Service destroyed. Cleaning up resources.")
        stopMeshNetworking()
        executorService.shutdownNow()
        INSTANCE = null // Clear singleton instance
    }

    private fun setupNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Mesh Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): NotificationCompat.Builder {
        val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Mesh Networking Active")
            .setContentText("Running in background for offline communication.")
            .setSmallIcon(android.R.drawable.ic_menu_share) // Replace with your app icon
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
    }

    private fun setupMethodChannel() {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeMesh" -> {
                    val success = initializeMeshNetworking()
                    result.success(success)
                }
                "startPeerDiscovery" -> {
                    startPeerDiscovery()
                    result.success(true)
                }
                "stopPeerDiscovery" -> {
                    stopPeerDiscovery()
                    result.success(true)
                }
                "sendDataToPeer" -> {
                    val peerId = call.argument<String>("peerId")
                    val data = call.argument<String>("data")
                    val success = sendDataToPeer(peerId, data)
                    result.success(success)
                }
                "broadcastData" -> {
                    val data = call.argument<String>("data")
                    val success = broadcastData(data)
                    result.success(success)
                }
                "getMeshStatus" -> {
                    val status = getCurrentMeshStatus()
                    result.success(status.toJson().toString())
                }
                "connectToPeer" -> {
                    val peerId = call.argument<String>("peerId")
                    val success = connectToPeer(peerId)
                    result.success(success)
                }
                "disconnectFromPeer" -> {
                    val peerId = call.argument<String>("peerId")
                    val success = disconnectFromPeer(peerId)
                    result.success(success)
                }
                "getConnectedPeers" -> {
                    result.success(activeConnections.keys.toList())
                }
                "enableBackgroundMode" -> {
                    enableBackgroundMode()
                    result.success(true)
                }
                "disableBackgroundMode" -> {
                    disableBackgroundMode()
                    result.success(true)
                }
                "sendFileChunk" -> {
                    val peerId = call.argument<String>("peerId")
                    val fileId = call.argument<String>("fileId")
                    val chunkIndex = call.argument<Int>("chunkIndex")
                    val chunkData = call.argument<String>("chunkData") // Base64 encoded
                    val success = sendFileChunk(peerId, fileId, chunkIndex, chunkData)
                    result.success(success)
                }
                "requestFileChunk" -> {
                    val peerId = call.argument<String>("peerId")
                    val fileId = call.argument<String>("fileId")
                    val chunkIndex = call.argument<Int>("chunkIndex")
                    val success = requestFileChunk(peerId, fileId, chunkIndex)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
        setupEventChannels()
    }

    private fun setupEventChannels() {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PEER_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    peerEventSink = events
                    // Send initial list of discovered peers
                    events.success(discoveredPeersFlutter.map { it.toJson().toString() }.toList())
                }
                override fun onCancel(arguments: Any?) {
                    peerEventSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    dataEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    dataEventSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STATUS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    statusEventSink = events
                    events.success(getCurrentMeshStatus().toJson().toString())
                }
                override fun onCancel(arguments: Any?) {
                    statusEventSink = null
                }
            })
    }

    // --- Mesh Networking Core Implementations ---

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun initializeMeshNetworking(): Boolean {
        if (isMeshInitialized) return true

        if (!checkBluetoothPermissions(this)) {
            Log.e("MeshService", "Bluetooth permissions not granted.")
            // Flutter should request permissions
            return false
        }

        val intentFilter = IntentFilter().apply {
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }
        registerReceiver(meshBroadcastReceiver, intentFilter)

        // Start Bluetooth server thread to accept incoming connections
        bluetoothAcceptThread = BluetoothAcceptThread()
        executorService.submit(bluetoothAcceptThread)

        Log.d("MeshService", "Mesh networking initialized.")
        isMeshInitialized = true
        updateMeshStatus(isEnabled = true, activeTransport = "none") // Initial state
        return true
    }

    private fun stopMeshNetworking() {
        if (!isMeshInitialized) return

        unregisterReceiver(meshBroadcastReceiver)
        stopPeerDiscovery()
        bluetoothAcceptThread?.cancel()
        bluetoothAcceptThread = null
        wifiP2pGroupOwnerThread?.cancel()
        wifiP2pGroupOwnerThread = null
        activeConnections.values.forEach { it.cancel() }
        activeConnections.clear()
        isMeshInitialized = false
        updateMeshStatus(isEnabled = false)
        Log.d("MeshService", "Mesh networking stopped and resources cleaned.")
    }

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun startPeerDiscovery() {
        if (!isMeshInitialized) {
            Log.w("MeshService", "Mesh not initialized, cannot start discovery.")
            return
        }
        if (isDiscovering) return

        Log.d("MeshService", "Starting peer discovery.")
        discoveredPeersFlutter.clear()
        knownWifiP2pDevices.clear()

        // Bluetooth discovery (Classic)
        bluetoothAdapter?.startDiscovery()

        // Wi-Fi Direct discovery
        wifiP2pManager?.discoverPeers(wifiP2pChannel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d("MeshService", "Wi-Fi Direct peer discovery initiated.")
            }
            override fun onFailure(reasonCode: Int) {
                Log.e("MeshService", "Wi-Fi Direct peer discovery failed: $reasonCode")
            }
        })

        isDiscovering = true
        updateMeshStatus(isDiscovering = true)
    }

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun stopPeerDiscovery() {
        if (!isDiscovering) return

        Log.d("MeshService", "Stopping peer discovery.")
        bluetoothAdapter?.cancelDiscovery()
        wifiP2pManager?.stopPeerDiscovery(wifiP2pChannel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d("MeshService", "Wi-Fi Direct peer discovery stopped.")
            }
            override fun onFailure(reasonCode: Int) {
                Log.e("MeshService", "Wi-Fi Direct stop discovery failed: $reasonCode")
            }
        })

        isDiscovering = false
        updateMeshStatus(isDiscovering = false)
    }

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun sendDataToPeer(peerId: String?, data: String?): Boolean {
        if (peerId == null || data == null) return false
        val connection = activeConnections[peerId]
        if (connection != null) {
            executorService.submit { connection.write(data.toByteArray()) }
            return true
        }
        Log.e("MeshService", "No active connection for peer: $peerId")
        return false
    }

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun broadcastData(data: String?): Boolean {
        if (data == null) return false
        if (activeConnections.isEmpty()) {
            Log.w("MeshService", "No active connections to broadcast data.")
            return false
        }
        activeConnections.values.forEach { connection ->
            executorService.submit { connection.write(data.toByteArray()) }
        }
        return true
    }

    private fun getCurrentMeshStatus(): MeshStatus {
        val btEnabled = bluetoothAdapter?.isEnabled ?: false
        val wifiP2pEnabled = isWifiP2pEnabled()
        return MeshStatus(
            isEnabled = btEnabled || wifiP2pEnabled,
            isDiscovering = isDiscovering,
            connectedPeersCount = activeConnections.size,
            activeTransport = getActiveTransportName(),
            backgroundModeEnabled = isBackgroundModeEnabled,
            batteryLevel = -1, // Not directly accessible from here, would need BatteryManager.BATTERY_PROPERTY_CAPACITY
            lowPowerMode = false
        )
    }

    private fun getActiveTransportName(): String {
        return when {
            activeConnections.values.any { it.connectionType == "wifi_direct" } -> "wifi_direct"
            activeConnections.values.any { it.connectionType == "bluetooth" } -> "bluetooth"
            else -> "none"
        }
    }

    private fun isWifiP2pEnabled(): Boolean {
        // This is a rough check, true status comes from WIFI_P2P_STATE_CHANGED_ACTION
        return wifiP2pManager != null && wifiP2pChannel != null
    }

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun connectToPeer(peerId: String?): Boolean {
        if (peerId == null) return false
        if (activeConnections.containsKey(peerId)) {
            Log.d("MeshService", "Already connected to $peerId")
            return true
        }

        // Try Bluetooth connection (MAC address pattern)
        if (peerId.matches(Regex("([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})"))) {
            Log.d("MeshService", "Attempting Bluetooth connection to $peerId")
            val device = bluetoothAdapter?.getRemoteDevice(peerId)
            if (device != null) {
                val clientThread = BluetoothClientThread(device)
                executorService.submit(clientThread)
                return true
            }
        }

        // Try Wi-Fi Direct connection
        val wifiDevice = knownWifiP2pDevices.firstOrNull { it.deviceAddress == peerId }
        if (wifiDevice != null) {
            Log.d("MeshService", "Attempting Wi-Fi Direct connection to ${wifiDevice.deviceName}")
            val config = WifiP2pConfig().apply {
                deviceAddress = wifiDevice.deviceAddress
                wps.setup = WifiP2pConfig.WPS_PBSC
            }
            wifiP2pManager?.connect(wifiP2pChannel, config, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d("MeshService", "Wi-Fi Direct connect initiated for ${wifiDevice.deviceName}")
                }
                override fun onFailure(reason: Int) {
                    Log.e("MeshService", "Wi-Fi Direct connect failed for ${wifiDevice.deviceName}: $reason")
                }
            })
            return true
        }

        Log.e("MeshService", "Could not connect to peer $peerId: Device not found or unsupported type.")
        return false
    }

    private fun connectToWifiP2pClient(peerId: String, groupOwnerAddress: InetAddress) {
        val clientThread = WifiP2pClientThread(peerId, groupOwnerAddress)
        executorService.submit(clientThread)
    }


    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun disconnectFromPeer(peerId: String?): Boolean {
        if (peerId == null) return false
        val connection = activeConnections.remove(peerId)
        connection?.cancel()

        // If it was a Wi-Fi Direct connection, consider removing the group if this device is GO
        if (wifiP2pIsGroupOwner && peerId.startsWith("wifi_direct")) { // Simplified check
            wifiP2pManager?.removeGroup(wifiP2pChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d("MeshService", "Wi-Fi Direct group removed upon disconnection.")
                }
                override fun onFailure(reason: Int) {
                    Log.e("MeshService", "Failed to remove Wi-Fi Direct group: $reason")
                }
            })
        }
        updateMeshStatus()
        Log.d("MeshService", "Disconnected from peer: $peerId")
        return true
    }

    private fun enableBackgroundMode() {
        if (!isBackgroundModeEnabled) {
            Log.d("MeshService", "Enabling background mode (Foreground Service).")
            val notification = createNotification().build()
            startForeground(NOTIFICATION_ID, notification)
            isBackgroundModeEnabled = true
            updateMeshStatus(backgroundModeEnabled = true)
        }
    }

    private fun disableBackgroundMode() {
        if (isBackgroundModeEnabled) {
            Log.d("MeshService", "Disabling background mode (Stopping Foreground Service).")
            stopForeground(true)
            isBackgroundModeEnabled = false
            updateMeshStatus(backgroundModeEnabled = false)
        }
    }

    private fun sendFileChunk(peerId: String?, fileId: String?, chunkIndex: Int?, chunkData: String?): Boolean {
        if (peerId == null || fileId == null || chunkIndex == null || chunkData == null) return false
        // A simple protocol for file chunks: "FILE_CHUNK:<fileId>:<chunkIndex>:<base64Data>"
        val fullChunkMessage = "FILE_CHUNK:$fileId:$chunkIndex:$chunkData"
        return sendDataToPeer(peerId, fullChunkMessage)
    }

    private fun requestFileChunk(peerId: String?, fileId: String?, chunkIndex: Int?): Boolean {
        if (peerId == null || fileId == null || chunkIndex == null) return false
        val requestMessage = "REQUEST_CHUNK:$fileId:$chunkIndex"
        return sendDataToPeer(peerId, requestMessage)
    }

    private fun addDiscoveredPeer(peer: DiscoveredPeer) {
        if (discoveredPeersFlutter.none { it.deviceId == peer.deviceId }) {
            discoveredPeersFlutter.add(peer)
            peerEventSink?.success(discoveredPeersFlutter.map { it.toJson().toString() }.toList())
            Log.d("MeshService", "Added discovered peer: ${peer.deviceName} (${peer.deviceId})")
        }
    }

    private fun updateMeshStatus(
        isEnabled: Boolean? = null,
        isDiscovering: Boolean? = null,
        connectedPeersCount: Int? = null,
        activeTransport: String? = null,
        backgroundModeEnabled: Boolean? = null,
        batteryLevel: Int? = null, // Battery level requires a separate broadcast receiver or BatteryManager
        lowPowerMode: Boolean? = null
    ) {
        val currentStatus = getCurrentMeshStatus() // Get current values for unspecified fields
        val newStatus = MeshStatus(
            isEnabled = isEnabled ?: currentStatus.isEnabled,
            isDiscovering = isDiscovering ?: currentStatus.isDiscovering,
            connectedPeersCount = connectedPeersCount ?: activeConnections.size,
            activeTransport = activeTransport ?: currentStatus.activeTransport,
            backgroundModeEnabled = backgroundModeEnabled ?: currentStatus.backgroundModeEnabled,
            batteryLevel = batteryLevel ?: currentStatus.batteryLevel,
            lowPowerMode = lowPowerMode ?: currentStatus.lowPowerMode
        )
        statusEventSink?.success(newStatus.toJson().toString())
        Log.d("MeshService", "Mesh Status Updated: ${newStatus.toJson()}")
    }

    // Helper to check Bluetooth permissions dynamically for newer Android versions
    private fun checkBluetoothPermissions(context: Context?): Boolean {
        if (context == null) return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // Android 12+
            context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                    context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
                    context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED
        } else { // Older versions require ACCESS_FINE_LOCATION for scanning
            context.checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    // --- Connection Thread Abstractions ---
    abstract inner class ConnectionThread(val peerId: String, val connectionType: String) : Runnable {
        protected var inputStream: InputStream? = null
        protected var outputStream: OutputStream? = null
        private var isRunning = true

        init {
            Log.d("ConnectionThread", "Starting $connectionType connection thread for $peerId")
            activeConnections[peerId] = this
            updateMeshStatus()
        }

        fun write(bytes: ByteArray) {
            try {
                outputStream?.write(bytes)
                outputStream?.flush()
                Log.d("ConnectionThread", "Sent ${bytes.size} bytes to $peerId via $connectionType")
            } catch (e: IOException) {
                Log.e("ConnectionThread", "Error writing to $peerId ($connectionType): ${e.message}")
                cancel()
            }
        }

        fun cancel() {
            isRunning = false
            try {
                inputStream?.close()
                outputStream?.close()
                closeSocket()
            } catch (e: IOException) {
                Log.e("ConnectionThread", "Error closing streams/socket for $peerId ($connectionType): ${e.message}")
            } finally {
                Log.d("ConnectionThread", "Connection to $peerId ($connectionType) cancelled.")
                activeConnections.remove(peerId)
                updateMeshStatus()
            }
        }

        override fun run() {
            val buffer = ByteArray(1024) // Read buffer
            var bytes: Int

            while (isRunning) {
                try {
                    bytes = inputStream?.read(buffer) ?: -1
                    if (bytes > 0) {
                        val receivedData = String(buffer, 0, bytes) // Assuming text data for now
                        Log.d("ConnectionThread", "Received $bytes bytes from $peerId ($connectionType): $receivedData")
                        dataEventSink?.success(receivedData)
                    } else if (bytes == -1) { // End of stream, connection lost
                        Log.d("ConnectionThread", "End of stream for $peerId ($connectionType). Disconnecting.")
                        cancel()
                        break
                    }
                } catch (e: IOException) {
                    Log.e("ConnectionThread", "Error reading from $peerId ($connectionType): ${e.message}")
                    cancel()
                    break
                }
            }
        }

        abstract fun closeSocket()
    }

    // --- Bluetooth Connection Threads ---

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    inner class BluetoothAcceptThread : Runnable {
        private val serverSocket: BluetoothServerSocket? by lazy(LazyThreadSafetyMode.NONE) {
            bluetoothAdapter?.listenUsingRfcommWithServiceRecord(SERVICE_NAME, BLUETOOTH_UUID)
        }
        private var isRunning = true

        override fun run() {
            var socket: BluetoothSocket? = null
            while (isRunning) {
                try {
                    Log.d("BluetoothAcceptThread", "Waiting for incoming Bluetooth connection...")
                    socket = serverSocket?.accept()
                } catch (e: IOException) {
                    Log.e("BluetoothAcceptThread", "Socket's accept() method failed: ${e.message}")
                    isRunning = false
                    break
                }

                socket?.let {
                    Log.d("BluetoothAcceptThread", "Accepted Bluetooth connection from ${it.remoteDevice.address}")
                    handleAcceptedBluetoothSocket(it)
                }
            }
            Log.d("BluetoothAcceptThread", "Bluetooth accept thread stopped.")
        }

        fun cancel() {
            isRunning = false
            try {
                serverSocket?.close()
            } catch (e: IOException) {
                Log.e("BluetoothAcceptThread", "Could not close the server Bluetooth socket: ${e.message}")
            }
        }
    }

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    inner class BluetoothClientThread(private val device: BluetoothDevice) : ConnectionThread(device.address, "bluetooth") {
        private var clientSocket: BluetoothSocket? = null

        override fun run() {
            bluetoothAdapter?.cancelDiscovery() // Cancel discovery to speed up connection

            try {
                // Try creating an insecure RFCOMM socket first for broader compatibility
                clientSocket = device.createInsecureRfcommSocketToServiceRecord(BLUETOOTH_UUID)
                clientSocket?.connect()
                Log.d("BluetoothClientThread", "Connected to Bluetooth device: ${device.address}")
                inputStream = clientSocket?.inputStream
                outputStream = clientSocket?.outputStream
                super.run() // Start reading from the socket
            } catch (e: IOException) {
                Log.e("BluetoothClientThread", "Could not connect to Bluetooth device ${device.address}: ${e.message}")
                cancel()
            } finally {
                // Ensure socket is closed on failure if not managed by ConnectionThread's cancel()
            }
        }

        override fun closeSocket() {
            try {
                clientSocket?.close()
            } catch (e: IOException) {
                Log.e("BluetoothClientThread", "Could not close the client Bluetooth socket: ${e.message}")
            }
        }
    }

    @SuppressLint("MissingPermission") // Permissions handled by Flutter in Dart
    private fun handleAcceptedBluetoothSocket(socket: BluetoothSocket) {
        val peerId = socket.remoteDevice.address
        if (!activeConnections.containsKey(peerId)) {
            Log.d("MeshService", "Handling incoming Bluetooth connection from $peerId")
            val connection = object : ConnectionThread(peerId, "bluetooth") {
                override fun closeSocket() {
                    try {
                        socket.close()
                    } catch (e: IOException) {
                        Log.e("MeshService", "Error closing accepted Bluetooth socket for $peerId: ${e.message}")
                    }
                }
            }
            connection.inputStream = socket.inputStream
            connection.outputStream = socket.outputStream
            executorService.submit(connection)
        } else {
            Log.d("MeshService", "Connection already exists for Bluetooth peer $peerId. Closing new socket.")
            try {
                socket.close()
            } catch (e: IOException) {
                Log.e("MeshService", "Error closing duplicate Bluetooth socket for $peerId: ${e.message}")
            }
        }
    }

    // --- Wi-Fi Direct Connection Threads ---

    inner class WifiP2pGroupOwnerThread : Runnable {
        private var serverSocket: ServerSocket? = null
        private var isRunning = true

        override fun run() {
            try {
                serverSocket = ServerSocket(WIFI_P2P_SERVICE_PORT)
                Log.d("WifiP2pGroupOwnerThread", "Wi-Fi Direct Group Owner: Listening for connections on port $WIFI_P2P_SERVICE_PORT")
                while (isRunning) {
                    val socket = serverSocket?.accept()
                    socket?.let {
                        Log.d("WifiP2pGroupOwnerThread", "Accepted Wi-Fi Direct client connection from ${it.inetAddress.hostAddress}")
                        handleAcceptedWifiP2pSocket(it)
                    }
                }
            } catch (e: IOException) {
                Log.e("WifiP2pGroupOwnerThread", "Error in Group Owner ServerSocket: ${e.message}")
            } finally {
                cancel()
            }
        }

        fun cancel() {
            isRunning = false
            try {
                serverSocket?.close()
            } catch (e: IOException) {
                Log.e("WifiP2pGroupOwnerThread", "Error closing Group Owner ServerSocket: ${e.message}")
            }
            Log.d("WifiP2pGroupOwnerThread", "Wi-Fi Direct Group Owner thread stopped.")
        }
    }

    inner class WifiP2pClientThread(peerId: String, private val groupOwnerAddress: InetAddress) : ConnectionThread(peerId, "wifi_direct") {
        private var socket: Socket? = null

        override fun run() {
            try {
                socket = Socket()
                socket?.bind(null) // Let the system choose an ephemeral port
                socket?.connect(InetSocketAddress(groupOwnerAddress, WIFI_P2P_SERVICE_PORT), 5000) // 5s timeout
                Log.d("WifiP2pClientThread", "Connected to Wi-Fi Direct Group Owner: ${groupOwnerAddress.hostAddress}")
                inputStream = socket?.inputStream
                outputStream = socket?.outputStream
                super.run() // Start reading from socket
            } catch (e: IOException) {
                Log.e("WifiP2pClientThread", "Error connecting to Wi-Fi Direct Group Owner ${groupOwnerAddress.hostAddress}: ${e.message}")
                cancel()
            }
        }

        override fun closeSocket() {
            try {
                socket?.close()
            } catch (e: IOException) {
                Log.e("WifiP2pClientThread", "Error closing Wi-Fi Direct client socket: ${e.message}")
            }
        }
    }

    private fun handleAcceptedWifiP2pSocket(socket: Socket) {
        val peerId = socket.inetAddress.hostAddress // Use IP as peerId for Wi-Fi Direct for simplicity
        if (!activeConnections.containsKey(peerId)) {
            Log.d("MeshService", "Handling incoming Wi-Fi Direct connection from $peerId")
            val connection = object : ConnectionThread(peerId, "wifi_direct") {
                override fun closeSocket() {
                    try {
                        socket.close()
                    } catch (e: IOException) {
                        Log.e("MeshService", "Error closing accepted Wi-Fi Direct socket for $peerId: ${e.message}")
                    }
                }
            }
            connection.inputStream = socket.inputStream
            connection.outputStream = socket.outputStream
            executorService.submit(connection)
        } else {
            Log.d("MeshService", "Connection already exists for Wi-Fi Direct peer $peerId. Closing new socket.")
            try {
                socket.close()
            } catch (e: IOException) {
                Log.e("MeshService", "Error closing duplicate Wi-Fi Direct socket for $peerId: ${e.message}")
            }
        }
    }

    // Helper data classes
    data class DiscoveredPeer(
        val deviceId: String,
        val deviceName: String,
        val transportType: String, // "bluetooth" or "wifi_direct"
        val isConnected: Boolean,
        val signalStrength: Int,
        val lastSeen: Long
    ) {
        fun toJson(): JSONObject {
            return JSONObject(mapOf(
                "deviceId" to deviceId,
                "deviceName" to deviceName,
                "transportType" to transportType,
                "isConnected" to isConnected,
                "signalStrength" to signalStrength,
                "lastSeen" to lastSeen
            ))
        }
    }

    data class MeshStatus(
        val isEnabled: Boolean,
        val isDiscovering: Boolean,
        val connectedPeersCount: Int,
        val activeTransport: String, // "bluetooth", "wifi_direct", or "none"
        val backgroundModeEnabled: Boolean,
        val batteryLevel: Int,
        val lowPowerMode: Boolean
    ) {
        fun toJson(): JSONObject {
            return JSONObject(mapOf(
                "isEnabled" to isEnabled,
                "isDiscovering" to isDiscovering,
                "connectedPeersCount" to connectedPeersCount,
                "activeTransport" to activeTransport,
                "backgroundModeEnabled" to backgroundModeEnabled,
                "batteryLevel" to batteryLevel,
                "lowPowerMode" to lowPowerMode
            ))
        }
    }
}