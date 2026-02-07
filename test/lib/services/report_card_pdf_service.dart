import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:test/services/comment_generator_service.dart';
import 'package:test/models/grading_models.dart';
import 'package:test/models/grading_service.dart';
import 'package:test/models/school.dart';
import 'package:test/models/subjects.dart';
import 'package:test/services/report_card_service.dart';
import 'package:test/services/student_service.dart';
import 'package:test/models/user_profile.dart';

class ReportCardPdfService {
  Future<Uint8List> generateReportCardPdf({
    required ReportCardDisplayData displayData,
    required School school,
    required String term,
    required int year,
  }) async {
    final pdf = pw.Document();
    final gradingService = GradingService();
    final commentService = CommentGeneratorService();

    // Fetch logo image for watermark
    pw.ImageProvider? logoImage;
    if (school.logoUrl != null && school.logoUrl!.isNotEmpty) {
      try {
        logoImage = await networkImage(school.logoUrl!);
      } catch (e) {
        debugPrint('Could not fetch school logo for PDF: $e');
      }
    }

    // This correctly handles classes with streams (e.g., "Senior 1 A").
    final baseClassName =
        displayData.reportData.student.className.split(' ').take(2).join(' ');
    final isOLevel = [
      'Senior 1',
      'Senior 2',
      'Senior 3',
      'Senior 4',
    ].contains(baseClassName);

    final content = isOLevel
        ? await _buildOLevelPdfContent(displayData, school, term, year,
            gradingService, commentService, logoImage)
        : await _buildALvelPdfContent(displayData, school, term, year,
            gradingService, commentService, logoImage);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(logoImage),
        build: (pw.Context context) => content,
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateBatchReportCardPdf({
    required School school,
    required String className,
    required String term,
    required int year,
  }) async {
    final pdf = pw.Document();
    final studentService = StudentService();
    final reportCardService = ReportCardService();
    final gradingService = GradingService();
    final commentService = CommentGeneratorService();

    // Fetch logo image once
    pw.ImageProvider? logoImage;
    if (school.logoUrl != null && school.logoUrl!.isNotEmpty) {
      try {
        logoImage = await networkImage(school.logoUrl!);
      } catch (e) {
        debugPrint('Could not fetch school logo for PDF: $e');
      }
    }

    final students = await studentService.getStudentsByClass(
        schoolId: school.id.toString(), className: className);

    // Fetch all report card data in parallel for better performance.
    final displayDataFutures = students.map((student) {
      return reportCardService.getReportCardDisplayData(
        schoolId: school.id.toString(),
        studentId: student.id.toString(),
        term: term,
        year: year,
      );
    }).toList();

    final allDisplayData = await Future.wait(displayDataFutures);

    // Now iterate through the fetched data and build the PDF pages.
    for (final displayData
        in allDisplayData.whereType<ReportCardDisplayData>()) {
      final baseClassName =
          displayData.reportData.student.className.split(' ').take(2).join(' ');
      final isOLevel = ['Senior 1', 'Senior 2', 'Senior 3', 'Senior 4']
          .contains(baseClassName);

      final content = isOLevel
          ? await _buildOLevelPdfContent(displayData, school, term, year,
              gradingService, commentService, logoImage)
          : await _buildALvelPdfContent(displayData, school, term, year,
              gradingService, commentService, logoImage);

      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(logoImage),
          build: (pw.Context context) => content,
        ),
      );
    }

