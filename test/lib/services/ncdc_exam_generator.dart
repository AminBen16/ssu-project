import 'dart:async';
import 'dart:math';
import '../models/curriculum_models.dart';
import 'ncdc_curriculum_parser.dart';

/// NCDC-Based Exam Generator using real curriculum content
class NCDCExamGenerator {
  final NCDCCurriculumParser _curriculumParser = NCDCCurriculumParser();
  final Random _random = Random();
  
  static final NCDCExamGenerator _instance = NCDCExamGenerator._internal();
  factory NCDCExamGenerator() => _instance;
  NCDCExamGenerator._internal();

  /// Generate exam based on NCDC curriculum
  Future<Exam> generateExam({
    required String subjectName,
    required String className,
    required String examType, // 'mid_term', 'end_term', 'mock', 'assessment'
    required int duration, // in minutes
    required int totalMarks,
    required List<String> topicsToCover,
    String? examTitle,
    DateTime? examDate,
  }) async {
    
    // Ensure curriculum data is parsed
    await _curriculumParser.parseAllSyllabusFiles();
    
    // Get curriculum data for specified topics
    final allTopics = _curriculumParser.getTopics(subjectName);
    final targetTopics = allTopics.where((topic) {
      return topicsToCover.any((topicName) => 
        topic.name.toLowerCase().contains(topicName.toLowerCase()));
    }).toList();
    
    if (targetTopics.isEmpty) {
      throw Exception('No topics found for the specified topics: $topicsToCover');
    }
    
    // Get learning outcomes for all target topics
    final allOutcomes = <LearningOutcome>[];
    for (final topic in targetTopics) {
      final outcomes = _curriculumParser.getOutcomesByTopic(subjectName, topic.id ?? 0);
      allOutcomes.addAll(outcomes);
    }
    
    // Generate exam sections based on exam type
    final sections = await _generateExamSections(
      subjectName,
      examType,
      totalMarks,
      targetTopics,
      allOutcomes,
    );
    
    // Create exam
    final exam = Exam(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subjectName: subjectName,
      className: className,
      examType: examType,
      title: examTitle ?? '${examType.toUpperCase()} Examination - $subjectName',
      duration: duration,
      totalMarks: totalMarks,
      examDate: examDate ?? DateTime.now(),
      instructions: _generateExamInstructions(examType, duration),
      sections: sections,
      markingScheme: _generateMarkingScheme(sections),
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return exam;
  }

  /// Generate exam sections based on NCDC curriculum
  Future<List<ExamSection>> _generateExamSections(
    String subjectName,
    String examType,
    int totalMarks,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
  ) async {
    
    final sections = <ExamSection>[];
    
    switch (examType.toLowerCase()) {
      case 'assessment':
        sections.addAll(await _generateAssessmentSections(subjectName, topics, outcomes, totalMarks));
        break;
      case 'mid_term':
        sections.addAll(await _generateMidTermSections(subjectName, topics, outcomes, totalMarks));
        break;
      case 'end_term':
        sections.addAll(await _generateEndTermSections(subjectName, topics, outcomes, totalMarks));
        break;
      case 'mock':
        sections.addAll(await _generateMockExamSections(subjectName, topics, outcomes, totalMarks));
        break;
      default:
        sections.addAll(await _generateAssessmentSections(subjectName, topics, outcomes, totalMarks));
    }
    
    return sections;
  }

  /// Generate assessment sections (short, formative)
  Future<List<ExamSection>> _generateAssessmentSections(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int totalMarks,
  ) async {
    
    final sections = <ExamSection>[];
    
    // Section 1: Multiple Choice (40% of marks)
    final mcqMarks = (totalMarks * 0.4).round();
    final mcqQuestions = await _generateMultipleChoiceQuestions(
      subjectName,
      topics,
      outcomes,
      mcqMarks ~/ 2, // 2 marks per question
    );
    
    sections.add(ExamSection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Section A: Multiple Choice Questions',
      instructions: 'Choose the best answer for each question.',
      totalMarks: mcqMarks,
      questions: mcqQuestions,
      isCompulsory: true,
    ));
    
    // Section 2: Short Answer (60% of marks)
    final shortAnswerMarks = totalMarks - mcqMarks;
    final shortQuestions = await _generateShortAnswerQuestions(
      subjectName,
      topics,
      outcomes,
      shortAnswerMarks ~/ 4, // 4 marks per question
    );
    
    sections.add(ExamSection(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      title: 'Section B: Short Answer Questions',
      instructions: 'Answer all questions briefly and clearly.',
      totalMarks: shortAnswerMarks,
      questions: shortQuestions,
      isCompulsory: true,
    ));
    
    return sections;
  }

