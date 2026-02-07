import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test/models/school.dart';
import 'package:test/models/subjects.dart';
import 'package:test/models/grading_models.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/grading_service.dart';
import 'package:test/services/report_card_service.dart';
import 'package:test/models/user_profile.dart'; // This path should now resolve correctly
import 'package:test/screens/report_card_pdf_preview_screen.dart';
import 'package:test/services/comment_generator_service.dart';

class ReportCardScreen extends StatefulWidget {
  final String studentId;
  final String term;
  final String year;

  const ReportCardScreen({
    super.key,
    required this.studentId,
    required this.term,
    required this.year,
  });

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  Future<ReportCardDisplayData?>? _reportDataFuture;
  final _reportService = ReportCardService();

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  void _loadReportData() {
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id.toString();

    setState(() {
      _reportDataFuture = _reportService.getReportCardDisplayData(
        schoolId: schoolId,
        studentId: widget.studentId,
        term: widget.term,
        year: int.tryParse(widget.year) ?? DateTime.now().year,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportCardDisplayData?>(
      future: _reportDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student Report Card')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student Report Card')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student Report Card')),
            body: const Center(
                child: Text('No report data found for the selected period.')),
          );
        }

        final displayData = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Report Card'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export as PDF',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportCardPdfPreviewScreen(
                        displayData: displayData,
                        term: widget.term,
                        year: int.tryParse(widget.year) ?? DateTime.now().year,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildReportBody(context, displayData),
          ),
        );
      },
    );
  }

  Widget _buildReportBody(
      BuildContext context, ReportCardDisplayData displayData) {
    // Determine level based on class name to show the correct report format.
    // This correctly handles classes with streams (e.g., "Senior 1 A").
    final baseClassName =
        displayData.reportData.student.className.split(' ').take(2).join(' ');
    final isOLevel = [
      'Senior 1',
      'Senior 2',
      'Senior 3',
      'Senior 4',
    ].contains(baseClassName);

    return isOLevel
        ? _buildOLevelReport(context, displayData)
        : _buildALevelReport(context, displayData);
  }

  Widget _buildOLevelReport(
    BuildContext context,
    ReportCardDisplayData displayData,
  ) {
    final gradingService = GradingService();
    final commentService = CommentGeneratorService();
    final school = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!;

    final reportData = displayData.reportData;
    // Collect all calculated grades to generate an overall comment
    final allCalculatedGrades = OLevelSubjects.all
        .map((subject) {
          final subjectScores = reportData.marks[subject.code];
          if (subjectScores == null) return null;
          return gradingService.calculateOLevelGrade(subjectScores);
        })
        .whereType<CalculatedSubjectGrade>()
        .toList();

    final classTeacherCommentFuture =
        commentService.generateClassTeacherComment(
      allCalculatedGrades,
    );

    final headTeacherCommentFuture = commentService.generateHeadTeacherComment(
      allCalculatedGrades,
    );

    final oLevelResult = gradingService.calculateOLevelFinalResult(
      allCalculatedGrades,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportHeader(context, school),
        const SizedBox(height: 20),
        // Student Details
        Text(
          'STUDENT DETAILS: ${reportData.student.fullName} | ${reportData.student.id.toString().substring(0, 6)} | ${reportData.student.className} | ${widget.term}, ${widget.year}',
        ),
        const SizedBox(height: 10),
        const Divider(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Table Header
              _buildOLevelHeaderRow(),
              const Divider(height: 1),
              // Table Body
              ...OLevelSubjects.all.map((subject) {
                final subjectScores = reportData.marks[subject.code];
                final calculatedGrade = subjectScores != null
                    ? gradingService.calculateOLevelGrade(subjectScores)
                    : null;
                return _buildOLevelSubjectEntry(
                  subject: subject,
                  rawScores: subjectScores,
                  calculatedGrade: calculatedGrade,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCommentsAndSignatures(
          context: context,
          classTeacher: displayData.classTeacher,
          headTeacher: displayData.headTeacher,
          classTeacherCommentFuture: classTeacherCommentFuture,
          headTeacherCommentFuture: headTeacherCommentFuture,
          oLevelResult: oLevelResult,
        ),
      ],
    );
  }

  Widget _buildOLevelHeaderRow() {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('SUBJECT', style: headerStyle)),
          Expanded(
            flex: 2,
            child: Text('BOT', style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('MOT', style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('EOT', style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('CA', style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('GS', style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'GRADE',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'DESCRIPTOR',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOLevelSubjectEntry({
    required Subject subject,
    Map<String, PaperScores>? rawScores,
    CalculatedSubjectGrade? calculatedGrade,
  }) {
    if (subject.papers.length <= 1) {
      // Render a single row for subjects with one paper.
      return _buildSinglePaperOLevelRow(
        subject: subject,
        rawScores: rawScores,
        calculatedGrade: calculatedGrade,
      );
    } else {
      // For multi-paper subjects, render a main row with the final grade,
      // followed by indented rows for each paper's scores.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text(subject.name,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                const Spacer(flex: 8), // Spacer for BOT, MOT, EOT, CA
                Expanded(
                    flex: 2,
                    child: Text(
                        calculatedGrade?.averagedGradingScore
                                ?.toStringAsFixed(1) ??
                            '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text(calculatedGrade?.grade ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text(calculatedGrade?.descriptor ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...subject.papers.map((paper) {
            final paperScores = rawScores?[paper.code];
            final paperCalculated = calculatedGrade?.paperGrades[paper.code];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(paper.code,
                            style:
                                const TextStyle(fontStyle: FontStyle.italic)),
                      )),
                  Expanded(
                      flex: 2,
                      child: Text(paperScores?.bot?.toStringAsFixed(1) ?? '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(paperScores?.mot?.toStringAsFixed(1) ?? '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(paperScores?.eot?.toStringAsFixed(0) ?? '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(
                          paperCalculated?.continuousAssessment
                                  .toStringAsFixed(1) ??
                              '-',
                          textAlign: TextAlign.center)),
                  const Spacer(flex: 7), // Spacer for GS, GRADE, DESCRIPTOR
                ],
              ),
            );
          }),
          const Divider(height: 1),
        ],
      );
    }
  }

  Widget _buildSinglePaperOLevelRow({
    required Subject subject,
    Map<String, PaperScores>? rawScores,
    CalculatedSubjectGrade? calculatedGrade,
  }) {
    final firstPaperCode =
        subject.papers.isNotEmpty ? subject.papers.first.code : null;
    final firstPaperScores = (firstPaperCode != null && rawScores != null)
        ? rawScores[firstPaperCode]
        : null;
    final firstPaperCalculated =
        (firstPaperCode != null && calculatedGrade != null)
            ? calculatedGrade.paperGrades[firstPaperCode]
            : null;
    final gradingScore = calculatedGrade?.averagedGradingScore;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(firstPaperCode != null
                  ? '${subject.name} ($firstPaperCode)'
                  : subject.name)),
          Expanded(
            flex: 2,
            child: Text(
              firstPaperScores?.bot?.toStringAsFixed(1) ?? '-',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              firstPaperScores?.mot?.toStringAsFixed(1) ?? '-',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              firstPaperScores?.eot?.toStringAsFixed(0) ?? '-',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              firstPaperCalculated?.continuousAssessment.toStringAsFixed(1) ??
                  '-',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              gradingScore?.toStringAsFixed(1) ?? '-',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              calculatedGrade?.grade ?? '-',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              calculatedGrade?.descriptor ?? '-',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // A-Level report UI
  Widget _buildALevelReport(
    BuildContext context,
    ReportCardDisplayData displayData,
  ) {
    final gradingService = GradingService();
    final commentService = CommentGeneratorService();
    final school = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!;
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
    final classTeacherCommentFuture =
        commentService.generateClassTeacherComment(
      allCalculatedGrades,
    );

    final headTeacherCommentFuture = commentService.generateHeadTeacherComment(
      allCalculatedGrades,
    );

    final subjectWidgets = subjectGradeData.map((data) {
      return _buildALevelSubjectEntry(
        subject: data['subject'],
        calculatedGrade: data['grade'],
        rawScores: data['rawScores'],
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportHeader(context, school),
        const SizedBox(height: 20),
        // Student Details
        Text(
          'STUDENT DETAILS: ${reportData.student.fullName} | ${reportData.student.id.toString().substring(0, 6)} | ${reportData.student.className} | ${widget.term}, ${widget.year}',
        ),
        const SizedBox(height: 10),
        const Divider(),
        // Table Body
        ...subjectWidgets,
        const Divider(),
        const SizedBox(height: 10),
        // Footer with Total Points
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'TOTAL POINTS: $totalPoints',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        _buildCommentsAndSignatures(
          context: context,
          classTeacher: displayData.classTeacher,
          headTeacher: displayData.headTeacher,
          classTeacherCommentFuture: classTeacherCommentFuture,
          headTeacherCommentFuture: headTeacherCommentFuture,
        ),
      ],
    );
  }

  Widget _buildALevelSubjectEntry({
    required Subject subject,
    required CalculatedSubjectGrade calculatedGrade,
    required Map<String, PaperScores> rawScores,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
                flex: 4,
                child: Text(subject.name,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
                flex: 2,
                child: Text(calculatedGrade.grade,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
                flex: 2,
                child: Text(calculatedGrade.points?.toString() ?? '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
                flex: 3,
                child: Text(calculatedGrade.descriptor,
                    textAlign: TextAlign.center)),
          ],
        ),
        children: [
          // Header for the paper details
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('Paper',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('BOT',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('MOT',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('EOT',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('CA',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('GS',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('SS',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Paper details
          ...subject.papers
              .where((p) => rawScores.containsKey(p.code))
              .map((paper) {
            final paperScores = rawScores[paper.code];
            final paperCalculated = calculatedGrade.paperGrades[paper.code];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 4,
                      child: Text(paper.code,
                          style: const TextStyle(fontStyle: FontStyle.italic))),
                  Expanded(
                      flex: 2,
                      child: Text(paperScores?.bot?.toStringAsFixed(1) ?? '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(paperScores?.mot?.toStringAsFixed(1) ?? '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(paperScores?.eot?.toStringAsFixed(0) ?? '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(
                          paperCalculated?.continuousAssessment
                                  .toStringAsFixed(1) ??
                              '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(
                          paperCalculated?.gradingScore.toStringAsFixed(1) ??
                              '-',
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(paperCalculated?.scaledScore ?? '-',
                          textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentsAndSignatures({
    required BuildContext context,
    required UserProfile? classTeacher,
    required UserProfile? headTeacher,
    required Future<String> classTeacherCommentFuture,
    required Future<String> headTeacherCommentFuture,
    int? oLevelResult,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommentSection(
              context: context,
              title: 'CLASS TEACHER\'S COMMENT',
              commentFuture: classTeacherCommentFuture,
              signer: classTeacher?.firstName ?? 'Class Teacher',
            ),
            const SizedBox(width: 16),
            _buildCommentSection(
              context: context,
              title: 'HEAD TEACHER\'S COMMENT',
              commentFuture: headTeacherCommentFuture,
              signer: headTeacher?.firstName ?? 'Head Teacher',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RESULT: ${oLevelResult ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('NEXT TERM BEGINS ON ........................'),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentSection({
    required BuildContext context,
    required String title,
    required Future<String> commentFuture,
    required String signer,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          FutureBuilder<String>(
            future: commentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Generating comment...',
                    style:
                        TextStyle(fontStyle: FontStyle.italic, fontSize: 12));
              }
              if (snapshot.hasError) {
                return const Text('Could not generate comment.',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.red));
              }
              final comment = snapshot.data ?? 'No comment available.';
              return Text(comment,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, fontSize: 12));
            },
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.black,
            margin: const EdgeInsets.only(bottom: 4),
          ),
          Text('$title | $signer', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildReportHeader(BuildContext context, School school) {
    return Center(
      child: Column(
        children: [
          if (school.logoUrl != null && school.logoUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: school.logoUrl!,
              height: 80,
              placeholder: (context, url) => const SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.school, size: 80),
            ),
          const SizedBox(height: 8),
          Text(
            school.name.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            '${school.address ?? "ADDRESS"} | ${school.contact ?? "CONTACT"}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
