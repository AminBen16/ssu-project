import 'dart:developer' as developer;

import 'package:flutter/material.dart';

/// A reusable widget that simplifies handling the common states of a FutureBuilder.
/// It manages loading, error, and empty data states, allowing you to focus on
/// the success state.
class FutureHandler<T> extends StatelessWidget {
  /// The future that this widget will listen to.
  final Future<T>? future;

  /// The builder function to be called when the future completes with data.
  /// The `data` parameter is guaranteed to be non-null.
  final Widget Function(BuildContext context, T data) builder;

  /// An optional widget to display while the future is loading.
  /// Defaults to a centered `CircularProgressIndicator`.
  final Widget? loadingWidget;

  /// An optional widget to display when the future completes with an error.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// An optional widget to display when the future completes with null data
  /// or an empty list.
  final Widget? emptyWidget;

  /// The message to display when the data is empty.
  /// This is used if `emptyWidget` is not provided.
  final String emptyMessage;

  const FutureHandler({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.emptyMessage = 'No data found.',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          developer.log('FutureHandler Error: ${snapshot.error}');
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('An error occurred: ${snapshot.error}'));
        }

        final data = snapshot.data;
        if (data == null || (data is List && data.isEmpty)) {
          return emptyWidget ?? Center(child: Text(emptyMessage));
        }

        return builder(context, data);
      },
    );
  }
}

