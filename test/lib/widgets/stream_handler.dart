import 'package:flutter/material.dart';

/// A reusable widget that simplifies handling the common states of a StreamBuilder.
/// It manages loading, error, and empty data states, allowing you to focus on
/// the success state.
class StreamHandler<T> extends StatelessWidget {
  /// The stream that this widget will listen to.
  final Stream<T>? stream;

  /// The builder function to be called when the stream emits data.
  /// The `data` parameter is guaranteed to be non-null.
  final Widget Function(BuildContext context, T data) builder;

  /// An optional widget to display while waiting for the first event.
  /// Defaults to a centered `CircularProgressIndicator`.
  final Widget? loadingWidget;

  /// An optional widget to display when the stream emits an error.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// An optional widget to display when the stream emits null data
  /// or an empty list/QuerySnapshot.
  final Widget? emptyWidget;

  /// The message to display when the data is empty.
  /// This is used if `emptyWidget` is not provided.
  final String emptyMessage;

  const StreamHandler({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.emptyMessage = 'No data found.',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('StreamHandler Error: ${snapshot.error}');
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('An error occurred: ${snapshot.error}'));
        }

        final data = snapshot.data;
        if (data == null ||
            (data is List && data.isEmpty) ||
            (data.runtimeType.toString() == 'QuerySnapshot' && (data as dynamic).docs.isEmpty)) {
          return emptyWidget ?? Center(child: Text(emptyMessage));
        }

        return builder(context, data);
      },
    );
  }
}
