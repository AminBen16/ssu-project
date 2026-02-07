import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/widgets/future_handler.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/report_card_screen.dart';
import 'package:test/services/report_card_service.dart';

class StudentReportListScreen extends StatefulWidget {
  final String? studentId;
  const StudentReportListScreen({super.key, this.studentId});

  @override
  State<StudentReportListScreen> createState() =>
      _StudentReportListScreenState();
}

class _StudentReportListScreenState extends State<StudentReportListScreen> {
  Future<List<Map<String, dynamic>>>? _reportsFuture;
  final ReportCardService _reportCardService = ReportCardService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize future here because it depends on an inherited widget (Provider).
    if (_reportsFuture == null) {
      final userProfile = Provider.of<UserDataProvider>(context).userProfile;
      if (userProfile != null && userProfile.schoolId != null) {
        // Use the provided studentId if available (for parents),
        // otherwise use the logged-in user's UID (for students).
        final targetStudentId = widget.studentId ?? userProfile.uid;

        _reportsFuture = _reportCardService.getAvailableReportTerms(
          schoolId: userProfile.schoolId!,
          studentId: targetStudentId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: FutureHandler<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        emptyMessage: 'No reports found.',
        builder: (context, reports) {
          // Sort reports, newest first
          reports.sort((a, b) {
            int yearComp = b['year'].compareTo(a['year']);
            if (yearComp != 0) return yearComp;
            return b['term'].compareTo(a['term']);
          });

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final term = report['term'];
              final year = report['year'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: Colors.blueGrey,
                  ),
                  title: Text('$term $year'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    final targetStudentId =
                        widget.studentId ?? userProfile!.uid;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ReportCardScreen(
                          studentId: targetStudentId,
                          term: term,
                          year: year,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
