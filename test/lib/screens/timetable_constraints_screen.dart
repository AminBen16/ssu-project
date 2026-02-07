import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/timetable_constraints_service.dart';
import 'package:test/providers/user_data_provider.dart';

class TimetableConstraintsScreen extends StatefulWidget {
  const TimetableConstraintsScreen({super.key});

  @override
  State<TimetableConstraintsScreen> createState() =>
      _TimetableConstraintsScreenState();
}

class _TimetableConstraintsScreenState
    extends State<TimetableConstraintsScreen> {
  final _service = TimetableConstraintsService();
  Map<String, (int?, int?)> _constraints = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConstraints();
  }

  Future<void> _loadConstraints() async {
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();
    final constraints = await _service.getConstraints(schoolId);
    if (mounted) {
      setState(() {
        _constraints = constraints;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConstraints() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();

    try {
      await _service.saveConstraints(schoolId, _constraints);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Constraints saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save constraints: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSubjects = [...OLevelSubjects.all, ...ALevelSubjects.all];
    allSubjects.sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Constraints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Constraints',
            onPressed: _isLoading ? null : _saveConstraints,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: allSubjects.length,
              itemBuilder: (context, index) {
                final subject = allSubjects[index];
                final currentConstraint =
                    _constraints[subject.code] ?? (null, null);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: currentConstraint.$1?.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Min Periods/Week',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final min = int.tryParse(value);
                                  final currentMax =
                                      _constraints[subject.code]?.$2;
                                  _constraints[subject.code] = (
                                    min,
                                    currentMax,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: currentConstraint.$2?.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Max Periods/Week',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final max = int.tryParse(value);
                                  final currentMin =
                                      _constraints[subject.code]?.$1;
                                  _constraints[subject.code] = (
                                    currentMin,
                                    max,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
