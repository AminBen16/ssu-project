import 'package:flutter/material.dart';

/// A widget that simplifies creating a group of radio buttons.
///
/// It wraps a `Column` and provides a common `groupValue` and `onChanged`
/// callback to a group of `RadioListTile` children.
class AppRadioGroup<T> extends StatelessWidget {
  /// The currently selected value for this group of radio buttons.
  final T? groupValue;

  /// Called when the user selects a radio button.
  final ValueChanged<T?> onChanged;

  /// The list of `RadioListTile` widgets to display in the group.
  final List<RadioListTile<T>> children;

  const AppRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}
