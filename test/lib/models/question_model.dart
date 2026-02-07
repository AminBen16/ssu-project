enum QuestionType {
  multipleChoice,
  shortAnswer,
  essay,
}

class Question {
  final String text;
  final QuestionType type;
  final List<String> options;
  final String? imageUrl;
  final bool? ncdcBased;

  Question({
    required this.text,
    required this.type,
    this.options = const [],
    this.imageUrl,
    this.ncdcBased,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      text: map['text'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestionType.shortAnswer,
      ),
      options: List<String>.from(map['options'] ?? []),
      imageUrl: map['imageUrl'],
      ncdcBased: map['ncdcBased'] as bool? ?? map['nccdcBased'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type.name,
      'options': options,
      'imageUrl': imageUrl,
      'ncdcBased': ncdcBased,
    };
  }

  Question copyWith({
    String? text,
    QuestionType? type,
    List<String>? options,
    String? imageUrl,
    bool? ncdcBased,
  }) {
    return Question(
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
      imageUrl: imageUrl ?? this.imageUrl,
      ncdcBased: ncdcBased ?? this.ncdcBased,
    );
  }

  // Compatibility getter (typo in some callers: nccdcBased)
  bool? get nccdcBased => ncdcBased;
}
