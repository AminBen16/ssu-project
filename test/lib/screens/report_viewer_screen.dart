import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/constants.dart';
import 'package:test/models/student_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/report_card_screen.dart';
import 'package:test/screens/batch_report_card_pdf_preview_screen.dart';
import 'package:test/services/student_service.dart';

class ReportViewerScreen extends StatefulWidget {
  const ReportViewerScreen({super.key});

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  String? _selectedClass;
  Student? _selectedStudent;
  String? _selectedTerm;
  int? _selectedYear;

  List<Student> _studentsInClass = [];
  bool _isLoadingStudents = false;

  final _studentService = StudentService();

  Future<void> _onClassChanged(String? newClass) async {
    if (newClass == null) return;
    setState(() {
      _selectedClass = newClass;
      _selectedStudent = null;
      _studentsInClass = [];
      _isLoadingStudents = true;
    });

    final schoolId =
        Provider.of<UserDataProvider>(context, listen: false).school?.id.toString();
    if (schoolId == null) {
      setState(() => _isLoadingStudents = false);
      return;
    }
    final students = await _studentService.getStudentsByClass(
      schoolId: schoolId,
      className: newClass,
    );

    setState(() {
      _studentsInClass = students;
      _isLoadingStudents = false;
    });
  }

  void _viewReport() {
    if (_selectedStudent == null ||
        _selectedTerm == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields to view the report.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportCardScreen(
          studentId: _selectedStudent!.id,
          term: _selectedTerm!,
          year: _selectedYear!.toString(),
        ),
      ),
    );
  }

  void _exportClassReports() {
    if (_selectedClass == null ||
        _selectedTerm == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class, term, and year to export.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BatchReportCardPdfPreviewScreen(
          className: _selectedClass!,
          term: _selectedTerm!,
          year: _selectedYear!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = Provider.of<UserDataProvider>(context).school;
    final classNames = school?.allClassNamesWithStreams ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('View Report Card')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              hint: const Text('Select Class'),
              onChanged: _onClassChanged,
              items: classNames
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Student>(
              initialValue: _selectedStudent,
              hint: _isLoadingStudents
                  ? const Text('Loading students...')
                  : const Text('Select Student'),
              isExpanded: true,
              onChanged: (student) =>
                  setState(() => _selectedStudent = student),
              items: _studentsInClass
                  .map(
                    (s) => DropdownMenuItem(
                        value: s,
                        child:
                            Text(s.fullName, overflow: TextOverflow.ellipsis)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTerm,
                    hint: const Text('Select Term'),
                    onChanged: (term) => setState(() => _selectedTerm = term),
                    items: AppConstants.terms
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    hint: const Text('Select Year'),
                    onChanged: (year) => setState(() => _selectedYear = year),
                    items:
                        List.generate(5, (index) => DateTime.now().year - index)
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: (_selectedStudent != null &&
                      _selectedTerm != null &&
                      _selectedYear != null)
                  ? _viewReport
                  : null,
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Student Report'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: (_selectedClass != null &&
                      _selectedTerm != null &&
                      _selectedYear != null)
                  ? _exportClassReports
                  : null,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export All Reports for Class'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
