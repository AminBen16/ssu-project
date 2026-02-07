import 'package:flutter/material.dart';

/// A button that shows a loading indicator when in a loading state.
///
/// It can be configured to display either a text label or an icon.
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.text,
    this.icon,
  }) : assert(text != null || icon != null,
            'Either text or icon must be provided.');

  @override
  Widget build(BuildContext context) {
    // Use an ElevatedButton for a button with text, and an IconButton for an icon-only button.
    if (text != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const SizedBox.shrink(), // No icon when not loading
        label: Text(text!),
      );
    } else {
      return IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? const CircularProgressIndicator() : Icon(icon),
      );
    }
  }
}