  /// Generate mid-term exam sections
  Future<List<ExamSection>> _generateMidTermSections(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int totalMarks,
  ) async {
    
    final sections = <ExamSection>[];
    
    // Section 1: Multiple Choice (30%)
    final mcqMarks = (totalMarks * 0.3).round();
    final mcqQuestions = await _generateMultipleChoiceQuestions(
      subjectName,
      topics,
      outcomes,
      mcqMarks ~/ 2,
    );
    
    sections.add(ExamSection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Section A: Multiple Choice Questions',
      instructions: 'Choose the best answer for each question.',
      totalMarks: mcqMarks,
      questions: mcqQuestions,
      isCompulsory: true,
    ));
    
    // Section 2: Short Answer (40%)
    final shortMarks = (totalMarks * 0.4).round();
    final shortQuestions = await _generateShortAnswerQuestions(
      subjectName,
      topics,
      outcomes,
      shortMarks ~/ 4,
    );
    
    sections.add(ExamSection(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      title: 'Section B: Short Answer Questions',
      instructions: 'Answer all questions briefly.',
      totalMarks: shortMarks,
      questions: shortQuestions,
      isCompulsory: true,
    ));
    
    // Section 3: Structured Questions (30%)
    final structuredMarks = totalMarks - mcqMarks - shortMarks;
    final structuredQuestions = await _generateStructuredQuestions(
      subjectName,
      topics,
      outcomes,
      structuredMarks ~/ 10, // 10 marks per question
    );
    
    sections.add(ExamSection(
      id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
      title: 'Section C: Structured Questions',
      instructions: 'Answer any TWO questions from this section.',
      totalMarks: structuredMarks,
      questions: structuredQuestions,
      isCompulsory: false,
      answerAny: 2,
    ));
    
