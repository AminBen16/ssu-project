import 'dart:async';
import 'package:http/http.dart' as http;

/// A callback to report upload progress, providing the number of bytes
/// uploaded and the total number of bytes to be uploaded.
typedef OnUploadProgress = void Function(int bytes, int totalBytes);

/// An `http.MultipartRequest` that can report its upload progress.
class ProgressAwareMultipartRequest extends http.MultipartRequest {
  final OnUploadProgress onProgress;

  ProgressAwareMultipartRequest(
    super.method,
    super.url, {
    required this.onProgress,
  });

  /// Overrides the base `finalize()` method to wrap the byte stream
  /// in a stream that reports progress.
  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );
    return http.ByteStream(byteStream.transform(t));
  }
}
