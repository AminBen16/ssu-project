import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'English';
  bool _useSystemTheme = true;
  bool _highContrast = false;
  double _fontSize = 1.0;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get useSystemTheme => _useSystemTheme;
  bool get highContrast => _highContrast;
  double get fontSize => _fontSize;

  void updateSettings({
    ThemeMode? themeMode,
    String? language,
    bool? useSystemTheme,
    bool? highContrast,
    double? fontSize,
  }) {
    if (themeMode != null) _themeMode = themeMode;
    if (language != null) _language = language;
    if (useSystemTheme != null) _useSystemTheme = useSystemTheme;
    if (highContrast != null) _highContrast = highContrast;
    if (fontSize != null) _fontSize = fontSize;
    notifyListeners();
  }
}
