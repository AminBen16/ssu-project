import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/report_card_service.dart';
import 'package:test/screens/report_card_screen.dart';

class StudentReportListScreen extends StatelessWidget {
  final String studentId;

  const StudentReportListScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final schoolId =
        Provider.of<UserDataProvider>(context).school?.id.toString();
    final reportCardService = ReportCardService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Reports'),
      ),
      body: schoolId == null
          ? const Center(
              child: Text('Error: School ID not found.'),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: reportCardService.getAvailableReportTerms(
                schoolId: schoolId,
                studentId: studentId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No report terms found for this student.'),
                  );
                } else {
                  final reportTerms = snapshot.data!;
                  return ListView.builder(
                    itemCount: reportTerms.length,
                    itemBuilder: (context, index) {
                      final term = reportTerms[index]['term'] as String;
                      final yearValue = reportTerms[index]['year'];
                      final int year = yearValue is int
                          ? yearValue
                          : int.tryParse(yearValue.toString()) ??
                              DateTime.now().year;

                      return ListTile(
                        title: Text('$term - $year'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportCardScreen(
                                studentId: studentId,
                                term: term,
                                year: year.toString(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}
