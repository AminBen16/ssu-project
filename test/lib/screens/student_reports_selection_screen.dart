import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../providers/user_data_provider.dart';
import '../services/student_service.dart';
import 'report_card_screen.dart';

/// Screen for selecting student and parameters for generating reports.
/// PHASE 3: SAFE COMPLETION - Implementing dynamic parameters for Student Reports.
/// Replaces placeholder navigation with proper student selection flow.
class StudentReportsSelectionScreen extends StatefulWidget {
  const StudentReportsSelectionScreen({super.key});

  @override
  State<StudentReportsSelectionScreen> createState() =>
      _StudentReportsSelectionScreenState();
}

class _StudentReportsSelectionScreenState
    extends State<StudentReportsSelectionScreen> {
  Student? _selectedStudent;
  String _selectedTerm = 'Term 1';
  String _selectedYear = DateTime.now().year.toString();
  bool _isLoading = false;

  final List<String> _terms = ['Term 1', 'Term 2', 'Term 3'];
  final List<String> _years = [
    (DateTime.now().year - 1).toString(),
    DateTime.now().year.toString(),
    (DateTime.now().year + 1).toString(),
  ];

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    final schoolId = userData.userProfile?.schoolId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Student for Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Student',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Student>>(
              future: _fetchStudents(schoolId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No students found.');
                } else {
                  return DropdownButton<Student>(
                    value: _selectedStudent,
                    hint: const Text('Select a student'),
                    isExpanded: true,
                    items: snapshot.data!.map((student) {
                      return DropdownMenuItem<Student>(
                        value: student,
                        child: Text('${student.firstName} ${student.lastName}'),
                      );
                    }).toList(),
                    onChanged: (student) {
                      setState(() {
                        _selectedStudent = student;
                      });
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Term',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedTerm,
              isExpanded: true,
              items: _terms.map((term) {
                return DropdownMenuItem<String>(
                  value: term,
                  child: Text(term),
                );
              }).toList(),
              onChanged: (term) {
                setState(() {
                  _selectedTerm = term!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Year',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedYear,
              isExpanded: true,
              items: _years.map((year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (year) {
                setState(() {
                  _selectedYear = year!;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _selectedStudent != null && !_isLoading
                  ? _generateReport
                  : null,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Student>> _fetchStudents(String? schoolId) async {
    if (schoolId == null) return [];
    final studentService = StudentService();
    return await studentService.getStudentsBySchool(schoolId);
  }

  void _generateReport() async {
    if (_selectedStudent == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to ReportCardScreen with selected parameters
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportCardScreen(
              studentId: _selectedStudent!.id,
              term: _selectedTerm,
              year: _selectedYear,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