    return pdf.save();
  }

  pw.PageTheme _buildPageTheme(pw.ImageProvider? logoImage) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      buildForeground: (pw.Context context) {
        if (logoImage == null) {
          return pw.SizedBox.shrink();
        }
        return pw.Center(
          child: pw.Opacity(
            opacity: 0.1,
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
        );
      },
    );
  }

  List<pw.Widget> _buildPdfHeader(ReportCardDisplayData displayData,
      School school, String term, int year, pw.ImageProvider? logoImage) {
    return [
      pw.Center(
        child: pw.Column(
          children: [
            if (logoImage != null)
              pw.Container(height: 60, child: pw.Image(logoImage)),
            if (logoImage != null) pw.SizedBox(height: 10),
            pw.Text(
              school.name.toUpperCase(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
            ),
            pw.Text(
              '${school.address ?? "ADDRESS"} | ${school.contact ?? "CONTACT"}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'END OF $term, $year REPORT',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Text(
        'STUDENT DETAILS: ${displayData.reportData.student.fullName} | ${displayData.reportData.student.id.substring(0, 6)} | ${displayData.reportData.student.className}',
      ),
      pw.Divider(height: 10),
    ];
  }

  Iterable<List<dynamic>> _buildOLevelSubjectRows(
    Subject subject,
    Map<String, PaperScores>? subjectScores,
    CalculatedSubjectGrade? calculatedGrade,
  ) {
    if (subject.papers.length <= 1) {
      final firstPaperCode =
          subject.papers.isNotEmpty ? subject.papers.first.code : null;
      final firstPaperScores = (firstPaperCode != null && subjectScores != null)
          ? subjectScores[firstPaperCode]
          : null;
      final firstPaperCalculated =
          (firstPaperCode != null && calculatedGrade != null)
              ? calculatedGrade.paperGrades[firstPaperCode]
              : null;
      final gradingScore = calculatedGrade?.averagedGradingScore;
      return [
        [
          firstPaperCode != null
              ? '${subject.name} ($firstPaperCode)'
              : subject.name,
          firstPaperScores?.bot?.toStringAsFixed(1) ?? '-',
          firstPaperScores?.mot?.toStringAsFixed(1) ?? '-',
          firstPaperScores?.eot?.toStringAsFixed(0) ?? '-',
          firstPaperCalculated?.continuousAssessment.toStringAsFixed(1) ?? '-',
          gradingScore?.toStringAsFixed(1) ?? '-',
          gradingScore?.toStringAsFixed(1) ??
              '-', // For single paper, GS is AGS
          calculatedGrade?.grade ?? '-',
          calculatedGrade?.descriptor ?? '-',
        ]
      ];
    } else {
      // Create a main row for the subject's overall grade
      final mainRow = [
        pw.Text(subject.name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        '', '', '', '', '', // Empty cells for paper scores
        pw.Text(
            calculatedGrade?.averagedGradingScore?.toStringAsFixed(1) ?? '-',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(calculatedGrade?.grade ?? '-',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(calculatedGrade?.descriptor ?? '-',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ];
      // Create sub-rows for each paper
      final paperRows = subject.papers.map((paper) {
        final paperScores = subjectScores?[paper.code];
        final paperCalculated = calculatedGrade?.paperGrades[paper.code];
        return [
          pw.Text('  ${paper.code}',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
          paperScores?.bot?.toStringAsFixed(1) ?? '-',
          paperScores?.mot?.toStringAsFixed(1) ?? '-',
          paperScores?.eot?.toStringAsFixed(0) ?? '-',
          paperCalculated?.continuousAssessment.toStringAsFixed(1) ?? '-',
          paperCalculated?.gradingScore.toStringAsFixed(1) ?? '-',
          '',
          '',
          ''
        ];
      }).toList();
      return [mainRow, ...paperRows];
    }
  }

  Future<List<pw.Widget>> _buildOLevelPdfContent(
    ReportCardDisplayData displayData,
    School school,
    String term,
    int year,
    GradingService gradingService,
    CommentGeneratorService commentService,
    pw.ImageProvider? logoImage,
  ) async {
    final reportData = displayData.reportData;
    final allCalculatedGrades = OLevelSubjects.all
        .map((subject) {
          final subjectScores = reportData.marks[subject.code];
          if (subjectScores == null) return null;
          return gradingService.calculateOLevelGrade(subjectScores);
        })
        .whereType<CalculatedSubjectGrade>()
        .toList();
    final oLevelResult =
        gradingService.calculateOLevelFinalResult(allCalculatedGrades);
    final classTeacherComment =
        await commentService.generateClassTeacherComment(allCalculatedGrades);
    final headTeacherComment =
        await commentService.generateHeadTeacherComment(allCalculatedGrades);

    return [
      ..._buildPdfHeader(displayData, school, term, year, logoImage),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellPadding: const pw.EdgeInsets.all(4),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
          5: pw.Alignment.center,
          6: pw.Alignment.center,
          7: pw.Alignment.center,
          8: pw.Alignment.center,
        },
        headers: [
          'SUBJECT',
          'BOT',
          'MOT',
          'EOT',
          'CA',
          'GS',
          'AGS',
          'GRADE',
          'DESCRIPTOR'
        ],
        data: OLevelSubjects.all.expand((subject) {
          final subjectScores = reportData.marks[subject.code];
          final calculatedGrade = subjectScores != null
              ? gradingService.calculateOLevelGrade(subjectScores)
              : null;
          return _buildOLevelSubjectRows(
              subject, subjectScores, calculatedGrade);
        }).toList(),
      ),
      pw.SizedBox(height: 20),
      _buildPdfCommentsAndSignatures(
        classTeacher: displayData.classTeacher,
        headTeacher: displayData.headTeacher,
        classTeacherComment: classTeacherComment,
        headTeacherComment: headTeacherComment,
        oLevelResult: oLevelResult,
      ),
    ];
  }

  Iterable<List<dynamic>> _buildALevelSubjectRows(
    Subject subject,
    CalculatedSubjectGrade grade,
    Map<String, PaperScores> rawScores,
  ) {
    final mainRow = [
      pw.Text(subject.name,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      '', '', '', '', '', '', // Empty cells for paper scores
      pw.Text(grade.grade, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(grade.points?.toString() ?? '-',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(grade.descriptor,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ];

    final paperRows = subject.papers.map((paper) {
      final paperScores = rawScores[paper.code];
      final paperCalculated = grade.paperGrades[paper.code];
      return [
        pw.Text('  ${paper.code}',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
        paperScores?.bot?.toStringAsFixed(1) ?? '-',
        paperScores?.mot?.toStringAsFixed(1) ?? '-',
        paperScores?.eot?.toStringAsFixed(0) ?? '-',
        paperCalculated?.continuousAssessment.toStringAsFixed(1) ?? '-',
        paperCalculated?.gradingScore.toStringAsFixed(1) ?? '-',
        paperCalculated?.scaledScore ?? '-',
        '',
        '',
        '', // Empty cells for final grade
      ];
    }).toList();

    return [mainRow, ...paperRows];
  }

  Future<List<pw.Widget>> _buildALvelPdfContent(
    ReportCardDisplayData displayData,
    School school,
    String term,
    int year,
    GradingService gradingService,
    CommentGeneratorService commentService,
    pw.ImageProvider? logoImage,
  ) async {
    final reportData = displayData.reportData;
    final List<Map<String, dynamic>> subjectGradeData = [];
    int totalPoints = 0;

    for (var subject in ALevelSubjects.all) {
      final subjectScores = reportData.marks[subject.code];
      if (subjectScores != null) {
        final isSubsidiary = subject.code.startsWith('S');
        final calculatedGrade = gradingService.calculateALevelGrade(
          paperScores: subjectScores,
          isSubsidiary: isSubsidiary,
        );
        totalPoints += calculatedGrade.points ?? 0;
        subjectGradeData.add({
          'subject': subject,
          'grade': calculatedGrade,
          'rawScores': subjectScores,
        });
      }
    }

    final allCalculatedGrades = subjectGradeData
        .map((d) => d['grade'] as CalculatedSubjectGrade)
        .toList();
    final classTeacherComment =
        await commentService.generateClassTeacherComment(allCalculatedGrades);
    final headTeacherComment =
        await commentService.generateHeadTeacherComment(allCalculatedGrades);

    return [
      ..._buildPdfHeader(displayData, school, term, year, logoImage),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellPadding: const pw.EdgeInsets.all(4),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
          5: pw.Alignment.center,
          6: pw.Alignment.center,
          7: pw.Alignment.center,
          8: pw.Alignment.center,
          9: pw.Alignment.center,
        },
        headers: [
          'SUBJECT',
          'BOT',
          'MOT',
          'EOT',
          'CA',
          'GS',
          'SS',
          'GRADE',
          'POINTS',
          'DESCRIPTOR'
        ],
        data: subjectGradeData.expand((data) {
          final subject = data['subject'] as Subject;
          final grade = data['grade'] as CalculatedSubjectGrade;
          final rawScores = data['rawScores'] as Map<String, PaperScores>;
          return _buildALevelSubjectRows(subject, grade, rawScores);
        }).toList(),
      ),
      pw.SizedBox(height: 10),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'TOTAL POINTS: $totalPoints',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
      ),
      pw.SizedBox(height: 20),
      _buildPdfCommentsAndSignatures(
        classTeacher: displayData.classTeacher,
        headTeacher: displayData.headTeacher,
        classTeacherComment: classTeacherComment,
        headTeacherComment: headTeacherComment,
      ),
    ];
  }

  pw.Widget _buildPdfCommentsAndSignatures({
    required UserProfile? classTeacher,
    required UserProfile? headTeacher,
    required String classTeacherComment,
    required String headTeacherComment,
    int? oLevelResult,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CLASS TEACHER\'S COMMENT',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    classTeacherComment,
                    style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic, fontSize: 10),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                      height: 1,
                      color: PdfColors.black,
                      margin: const pw.EdgeInsets.only(bottom: 4)),
                  pw.Text('CLASS TEACHER | ${classTeacher?.firstName ?? ''}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('HEAD TEACHER\'S COMMENT',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    headTeacherComment,
                    style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic, fontSize: 10),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                      height: 1,
                      color: PdfColors.black,
                      margin: const pw.EdgeInsets.only(bottom: 4)),
                  pw.Text('HEAD TEACHER | ${headTeacher?.firstName ?? ''}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'RESULT: ${oLevelResult != null ? oLevelResult.toString() : 'N/A'}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('NEXT TERM BEGINS ON ........................'),
          ],
        ),
      ],
    );
  }
}
