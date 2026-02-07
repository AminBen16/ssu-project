import 'dart:convert';

import 'package:test/models/question_model.dart';

class Exam {
  final String? id;
  final String title;
  final String description;
  final String? instructions;
  final String className;
  final String subject;
  final List<Question> questions;
  final String teacherId;
  final String schoolId;
  final DateTime date;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Exam({
    this.id,
    required this.title,
    required this.description,
    this.instructions,
    required this.className,
    required this.subject,
    required this.questions,
    required this.teacherId,
    required this.schoolId,
    required this.date,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructions': instructions,
      'className': className,
      'subject': subject,
      'questions': questions.map((x) => x.toMap()).toList(),
      'teacherId': teacherId,
      'schoolId': schoolId,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] != null ? map['id'] as String : null,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructions: map['instructions'] as String?,
      className: map['className'] ?? '',
      subject: map['subject'] ?? '',
      questions: map['questions'] != null
          ? List<Question>.from(
              (map['questions'] as List<dynamic>).map<Question>(
                (x) => Question.fromMap(x as Map<String, dynamic>),
              ),
            )
          : [],
      teacherId: map['teacherId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      date: DateTime.parse(map['date']),
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Exam.fromJson(String source) => Exam.fromMap(json.decode(source));
}
