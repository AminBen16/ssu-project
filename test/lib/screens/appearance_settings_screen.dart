import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/radio_group.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  late ThemeMode _selectedTheme;
  late String _selectedLanguage;
  late bool _useSystemTheme;
  late bool _highContrast;
  late double _fontSize;

  final List<String> _languages = ['English', 'Swahili', 'French', 'Arabic'];
  final List<String> _fontSizes = ['0.8', '1.0', '1.2', '1.4', '1.6', '2.0'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedTheme = themeProvider.themeMode;
      _selectedLanguage = themeProvider.language;
      _useSystemTheme = themeProvider.useSystemTheme;
      _highContrast = themeProvider.highContrast;
      _fontSize = themeProvider.fontSize;
    });
  }

  Future<void> _saveSettings() async {
    // Save settings to ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.updateSettings(
      themeMode: _selectedTheme,
      language: _selectedLanguage,
      useSystemTheme: _useSystemTheme,
      highContrast: _highContrast,
      fontSize: _fontSize,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Theme'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use System Theme'),
                  subtitle:
                      const Text('Automatically match system light/dark mode'),
                  value: _useSystemTheme,
                  onChanged: (value) {
                    setState(() {
                      _useSystemTheme = value;
                      if (value) {
                        _selectedTheme = ThemeMode.system;
                      }
                    });
                    _saveSettings();
                  },
                ),
                if (!_useSystemTheme) ...[
                  const Divider(),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Theme'),
                    value: ThemeMode.light,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTheme = value);
                        _saveSettings();
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark Theme'),
                    value: ThemeMode.dark,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTheme = value);
                        _saveSettings();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Language'),
          Card(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(),
                  ),
                  items: _languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value!);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          _buildSectionHeader('Accessibility'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('High Contrast'),
                  subtitle:
                      const Text('Increase contrast for better visibility'),
                  value: _highContrast,
                  onChanged: (value) {
                    setState(() => _highContrast = value);
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 16),
                Text('Font Size: ${_fontSize.toStringAsFixed(1)}'),
                Slider(
                  value: _fontSize,
                  min: 0.8,
                  max: 2.0,
                  divisions: 7,
                  onChanged: (value) {
                    setState(() => _fontSize = value);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back'),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Preview'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Text',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is how your text will appear with the current settings. You can adjust the theme, font size, and other display options above.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sample Button'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
