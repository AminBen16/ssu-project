import 'package:flutter/material.dart';

/// Standardized TextFormField with consistent styling and behavior
class StandardizedTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? hintText;

  const StandardizedTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}

/// Standardized Password Field with visibility toggle
class StandardizedPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final String? hintText;

  const StandardizedPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.hintText,
  });

  @override
  State<StandardizedPasswordField> createState() =>
      _StandardizedPasswordFieldState();
}

class _StandardizedPasswordFieldState extends State<StandardizedPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      obscureText: _obscureText,
      validator: widget.validator,
    );
  }
}

/// Standardized Dropdown Field
class StandardizedDropdownField<T> extends StatelessWidget {
  final String labelText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  const StandardizedDropdownField({
    super.key,
    required this.labelText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Standardized Email Field
class StandardizedEmailField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  const StandardizedEmailField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return StandardizedTextFormField(
      controller: controller,
      labelText: labelText,
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? _defaultEmailValidator,
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}

/// Standardized Date Picker Field
class StandardizedDateField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(String?)? validator;

  const StandardizedDateField({
    super.key,
    required this.controller,
    required this.labelText,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.validator,
  });

  @override
  State<StandardizedDateField> createState() => _StandardizedDateFieldState();
}

class _StandardizedDateFieldState extends State<StandardizedDateField> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return StandardizedTextFormField(
      controller: widget.controller,
      labelText: widget.labelText,
      prefixIcon: Icons.calendar_today,
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: widget.validator,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        widget.controller.text =
            picked.toString().split(' ')[0]; // YYYY-MM-DD format
      });
    }
  }
}
