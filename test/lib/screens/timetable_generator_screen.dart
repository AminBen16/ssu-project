import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/timetable_service.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/services/timetable_generator_service.dart';

class TimetableGeneratorScreen extends StatefulWidget {
  final String className;
  const TimetableGeneratorScreen({super.key, required this.className});

  @override
  State<TimetableGeneratorScreen> createState() =>
      _TimetableGeneratorScreenState();
}

class _TimetableGeneratorScreenState extends State<TimetableGeneratorScreen> {
  final _generatorService = TimetableGeneratorService();
  final _timetableService = TimetableService();
  bool _isLoading = false;

  Future<void> _generateAndSaveTimetable() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();

    try {
      final generatedData = await _generatorService.generateClassTimetable(
        schoolId: schoolId,
        className: widget.className,
      );

      await _timetableService.saveFullTimetable(
        schoolId: schoolId,
        className: widget.className,
        timetable: generatedData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Timetable for ${widget.className} generated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate timetable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Timetable Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Generate Timetable',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'This will generate a new timetable for ${widget.className}. Any existing timetable for this class will be overwritten.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _generateAndSaveTimetable,
                icon: Icons.auto_awesome,
                text: 'Generate Now',
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text('AI is thinking... This may take a moment.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