    return sections;
  }

  /// Generate end-term exam sections
  Future<List<ExamSection>> _generateEndTermSections(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int totalMarks,
  ) async {
    
    final sections = <ExamSection>[];
    
    // Section 1: Multiple Choice (25%)
    final mcqMarks = (totalMarks * 0.25).round();
    final mcqQuestions = await _generateMultipleChoiceQuestions(
      subjectName,
      topics,
      outcomes,
      mcqMarks ~/ 2,
    );
    
    sections.add(ExamSection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Section A: Multiple Choice Questions',
      instructions: 'Choose the best answer for each question.',
      totalMarks: mcqMarks,
      questions: mcqQuestions,
      isCompulsory: true,
    ));
    
    // Section 2: Short Answer (35%)
    final shortMarks = (totalMarks * 0.35).round();
    final shortQuestions = await _generateShortAnswerQuestions(
      subjectName,
      topics,
      outcomes,
      shortMarks ~/ 4,
    );
    
    sections.add(ExamSection(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      title: 'Section B: Short Answer Questions',
      instructions: 'Answer all questions briefly.',
      totalMarks: shortMarks,
      questions: shortQuestions,
      isCompulsory: true,
    ));
    
    // Section 3: Structured Questions (25%)
    final structuredMarks = (totalMarks * 0.25).round();
    final structuredQuestions = await _generateStructuredQuestions(
      subjectName,
      topics,
      outcomes,
      structuredMarks ~/ 12, // 12 marks per question
    );
    
    sections.add(ExamSection(
      id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
      title: 'Section C: Structured Questions',
      instructions: 'Answer any TWO questions from this section.',
      totalMarks: structuredMarks,
      questions: structuredQuestions,
      isCompulsory: false,
      answerAny: 2,
    ));
    
    // Section 4: Essay Questions (15%)
    final essayMarks = totalMarks - mcqMarks - shortMarks - structuredMarks;
    final essayQuestions = await _generateEssayQuestions(
      subjectName,
      topics,
      outcomes,
      essayMarks ~/ 20, // 20 marks per essay
    );
    
    sections.add(ExamSection(
      id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
      title: 'Section D: Essay Questions',
      instructions: 'Answer any ONE question from this section.',
      totalMarks: essayMarks,
      questions: essayQuestions,
      isCompulsory: false,
      answerAny: 1,
    ));
    
    return sections;
  }

  /// Generate mock exam sections (comprehensive)
  Future<List<ExamSection>> _generateMockExamSections(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int totalMarks,
  ) async {
    
    // Mock exams follow end-term structure but with more comprehensive coverage
    return await _generateEndTermSections(subjectName, topics, outcomes, totalMarks);
  }

  /// Generate multiple choice questions from NCDC content
  Future<List<Question>> _generateMultipleChoiceQuestions(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int questionCount,
  ) async {
    
    final questions = <Question>[];
    
    for (int i = 0; i < questionCount && i < outcomes.length; i++) {
      final outcome = outcomes[i];
      final topic = topics.firstWhere(
        (t) => t.id == outcome.topicId,
        orElse: () => topics.first,
      );
      
      final question = Question(
        id: DateTime.now().millisecondsSinceEpoch + i,
        text: _generateMCQQuestion(outcome, topic),
        type: 'multiple_choice',
        marks: 2,
        options: _generateMCQOptions(outcome, topic),
        correctAnswer: _generateCorrectAnswer(outcome, topic),
        topic: topic.name,
        learningOutcome: outcome.outcomeText,
        ncdcBased: true,
      );
      
      questions.add(question);
    }
    
    return questions;
  }

  /// Generate short answer questions
  Future<List<Question>> _generateShortAnswerQuestions(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int questionCount,
  ) async {
    
    final questions = <Question>[];
    
    for (int i = 0; i < questionCount && i < outcomes.length; i++) {
      final outcome = outcomes[i];
      final topic = topics.firstWhere(
        (t) => t.id == outcome.topicId,
        orElse: () => topics.first,
      );
      
      final question = Question(
        id: DateTime.now().millisecondsSinceEpoch + i,
        text: _generateShortAnswerQuestion(outcome, topic),
        type: 'short_answer',
        marks: 4,
        expectedAnswer: _generateExpectedAnswer(outcome),
        topic: topic.name,
        learningOutcome: outcome.outcomeText,
        ncdcBased: true,
      );
      
      questions.add(question);
    }
    
    return questions;
  }

  /// Generate structured questions
  Future<List<Question>> _generateStructuredQuestions(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int questionCount,
  ) async {
    
    final questions = <Question>[];
    
    for (int i = 0; i < questionCount && i < topics.length; i++) {
      final topic = topics[i];
      final topicOutcomes = outcomes.where((o) => o.topicId == topic.id).toList();
      
      final question = Question(
        id: DateTime.now().millisecondsSinceEpoch + i,
        text: _generateStructuredQuestion(topic, topicOutcomes),
        type: 'structured',
        marks: 12,
        subQuestions: _generateSubQuestions(topicOutcomes),
        topic: topic.name,
        learningOutcome: topicOutcomes.map((o) => o.outcomeText).join('; '),
        ncdcBased: true,
      );
      
      questions.add(question);
    }
    
    return questions;
  }

  /// Generate essay questions
  Future<List<Question>> _generateEssayQuestions(
    String subjectName,
    List<Topic> topics,
    List<LearningOutcome> outcomes,
    int questionCount,
  ) async {
    
    final questions = <Question>[];
    
    for (int i = 0; i < questionCount && i < topics.length; i++) {
      final topic = topics[i];
      final topicOutcomes = outcomes.where((o) => o.topicId == topic.id).toList();
      
      final question = Question(
        id: DateTime.now().millisecondsSinceEpoch + i,
        text: _generateEssayQuestion(topic, topicOutcomes),
        type: 'essay',
        marks: 20,
        expectedLength: '300-400 words',
        topic: topic.name,
        learningOutcome: topicOutcomes.map((o) => o.outcomeText).join('; '),
        ncdcBased: true,
      );
      
      questions.add(question);
    }
    
    return questions;
  }

  /// Generate MCQ question text
  String _generateMCQQuestion(LearningOutcome outcome, Topic topic) {
    final templates = [
      'Which of the following best describes ${outcome.outcomeText.toLowerCase()}?',
      'What is the main principle behind ${outcome.outcomeText.toLowerCase()}?',
      'The process of ${outcome.outcomeText.toLowerCase()} involves:',
      'When considering ${outcome.outcomeText.toLowerCase()}, which statement is correct?',
      'The key aspect of ${outcome.outcomeText.toLowerCase()} is:',
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Generate MCQ options
  List<String> _generateMCQOptions(LearningOutcome outcome, Topic topic) {
    final correctOption = _generateCorrectAnswer(outcome, topic);
    final options = [correctOption];
    
    // Generate distractors
    final distractors = [
      'None of the above',
      'All of the above',
      'Only A and B',
      'Only B and C',
      'Cannot be determined',
    ];
    
    while (options.length < 4) {
      final distractor = distractors[_random.nextInt(distractors.length)];
      if (!options.contains(distractor)) {
        options.add(distractor);
      }
    }
    
    // Shuffle options
    options.shuffle();
    return options;
  }

  /// Generate correct answer for MCQ
  String _generateCorrectAnswer(LearningOutcome outcome, Topic topic) {
    // Extract key concept from outcome
    final words = outcome.outcomeText.split(' ');
    if (words.length >= 3) {
      return words.sublist(0, 3).join(' ') + '...';
    }
    return outcome.outcomeText;
  }

  /// Generate short answer question
  String _generateShortAnswerQuestion(LearningOutcome outcome, Topic topic) {
    final templates = [
      'Briefly explain ${outcome.outcomeText.toLowerCase()}.',
      'Describe the process of ${outcome.outcomeText.toLowerCase()}.',
      'What are the key features of ${outcome.outcomeText.toLowerCase()}?',
      'Explain the importance of ${outcome.outcomeText.toLowerCase()}.',
      'How does ${outcome.outcomeText.toLowerCase()} affect ${topic.name.toLowerCase()}?',
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Generate expected answer for short answer
  String _generateExpectedAnswer(LearningOutcome outcome) {
    return 'Answer should demonstrate understanding of: ${outcome.outcomeText}';
  }

  /// Generate structured question
  String _generateStructuredQuestion(Topic topic, List<LearningOutcome> outcomes) {
    return '''
With reference to ${topic.name}, answer the following:

a) Define and explain the key concepts
b) Describe the main processes involved
c) Analyze the importance and applications
d) Evaluate the effectiveness and limitations
    ''';
  }

  /// Generate sub-questions for structured questions
  List<SubQuestion> _generateSubQuestions(List<LearningOutcome> outcomes) {
    final subQuestions = <SubQuestion>[];
    
    final subParts = [
      {'text': 'Define the key terms and concepts', 'marks': 3},
      {'text': 'Describe the main processes', 'marks': 3},
      {'text': 'Explain the importance', 'marks': 3},
      {'text': 'Provide examples', 'marks': 3},
    ];
    
    for (int i = 0; i < subParts.length && i < 4; i++) {
      final part = subParts[i];
      subQuestions.add(SubQuestion(
        id: i + 1,
        text: part['text'] as String,
        marks: part['marks'] as int,
      ));
    }
    
    return subQuestions;
  }

  /// Generate essay question
  String _generateEssayQuestion(Topic topic, List<LearningOutcome> outcomes) {
    return '''
Critically analyze the concept of ${topic.name} in the context of ${outcomes.first.outcomeText}.

In your essay, you should:
- Define and explain the key concepts
- Discuss the theoretical foundations
- Analyze practical applications
- Evaluate the significance and implications
- Provide relevant examples

Your essay should be well-structured and comprehensive.
    ''';
  }

  /// Generate exam instructions
  String _generateExamInstructions(String examType, int duration) {
    final instructions = <String>[];
    
    instructions.add('EXAMINATION INSTRUCTIONS');
    instructions.add('');
    instructions.add('1. Read all questions carefully before answering.');
    instructions.add('2. Write your name and class on every page.');
    instructions.add('3. This paper consists of ${duration ~/ 60} hour(s) and ${duration % 60} minutes.');
    instructions.add('4. Answer questions according to the instructions in each section.');
    instructions.add('5. All work must be shown for calculations.');
    instructions.add('6. Write neatly and legibly.');
    instructions.add('7. Do not use correction fluid or tape.');
    instructions.add('8. Check your work before submitting.');
    
    if (examType.toLowerCase() == 'mock') {
      instructions.add('9. This is a mock examination - treat it as final.');
    }
    
    instructions.add('');
    instructions.add('This examination is based on NCDC official curriculum content.');
    
    return instructions.join('\n');
  }

  /// Generate marking scheme
  String _generateMarkingScheme(List<ExamSection> sections) {
    final scheme = <String>[];
    
    scheme.add('MARKING SCHEME');
    scheme.add('');
    
    for (final section in sections) {
      scheme.add('${section.title}: ${section.totalMarks} marks');
      
      for (final question in section.questions) {
        scheme.add('  Question ${question.id}: ${question.marks} marks');
        
        if (question.subQuestions?.isNotEmpty == true) {
          for (final subQuestion in question.subQuestions!) {
            scheme.add('    ${subQuestion.id}) ${subQuestion.marks} marks');
          }
        }
      }
      scheme.add('');
    }
    
    scheme.add('Total: ${sections.fold(0, (sum, section) => sum + section.totalMarks)} marks');
    
    return scheme.join('\n');
  }

  /// Get available subjects for exam generation
  Future<List<String>> getAvailableSubjects() async {
    await _curriculumParser.parseAllSyllabusFiles();
    return _curriculumParser.getAllSubjectNames();
  }

  /// Get available topics for a subject
  Future<List<String>> getAvailableTopics(String subjectName) async {
    await _curriculumParser.parseAllSyllabusFiles();
    final topics = _curriculumParser.getTopics(subjectName);
    return topics.map((t) => t.name).toList();
  }

  /// Export exam to various formats
  Future<String> exportExam(Exam exam, String format) async {
    switch (format.toLowerCase()) {
      case 'markdown':
        return _exportToMarkdown(exam);
      case 'pdf':
        return _exportToPDF(exam);
      case 'word':
        return _exportToWord(exam);
      default:
        return _exportToMarkdown(exam);
    }
  }

  String _exportToMarkdown(Exam exam) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${exam.title}');
    buffer.writeln();
    buffer.writeln('**Subject:** ${exam.subjectName}');
    buffer.writeln('**Class:** ${exam.className}');
    buffer.writeln('**Type:** ${exam.examType}');
    buffer.writeln('**Duration:** ${exam.duration} minutes');
    buffer.writeln('**Total Marks:** ${exam.totalMarks}');
    buffer.writeln('**Date:** ${exam.examDate.toString().split(' ')[0]}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    buffer.writeln('## Instructions');
    buffer.writeln();
    buffer.writeln(exam.instructions);
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    for (final section in exam.sections) {
      buffer.writeln('## ${section.title}');
      buffer.writeln();
      buffer.writeln('**Marks:** ${section.totalMarks}');
      buffer.writeln();
      buffer.writeln(section.instructions);
      buffer.writeln();
      
      for (final question in section.questions) {
        buffer.writeln('### Question ${question.id}');
        buffer.writeln();
        buffer.writeln('**Marks:** ${question.marks}');
        buffer.writeln('**Topic:** ${question.topic}');
        buffer.writeln();
        buffer.writeln(question.text);
        buffer.writeln();
        
        if (question.options?.isNotEmpty == true) {
          for (int i = 0; i < question.options!.length; i++) {
            buffer.writeln('${String.fromCharCode(65 + i)}. ${question.options![i]}');
          }
          buffer.writeln();
        }
        
        if (question.subQuestions?.isNotEmpty == true) {
          for (final subQuestion in question.subQuestions!) {
            buffer.writeln('**${subQuestion.id})** ${subQuestion.text} (${subQuestion.marks} marks)');
            buffer.writeln();
          }
        }
        
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    
    buffer.writeln('## Marking Scheme');
    buffer.writeln();
    buffer.writeln(exam.markingScheme);
    
    return buffer.toString();
  }

  String _exportToPDF(Exam exam) {
    // Placeholder for PDF export
    return 'PDF export not yet implemented';
  }

  String _exportToWord(Exam exam) {
    // Placeholder for Word export
    return 'Word export not yet implemented';
  }
}

/// Exam Model
class Exam {
  String id;
  String subjectName;
  String className;
  String examType;
  String title;
  int duration; // in minutes
  int totalMarks;
  DateTime examDate;
  String instructions;
  List<ExamSection> sections;
  String markingScheme;
  String status;
  DateTime createdAt;
  DateTime updatedAt;

  Exam({
    required this.id,
    required this.subjectName,
    required this.className,
    required this.examType,
    required this.title,
    required this.duration,
    required this.totalMarks,
    required this.examDate,
    required this.instructions,
    required this.sections,
    required this.markingScheme,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'className': className,
      'examType': examType,
      'title': title,
      'duration': duration,
      'totalMarks': totalMarks,
      'examDate': examDate.toIso8601String(),
      'instructions': instructions,
      'sections': sections.map((s) => s.toMap()).toList(),
      'markingScheme': markingScheme,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Exam Section Model
class ExamSection {
  String id;
  String title;
  String instructions;
  int totalMarks;
  List<Question> questions;
  bool isCompulsory;
  int? answerAny; // Number of questions to answer if not compulsory

  ExamSection({
    required this.id,
    required this.title,
    required this.instructions,
    required this.totalMarks,
    required this.questions,
    required this.isCompulsory,
    this.answerAny,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'instructions': instructions,
      'totalMarks': totalMarks,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isCompulsory': isCompulsory,
      'answerAny': answerAny,
    };
  }
}

/// Question Model
class Question {
  int id;
  String text;
  String type; // multiple_choice, short_answer, structured, essay
  int marks;
  List<String>? options;
  String? correctAnswer;
  String? expectedAnswer;
  String? expectedLength;
  List<SubQuestion>? subQuestions;
  String topic;
  String learningOutcome;
  bool ncdcBased;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.marks,
    this.options,
    this.correctAnswer,
    this.expectedAnswer,
    this.expectedLength,
    this.subQuestions,
    required this.topic,
    required this.learningOutcome,
    required this.ncdcBased,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'marks': marks,
      'options': options,
      'correctAnswer': correctAnswer,
      'expectedAnswer': expectedAnswer,
      'expectedLength': expectedLength,
      'subQuestions': subQuestions?.map((sq) => sq.toMap()).toList(),
      'topic': topic,
      'learningOutcome': learningOutcome,
      'ncdcBased': ncdcBased,
    };
  }
}

/// Sub-Question Model
class SubQuestion {
  int id;
  String text;
  int marks;

  SubQuestion({
    required this.id,
    required this.text,
    required this.marks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'marks': marks,
    };
  }
}
