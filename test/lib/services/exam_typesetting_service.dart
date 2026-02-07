import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/models/exam_model.dart';
import 'package:test/models/question_model.dart';
import 'package:printing/printing.dart';

class ExamTypesettingService {
  Future<Uint8List> generateExamPdf(Exam exam, String schoolName) async {
    final pdf = pw.Document();

    // Pre-fetch all network images to avoid doing it inside the build function
    final imageProviders = <String, pw.ImageProvider>{};
    for (final question in exam.questions) {
      if (question.imageUrl != null && question.imageUrl!.isNotEmpty) {
        try {
          imageProviders[question.imageUrl!] = await networkImage(
            question.imageUrl!,
          );
        } catch (e) {
          debugPrint('Could not fetch image: ${question.imageUrl}');
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(exam, schoolName),
            pw.SizedBox(height: 20),
            _buildInstructions(exam.instructions),
            pw.Divider(),
            pw.SizedBox(height: 10),
            ..._buildQuestions(exam.questions, imageProviders),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Exam exam, String schoolName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          schoolName.toUpperCase(),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          exam.title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
        pw.SizedBox(height: 5),
        pw.Text('${exam.subject} - ${exam.className}'),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Name: ....................................................',
            ),
            pw.Text('Date: ..........................'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInstructions(String? instructions) {
    final instructionText = instructions != null && instructions.isNotEmpty
        ? instructions
        : 'Instructions: Answer all questions in the spaces provided. Read each question carefully before answering.';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Text(
        instructionText,
        style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  List<pw.Widget> _buildQuestions(
    List<Question> questions,
    Map<String, pw.ImageProvider> imageProviders,
  ) {
    return List.generate(questions.length, (i) {
      final question = questions[i];
      final imageProvider = imageProviders[question.imageUrl];

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 15),
          pw.Text(
            '${i + 1}. ${question.text}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (imageProvider != null)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              alignment: pw.Alignment.center,
              child: pw.Image(imageProvider, height: 150),
            ),
          _buildAnswerSpace(question),
        ],
      );
    });
  }

  /// Builds the appropriate space or options for a given question type.
  pw.Widget _buildAnswerSpace(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        // For multiple choice, display the options.
        return pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, top: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: List.generate(question.options.length, (index) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(
                  // e.g., "A. Option 1"
                  '${String.fromCharCode(65 + index)}. ${question.options[index]}',
                ),
              );
            }),
          ),
        );
      case QuestionType.essay:
        // Provide more space for essay questions.
        return pw.SizedBox(height: 200);
      case QuestionType.shortAnswer:
        // Provide a default space for short answers.
        return pw.SizedBox(height: 80);
    }
  }
}
