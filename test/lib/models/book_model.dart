class Book {
  final String? id;
  final String schoolId;
  final String title;
  final String? author;
  final String? isbn;
  final String? publisher;
  final int quantity;
  final int availableQuantity;

  Book({
    this.id,
    required this.schoolId,
    required this.title,
    this.author,
    this.isbn,
    this.publisher,
    required this.quantity,
    required this.availableQuantity,
  });

  factory Book.fromMap(Map<String, dynamic> data) {
    return Book(
      id: data['id']?.toString(),
      schoolId: data['school_id'] ?? '',
      title: data['title'] ?? 'No Title',
      author: data['author'],
      isbn: data['isbn'],
      publisher: data['publisher'],
      quantity: data['quantity'] ?? 0,
      availableQuantity: data['available_quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'school_id': schoolId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publisher': publisher,
      'quantity': quantity,
      'available_quantity': availableQuantity,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? quantity,
    int? availableQuantity,
  }) {
    return Book(
      id: id ?? this.id,
      schoolId: schoolId,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn,
      publisher: publisher,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }
}
