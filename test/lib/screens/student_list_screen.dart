import 'package:flutter/material.dart';

import 'package:test/screens/student_detail_screen.dart';
import 'package:test/services/export_service.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/student_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late Future<List<Student>> _studentsFuture;
  final _studentService = StudentService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClass;
  String? _selectedStream;
  String? _selectedGender;
  String? _selectedFeesStatus;
  String? _selectedAdmissionYear;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudents();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<List<Student>> _fetchStudents() async {
    try {
      return await _studentService.getStudents();
    } catch (e) {
      throw Exception('Failed to load students: $e');
    }
  }

  Future<List<Student>> _fetchFilteredStudents() async {
    try {
      final students = await _studentService.getStudents();
      return students.where((student) {
        bool matches = true;
        if (_searchQuery.isNotEmpty) {
          matches = matches &&
              '${student.firstName} ${student.lastName}'
                  .toLowerCase()
                  .contains(_searchQuery);
        }
        if (_selectedClass != null) {
          matches = matches && student.className == _selectedClass;
        }
        if (_selectedGender != null) {
          matches = matches && student.sex == _selectedGender;
        }
        return matches;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load filtered students: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportStudents,
            tooltip: 'Export Students',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printStudents,
            tooltip: 'Print List',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                final students = snapshot.data!;
                final filteredStudents = students.where((student) {
                  final searchMatches = _searchQuery.isEmpty ||
                      '${student.firstName} ${student.lastName}'
                          .toLowerCase()
                          .contains(_searchQuery);
                  return searchMatches;
                }).toList();

                if (filteredStudents.isEmpty && students.isNotEmpty) {
                  return const Center(
                      child: Text('No students match your search.'));
                }

                return ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                            child: Text(student.firstName.isNotEmpty
                                ? student.firstName[0]
                                : '?')),
                        title: Text('${student.firstName} ${student.lastName}'),
                        subtitle: Text('Class: ${student.className}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailScreen(student: student),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DropdownButton<String>(
                  hint: const Text('Class'),
                  value: _selectedClass,
                  items: [
                    'Senior 1',
                    'Senior 2',
                    'Senior 3',
                    'Senior 4',
                    'Senior 5',
                    'Senior 6'
                  ]
                      .map((className) => DropdownMenuItem(
                          value: className, child: Text(className)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                      _studentsFuture = _fetchFilteredStudents();
                    });
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Stream'),
                  value: _selectedStream,
                  items: ['A', 'B', 'C', 'D']
                      .map((stream) => DropdownMenuItem(
                          value: stream, child: Text('Stream $stream')))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStream = value;
                      _studentsFuture = _fetchFilteredStudents();
                    });
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Gender'),
                  value: _selectedGender,
                  items: ['Male', 'Female']
                      .map((gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                      _studentsFuture = _fetchFilteredStudents();
                    });
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Fees Status'),
                  value: _selectedFeesStatus,
                  items: ['Paid', 'Partial', 'Outstanding']
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFeesStatus = value;
                      _studentsFuture = _fetchFilteredStudents();
                    });
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Admission Year'),
                  value: _selectedAdmissionYear,
                  items:
                      List.generate(10, (index) => DateTime.now().year - index)
                          .map((year) => DropdownMenuItem(
                              value: year.toString(),
                              child: Text(year.toString())))
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAdmissionYear = value;
                      _studentsFuture = _fetchFilteredStudents();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedClass = null;
                      _selectedStream = null;
                      _selectedGender = null;
                      _selectedFeesStatus = null;
                      _selectedAdmissionYear = null;
                      _studentsFuture = _fetchStudents();
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportStudents() async {
    try {
      final students = await _studentsFuture;
      final csvData = await ExportService.exportStudentsToExcel(students);

      // Save file
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Students CSV',
        fileName: 'students_${DateTime.now().millisecondsSinceEpoch}.csv',
        bytes: Uint8List.fromList(csvData.codeUnits),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Students exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _printStudents() async {
    try {
      final students = await _studentsFuture;
      final pdfData = await ExportService.exportStudentsToPDF(students);

      // Save PDF
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Students PDF',
        fileName: 'students_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print-ready file generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print generation failed: $e')),
        );
      }
    }
  }
}
