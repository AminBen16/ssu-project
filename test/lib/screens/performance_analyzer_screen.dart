import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/constants.dart';
import 'package:test/models/student_model.dart';
import 'package:test/widgets/loading_button.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/performance_analysis_service.dart';

class PerformanceAnalyzerScreen extends StatefulWidget {
  const PerformanceAnalyzerScreen({super.key});

  @override
  State<PerformanceAnalyzerScreen> createState() =>
      _PerformanceAnalyzerScreenState();
}

class _PerformanceAnalyzerScreenState extends State<PerformanceAnalyzerScreen> {
  String? _selectedClass;
  String? _selectedTerm;
  int? _selectedYear;
  bool _isLoading = false;
  ClassPerformanceAnalysis? _analysisResult;

  final _analysisService = PerformanceAnalysisService();

  void _runAnalysis() async {
    if (_selectedClass == null ||
        _selectedTerm == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class, term, and year.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();
    final result = await _analysisService.analyzeClassPerformance(
      schoolId: schoolId,
      className: _selectedClass!,
      term: _selectedTerm!,
      year: _selectedYear!,
    );

    setState(() {
      _analysisResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final school = Provider.of<UserDataProvider>(context).school;
    final classNames = school?.allClassNamesWithStreams ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Analyzer')),
      body: Column(
        children: [
          _buildSelectionControls(classNames),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _analysisResult == null
                    ? const Center(
                        child: Text('Select parameters and run analysis.'),
                      )
                    : _buildResultsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionControls(List<String> classNames) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  hint: const Text('Select Class'),
                  onChanged: (value) => setState(() => _selectedClass = value),
                  items: classNames
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
              ),
              const SizedBox(width: 12),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          LoadingButton(
            isLoading: _isLoading,
            onPressed: _runAnalysis,
            icon: Icons.analytics,
            text: 'Run Analysis',
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_analysisResult!.studentCount == 0) {
      return const Center(child: Text('No students found in this class.'));
    }

    // Sort subjects by average score
    final sortedSubjects = _analysisResult!.averageSubjectScores.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildSubjectAveragesCard(sortedSubjects),
          const SizedBox(height: 20),
          _buildStudentListsCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat('Students', _analysisResult!.studentCount.toString()),
            _buildStat(
              'Top Performers',
              _analysisResult!.topPerformers.length.toString(),
            ),
            _buildStat(
              'Needs Support',
              _analysisResult!.underperformers.length.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSubjectAveragesCard(
    List<MapEntry<String, double>> sortedSubjects,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Subject Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...sortedSubjects.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      entry.value.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStudentList(
              'Top Performers',
              _analysisResult!.topPerformers,
              Colors.green,
            ),
            const Divider(height: 30),
            _buildStudentList(
              'Students Needing Support',
              _analysisResult!.underperformers,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(
    String title,
    List<Student> students,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (students.isEmpty)
          const Text('None')
        else
          ...students.map(
            (student) => ListTile(
              leading: Icon(Icons.person, color: iconColor),
              title: Text(student.fullName),
              dense: true,
            ),
          ),
      ],
    );
  }
}
