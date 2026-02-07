import 'package:test/services/communication/core_models.dart';

export 'package:test/services/communication/core_models.dart';

/// File chunk for resumable transfers
class FileChunk {
  final String messageId;
  final int chunkIndex;
  final int totalChunks;
  final String data; // Base64 encoded chunk data
  final String checksum;
  final DateTime timestamp;

  FileChunk({
    required this.messageId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.data,
    required this.checksum,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'data': data,
      'checksum': checksum,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FileChunk.fromJson(Map<String, dynamic> json) {
    return FileChunk(
      messageId: json['messageId'],
      chunkIndex: json['chunkIndex'],
      totalChunks: json['totalChunks'],
      data: json['data'],
      checksum: json['checksum'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Delivery status tracking
class DeliveryStatusInfo {
  final String messageId;
  final DeliveryStatus status;
  final DateTime timestamp;
  final String? errorMessage;
  final int retryCount;

  DeliveryStatusInfo({
    required this.messageId,
    required this.status,
    required this.timestamp,
    this.errorMessage,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  factory DeliveryStatusInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusInfo(
      messageId: json['messageId'],
      status: DeliveryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}
