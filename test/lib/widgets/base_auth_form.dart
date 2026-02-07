import 'package:flutter/material.dart';

/// Base widget for authentication forms (login, registration, etc.)
/// Provides common layout and behavior patterns
class BaseAuthForm extends StatelessWidget {
  final String title;
  final List<Widget> formFields;
  final Widget actionButton;
  final List<Widget>? additionalWidgets;
  final VoidCallback? onBackPressed;
  final String? backButtonText;
  final String? subtitle;
  final bool showLogo;

  const BaseAuthForm({
    super.key,
    required this.title,
    required this.formFields,
    required this.actionButton,
    this.additionalWidgets,
    this.onBackPressed,
    this.backButtonText,
    this.subtitle,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: onBackPressed != null
          ? AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackPressed,
              ),
            )
          : AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SSU Logo/Branding (optional)
              if (showLogo) ...[
                Image.asset(
                  'assets/images/ssu_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 24),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ...formFields,
              const SizedBox(height: 32),
              actionButton,
              if (additionalWidgets != null) ...[
                const SizedBox(height: 20),
                ...?additionalWidgets,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable loading button widget for forms
class StandardizedLoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String text;
  final String? loadingText;

  const StandardizedLoadingButton({
    super.key,
    required this.isLoading,
    this.onPressed,
    required this.text,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(loadingText ?? 'Loading...'),
                ],
              )
            : Text(text),
      ),
    );
  }
}

/// Reusable form field widget with consistent styling
class AuthTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const AuthTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}

/// Utility class for common auth form operations
class AuthFormUtils {
  /// Shows an error message using SnackBar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Shows a success message using SnackBar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Common password visibility toggle widget
  static Widget buildPasswordVisibilityToggle({
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        obscureText ? Icons.visibility_off : Icons.visibility,
      ),
      onPressed: onToggle,
    );
  }
}
