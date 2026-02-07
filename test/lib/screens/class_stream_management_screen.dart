import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/constants.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/school_service.dart';

class ClassStreamManagementScreen extends StatefulWidget {
  const ClassStreamManagementScreen({super.key});

  @override
  State<ClassStreamManagementScreen> createState() =>
      _ClassStreamManagementScreenState();
}

class _ClassStreamManagementScreenState
    extends State<ClassStreamManagementScreen> {
  final _schoolService = SchoolService();
  late Map<String, List<String>> _classStreams;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final school = Provider.of<UserDataProvider>(context, listen: false).school;
    // Create a deep copy to allow for local modifications before saving.
    _classStreams = (school?.streams ?? {}).map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
  }

  Future<void> _addStream(String className) async {
    final streamNameController = TextEditingController();
    final newStreamName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stream to $className'),
        content: TextField(
          controller: streamNameController,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'e.g., A, B, North, West'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(streamNameController.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newStreamName != null && newStreamName.isNotEmpty) {
      setState(() {
        _classStreams.putIfAbsent(className, () => []);
        if (!_classStreams[className]!.contains(newStreamName)) {
          _classStreams[className]!.add(newStreamName);
        }
      });
    }
  }

  void _removeStream(String className, String streamName) {
    setState(() {
      _classStreams[className]?.remove(streamName);
      if (_classStreams[className]?.isEmpty ?? false) {
        _classStreams.remove(className);
      }
    });
  }

  Future<void> _saveStreams() async {
    setState(() => _isLoading = true);
    final userDataProvider =
        Provider.of<UserDataProvider>(context, listen: false);
    final school = userDataProvider.school;

    if (school == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School data not available')),
        );
      }
      return;
    }

    try {
      await _schoolService.updateClassStreams(school.id.toString(), _classStreams);
      // Refresh the school data to update the available classes
      await userDataProvider.refreshSchoolData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class streams updated successfully!')),
        );
        Navigator.of(context)
            .pop(true); // Pop with a 'true' result to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save streams: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Class Streams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveStreams,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: AppConstants.classLevels.length,
              itemBuilder: (context, index) {
                final className = AppConstants.classLevels[index];
                final streams = _classStreams[className] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              className,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _addStream(className),
                              tooltip: 'Add Stream',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (streams.isEmpty)
                          const Text(
                            'No streams defined. This class will appear as a single unit.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: streams.map((stream) {
                              return Chip(
                                label: Text(stream),
                                onDeleted: () =>
                                    _removeStream(className, stream),
                                deleteIcon: const Icon(Icons.cancel, size: 18),
                              );
                            }).toList(),
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
