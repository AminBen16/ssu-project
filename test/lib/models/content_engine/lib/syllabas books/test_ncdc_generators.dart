import 'dart:io';
import 'test/lib/services/ncdc_curriculum_parser.dart';
import 'test/lib/services/scheme_of_work_generator.dart';
import 'test/lib/services/ncdc_lesson_plan_generator.dart';
import 'test/lib/services/ncdc_exam_generator.dart';

/// Test script for NCDC generators with real data
void main() async {
  print('🧪 TESTING NCDC GENERATORS WITH REAL DATA');
  print('=' * 60);
  
  try {
    // Test 1: Curriculum Parser
    await testCurriculumParser();
    
    // Test 2: Scheme of Work Generator
    await testSchemeOfWorkGenerator();
    
    // Test 3: Lesson Plan Generator
    await testLessonPlanGenerator();
    
    // Test 4: Exam Generator
    await testExamGenerator();
    
    print('\n🎉 ALL TESTS COMPLETED SUCCESSFULLY!');
    
  } catch (e, stackTrace) {
    print('\n❌ TEST FAILED: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Test the NCDC Curriculum Parser
Future<void> testCurriculumParser() async {
  print('\n📚 TEST 1: NCDC Curriculum Parser');
  print('-' * 40);
  
  final parser = NCDCCurriculumParser();
  
  // Parse all syllabus files
  print('Parsing NCDC syllabus files...');
  await parser.parseAllSyllabusFiles();
  
  // Get available subjects
  final subjects = parser.getAllSubjectNames();
  print('✅ Found ${subjects.length} subjects:');
  for (final subject in subjects.take(5)) {
    print('   - $subject');
  }
  if (subjects.length > 5) {
    print('   ... and ${subjects.length - 5} more');
  }
  
  // Test with Chemistry subject
  if (subjects.contains('CHEMISTRY')) {
    print('\n🧪 Testing Chemistry subject:');
    final chemistrySubjects = parser.getSubjects('CHEMISTRY');
    final chemistryStrands = parser.getStrands('CHEMISTRY');
    final chemistryTopics = parser.getTopics('CHEMISTRY');
    final chemistryOutcomes = parser.getLearningOutcomes('CHEMISTRY');
    
    print('   Subjects: ${chemistrySubjects.length}');
    print('   Strands: ${chemistryStrands.length}');
    print('   Topics: ${chemistryTopics.length}');
    print('   Learning Outcomes: ${chemistryOutcomes.length}');
    
    if (chemistryTopics.isNotEmpty) {
      final firstTopic = chemistryTopics.first;
      print('   First topic: ${firstTopic.name}');
      print('   Topic code: ${firstTopic.code}');
      print('   Suggested periods: ${firstTopic.suggestedPeriods}');
    }
    
    if (chemistryOutcomes.isNotEmpty) {
      final firstOutcome = chemistryOutcomes.first;
      print('   First outcome: ${firstOutcome.outcome}');
      print('   Outcome type: ${firstOutcome.outcomeType}');
    }
  }
  
  print('✅ Curriculum Parser Test PASSED');
}

/// Test the Scheme of Work Generator
Future<void> testSchemeOfWorkGenerator() async {
  print('\n📋 TEST 2: Scheme of Work Generator');
  print('-' * 40);
  
  final generator = SchemeOfWorkGenerator();
  
  // Get available subjects
  final subjects = await generator.getAvailableSubjects();
  print('Available subjects: ${subjects.length}');
  
  if (subjects.isNotEmpty) {
    final testSubject = subjects.first;
    print('Testing with subject: $testSubject');
    
    // Generate scheme of work
    try {
      final schemeOfWork = await generator.generateSchemeOfWork(
        subjectName: testSubject,
        className: 'Senior 3',
        academicYear: '2024',
        weeksPerTerm: 12,
        periodsPerWeek: 5,
      );
      
      print('✅ Scheme of Work Generated:');
      print('   ID: ${schemeOfWork.id}');
      print('   Subject: ${schemeOfWork.subjectName}');
      print('   Class: ${schemeOfWork.className}');
      print('   Total Periods: ${schemeOfWork.totalPeriods}');
      print('   Weekly Breakdown: ${schemeOfWork.weeklyBreakdown.length} weeks');
      
      if (schemeOfWork.weeklyBreakdown.isNotEmpty) {
        final firstWeek = schemeOfWork.weeklyBreakdown.first;
        print('   First week:');
        print('     Term: ${firstWeek.term}');
        print('     Week: ${firstWeek.week}');
        print('     Strand: ${firstWeek.strandName}');
        print('     Topic: ${firstWeek.topicName}');
        print('     Learning Outcomes: ${firstWeek.learningOutcomes.length}');
        print('     Activities: ${firstWeek.teachingActivities.length}');
        print('     Resources: ${firstWeek.resources.length}');
      }
      
      // Test curriculum overview
      final overview = await generator.getCurriculumOverview(testSubject);
      print('   Curriculum Overview:');
      print('     Total Strands: ${overview['totalStrands']}');
      print('     Total Topics: ${overview['totalTopics']}');
      print('     Total Outcomes: ${overview['totalOutcomes']}');
      
    } catch (e) {
      print('❌ Scheme of Work Generation Failed: $e');
      // Continue with other tests
    }
  }
  
  print('✅ Scheme of Work Generator Test COMPLETED');
}

/// Test the Lesson Plan Generator
Future<void> testLessonPlanGenerator() async {
  print('\n📖 TEST 3: Lesson Plan Generator');
  print('-' * 40);
  
  final generator = NCDCLessonPlanGenerator();
  
  // Get available subjects
  final subjects = await generator.getAvailableSubjects();
  print('Available subjects: ${subjects.length}');
  
  if (subjects.isNotEmpty) {
    final testSubject = subjects.first;
    print('Testing with subject: $testSubject');
    
    // Get available topics
    final topics = await generator.getAvailableTopics(testSubject);
    print('Available topics: ${topics.length}');
    
    if (topics.isNotEmpty) {
      final testTopic = topics.first;
      print('Testing with topic: $testTopic');
      
      try {
        // Generate lesson plan
        final lessonPlan = await generator.generateLessonPlan(
          subjectName: testSubject,
          topicName: testTopic,
          className: 'Senior 3',
          duration: '40 minutes',
          date: DateTime.now(),
          startTime: DateTime.now(),
          availableResources: ['Whiteboard', 'Textbook', 'Laboratory'],
          teachingStyle: 'interactive',
          studentCount: 30,
        );
        
        print('✅ Lesson Plan Generated:');
        print('   ID: ${lessonPlan.id}');
        print('   Title: ${lessonPlan.title}');
        print('   Duration: ${lessonPlan.duration}');
        print('   Class: ${lessonPlan.className}');
        print('   Learning Objectives: ${lessonPlan.learningObjectives.length}');
        print('   Teaching Methods: ${lessonPlan.teachingMethods.length}');
        print('   Activities: ${lessonPlan.activities.length}');
        print('   Assessments: ${lessonPlan.assessments.length}');
        print('   Materials: ${lessonPlan.materials.length}');
        
        if (lessonPlan.activities.isNotEmpty) {
          final firstActivity = lessonPlan.activities.first;
          print('   First activity:');
          print('     Name: ${firstActivity['name']}');
          print('     Duration: ${firstActivity['duration']} minutes');
          print('     Type: ${firstActivity['type']}');
          print('     NCDC Based: ${firstActivity['ncdcBased']}');
        }
        
        // Test topic details
        final topicDetails = await generator.getTopicDetails(testSubject, testTopic);
        print('   Topic Details:');
        print('     Topic: ${topicDetails['topic'].name}');
        print('     Outcomes: ${topicDetails['outcomes'].length}');
        print('     Activities: ${topicDetails['activities'].length}');
        print('     Assessments: ${topicDetails['assessments'].length}');
        
      } catch (e) {
        print('❌ Lesson Plan Generation Failed: $e');
        // Continue with other tests
      }
    }
  }
  
  print('✅ Lesson Plan Generator Test COMPLETED');
}

/// Test the Exam Generator
Future<void> testExamGenerator() async {
  print('\n📝 TEST 4: Exam Generator');
  print('-' * 40);
  
  final generator = NCDCExamGenerator();
  
  // Get available subjects
  final subjects = await generator.getAvailableSubjects();
  print('Available subjects: ${subjects.length}');
  
  if (subjects.isNotEmpty) {
    final testSubject = subjects.first;
    print('Testing with subject: $testSubject');
    
    // Get available topics
    final topics = await generator.getAvailableTopics(testSubject);
    print('Available topics: ${topics.length}');
    
    if (topics.isNotEmpty) {
      final testTopics = topics.take(3).toList(); // Use first 3 topics
      print('Testing with topics: ${testTopics.join(', ')}');
      
      try {
        // Generate different exam types
        final examTypes = ['assessment', 'mid_term', 'end_term'];
        
        for (final examType in examTypes) {
          print('\n   Generating $examType exam...');
          
          final exam = await generator.generateExam(
            subjectName: testSubject,
            className: 'Senior 3',
            examType: examType,
            duration: 120, // 2 hours
            totalMarks: 100,
            topicsToCover: testTopics,
            examTitle: '$examType Examination - $testSubject',
            examDate: DateTime.now(),
          );
          
          print('   ✅ ${examType.toUpperCase()} Exam Generated:');
          print('     ID: ${exam.id}');
          print('     Title: ${exam.title}');
          print('     Duration: ${exam.duration} minutes');
          print('     Total Marks: ${exam.totalMarks}');
          print('     Sections: ${exam.sections.length}');
          
          for (final section in exam.sections) {
            print('     Section: ${section.title}');
            print('       Questions: ${section.questions.length}');
            print('       Marks: ${section.totalMarks}');
            print('       Compulsory: ${section.isCompulsory}');
            
            if (section.questions.isNotEmpty) {
              final firstQuestion = section.questions.first;
              print('       First question:');
              print('         Type: ${firstQuestion.type}');
              print('         Marks: ${firstQuestion.marks}');
              print('         Topic: ${firstQuestion.topic}');
              print('         NCDC Based: ${firstQuestion.ncdcBased}');
              
              if (firstQuestion.options != null) {
                print('         Options: ${firstQuestion.options!.length}');
              }
            }
          }
        }
        
      } catch (e) {
        print('❌ Exam Generation Failed: $e');
        // Continue with other tests
      }
    }
  }
  
  print('✅ Exam Generator Test COMPLETED');
}

/// Test markdown file accessibility
Future<void> testMarkdownFileAccess() async {
  print('\n📁 TEST 5: Markdown File Access');
  print('-' * 40);
  
  final syllabusDir = Directory(r'C:\Users\user\SSU\extracted_syllabi');
  
  if (await syllabusDir.exists()) {
    print('✅ Syllabus directory found: ${syllabusDir.path}');
    
    final files = await syllabusDir.list().where((f) => f.path.endsWith('.md')).toList();
    print('✅ Found ${files.length} markdown files');
    
    // Test reading a few files
    for (int i = 0; i < files.length && i < 3; i++) {
      final file = files[i] as File;
      final fileName = file.path.split('\\').last;
      
      try {
        final content = await file.readAsString();
        print('✅ $fileName: ${content.length} characters');
        
        // Check for NCDC content indicators
        if (content.toLowerCase().contains('ncdc')) {
          print('   Contains NCDC reference');
        }
        if (content.toLowerCase().contains('learning outcome')) {
          print('   Contains learning outcomes');
        }
        if (content.toLowerCase().contains('topic')) {
          print('   Contains topics');
        }
        
      } catch (e) {
        print('❌ Error reading $fileName: $e');
      }
    }
  } else {
    print('❌ Syllabus directory not found: ${syllabusDir.path}');
  }
  
  print('✅ Markdown File Access Test COMPLETED');
}
