import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:test/models/salary_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/salary_report_service.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

class SalaryPdfPreviewScreen extends StatelessWidget {
  final List<SalaryPayment> payments;
  final String staffName;
  final String year;

  const SalaryPdfPreviewScreen({
    super.key,
    required this.payments,
    required this.year,
    required this.staffName,
  });

  @override
  Widget build(BuildContext context) {
    final reportService = SalaryReportService();
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final schoolName = userData.school?.name ?? 'School Name';

    return Scaffold(
      appBar: AppBar(title: Text('Salary Report for $year')),
      body: kIsWeb
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDF preview is not available on this platform.\nClick below to generate and save the file.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save PDF'),
                    onPressed: () async {
                      final pdfBytes = await reportService.generateSalaryPdf(
                        schoolName: schoolName,
                        staffName: staffName,
                        year: year,
                        payments: payments,
                      );
                      await file_picker.FilePicker.platform.saveFile(
                        dialogTitle: 'Save Salary Report',
                        fileName:
                            'Salary_Report_${staffName.replaceAll(' ', '_')}_$year.pdf',
                        bytes: pdfBytes,
                      );
                    },
                  ),
                ],
              ),
            )
          : PdfPreview(
              build: (format) => reportService.generateSalaryPdf(
                schoolName: schoolName,
                staffName: staffName,
                year: year,
                payments: payments,
              ),
            ),
    );
  }
}
