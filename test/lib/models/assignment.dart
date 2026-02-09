class Assignment {
  final String title;
  final String description;
  final DateTime? dueDate;

  Assignment({
    required this.title,
    required this.description,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
