import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing student marks and grades
class MarksService {
  static Database? _database;
  static const String _dbName = 'marks_database.db';
  static const int _dbVersion = 1;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        exam_type TEXT NOT NULL,
        marks_obtained REAL NOT NULL,
        total_marks REAL NOT NULL,
        grade TEXT,
        term TEXT,
        academic_year TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE grade_scales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_marks REAL NOT NULL,
        max_marks REAL NOT NULL,
        grade TEXT NOT NULL,
        points REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default grade scale
    await db.insert('grade_scales', {
      'min_marks': 90,
      'max_marks': 100,
      'grade': 'A',
      'points': 4.0,
    });
    await db.insert('grade_scales', {
      'min_marks': 80,
      'max_marks': 89.9,
      'grade': 'B',
      'points': 3.0,
    });
    await db.insert('grade_scales', {
      'min_marks': 70,
      'max_marks': 79.9,
      'grade': 'C',
      'points': 2.0,
    });
    await db.insert('grade_scales', {
      'min_marks': 60,
      'max_marks': 69.9,
      'grade': 'D',
      'points': 1.0,
    });
    await db.insert('grade_scales', {
      'min_marks': 0,
      'max_marks': 59.9,
      'grade': 'F',
      'points': 0.0,
    });
  }

  static Future<int> addMark({
    required int studentId,
    required int subjectId,
    required String examType,
    required double marksObtained,
    required double totalMarks,
    String? term,
    String? academicYear,
  }) async {
    final db = await database;
    final percentage = (marksObtained / totalMarks) * 100;
    final grade = _calculateGrade(percentage);
    
    return await db.insert('marks', {
      'student_id': studentId,
      'subject_id': subjectId,
      'exam_type': examType,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'grade': grade,
      'term': term,
      'academic_year': academicYear,
    });
  }

  static Future<List<Map<String, dynamic>>> getStudentMarks(int studentId) async {
    final db = await database;
    return await db.query(
      'marks',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getSubjectMarks(int subjectId) async {
    final db = await database;
    return await db.query(
      'marks',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<double> getStudentAverage(int studentId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(marks_obtained / total_marks * 100) as average 
      FROM marks 
      WHERE student_id = ?
    ''', [studentId]);
    
    return result.first['average'] as double? ?? 0.0;
  }

  static String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  static Future<int> updateMark(int markId, {
    required double marksObtained,
    required double totalMarks,
    String? examType,
    String? term,
    String? academicYear,
  }) async {
    final db = await database;
    final percentage = (marksObtained / totalMarks) * 100;
    final grade = _calculateGrade(percentage);
    
    return await db.update(
      'marks',
      {
        'marks_obtained': marksObtained,
        'total_marks': totalMarks,
        'grade': grade,
        if (examType != null) 'exam_type': examType,
        if (term != null) 'term': term,
        if (academicYear != null) 'academic_year': academicYear,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [markId],
    );
  }

  static Future<int> deleteMark(int markId) async {
    final db = await database;
    return await db.delete('marks', where: 'id = ?', whereArgs: [markId]);
  }

  static Future<Map<String, dynamic>> getStudentGrades(int schoolId, String studentId) async {
    final db = await database;
    final marks = await db.query(
      'marks',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );

    if (marks.isEmpty) {
      return {
        'overallGrade': 'N/A',
        'gpa': 0.0,
        'recentSubjects': [],
      };
    }

    // Calculate overall grade and GPA
    double totalPoints = 0.0;
    int subjectCount = 0;
    final subjectGrades = <Map<String, dynamic>>[];

    // Group by subject
    final subjectMap = <int, List<Map<String, dynamic>>>{};
    for (final mark in marks) {
      final subjectId = mark['subject_id'] as int;
      subjectMap.putIfAbsent(subjectId, () => []).add(mark);
    }

    for (final subjectMarks in subjectMap.values) {
      if (subjectMarks.isNotEmpty) {
        final latestMark = subjectMarks.first;
        final percentage = (latestMark['marks_obtained'] as double) / (latestMark['total_marks'] as double) * 100;
        final grade = _calculateGrade(percentage);
        final points = _getGradePoints(grade);

        totalPoints += points;
        subjectCount++;

        subjectGrades.add({
          'subject': 'Subject ${latestMark['subject_id']}', // TODO: Get actual subject name
          'grade': grade,
          'score': percentage,
        });
      }
    }

    final gpa = subjectCount > 0 ? totalPoints / subjectCount : 0.0;
    final overallGrade = _calculateGradeFromGPA(gpa);

    return {
      'overallGrade': overallGrade,
      'gpa': gpa,
      'recentSubjects': subjectGrades.take(10).toList(), // Return up to 10 recent subjects
    };
  }

  static double _getGradePoints(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 4.0;
      case 'B':
        return 3.0;
      case 'C':
        return 2.0;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return 0.0;
    }
  }

  static String _calculateGradeFromGPA(double gpa) {
    if (gpa >= 3.5) return 'A';
    if (gpa >= 3.0) return 'B';
    if (gpa >= 2.0) return 'C';
    if (gpa >= 1.0) return 'D';
    return 'F';
  }
}
