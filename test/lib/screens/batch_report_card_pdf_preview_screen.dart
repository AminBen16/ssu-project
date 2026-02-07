import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/report_card_pdf_service.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

class BatchReportCardPdfPreviewScreen extends StatelessWidget {
  final String className;
  final String term;
  final int year;

  const BatchReportCardPdfPreviewScreen({
    super.key,
    required this.className,
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
      appBar: AppBar(title: Text('Batch Report for $className')),
      // The `printing` package's PdfPreview widget is not available on Windows.
      // Therefore, we provide a fallback UI with a "Save PDF" button.
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
                          .generateBatchReportCardPdf(
                            school: school,
                            className: className,
                            term: term,
                            year: year,
                          );
                      await file_picker.FilePicker.platform.saveFile(
                        dialogTitle: 'Save Batch Report',
                        fileName:
                            'Batch_Report_${className.replaceAll(' ', '_')}_${term}_$year.pdf',
                        bytes: pdfBytes,
                      );
                    },
                  ),
                ],
              ),
            )
          : PdfPreview(
              build: (format) => reportPdfService.generateBatchReportCardPdf(
                school: school,
                className: className,
                term: term,
                year: year,
              ),
            ),
    );
  }
}
