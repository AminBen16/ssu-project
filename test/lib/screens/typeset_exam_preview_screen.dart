import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:test/models/exam_model.dart';
import 'package:test/services/exam_typesetting_service.dart';
import 'package:test/providers/user_data_provider.dart';

class TypesetExamPreviewScreen extends StatelessWidget {
  final Exam exam;

  const TypesetExamPreviewScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final typesettingService = ExamTypesettingService();
    // Get the school name from the provider to pass to the PDF generator.
    // Provide a fallback in case the school data isn't available.
    final schoolName =
        Provider.of<UserDataProvider>(context, listen: false).school?.name ??
        'SCHOOL NAME';

    return Scaffold(
      appBar: AppBar(title: Text('Preview: ${exam.title}')),
      body: PdfPreview(
        build: (format) => typesettingService.generateExamPdf(exam, schoolName),
      ),
    );
  }
}
