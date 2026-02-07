import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/report_card_pdf_service.dart';
import 'package:test/services/report_card_service.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

class ReportCardPdfPreviewScreen extends StatelessWidget {
  final ReportCardDisplayData displayData;
  final String term;
  final int year;

  const ReportCardPdfPreviewScreen({
    super.key,
    required this.displayData,
    required this.term,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final reportPdfService = ReportCardPdfService();
    final school = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Preview')),
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
                      final pdfBytes = await reportPdfService
                          .generateReportCardPdf(
                            displayData: displayData,
                            school: school,
                            term: term,
                            year: year,
                          );
                      await file_picker.FilePicker.platform.saveFile(
                        dialogTitle: 'Save Report Card',
                        fileName:
                            'Report_${displayData.reportData.student.fullName.replaceAll(' ', '_')}_${term}_$year.pdf',
                        bytes: pdfBytes,
                      );
                    },
                  ),
                ],
              ),
            )
          : PdfPreview(
              build: (format) => reportPdfService.generateReportCardPdf(
                displayData: displayData,
                school: school,
                term: term,
                year: year,
              ),
            ),
    );
  }
}
