import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../services/library_service.dart';
import '../widgets/future_handler.dart';
import '../models/book_model.dart';

/// Screen for managing the book catalog in the library.
/// PHASE 3: SAFE COMPLETION - Implementing librarian dashboard features.
/// Replaces "Coming Soon" placeholder with functional book catalog management.
class BookCatalogScreen extends StatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  State<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

class _BookCatalogScreenState extends State<BookCatalogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    final schoolId = userData.userProfile?.schoolId;

    if (schoolId == null) {
      return const Scaffold(
        body: Center(child: Text('School information not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBookDialog(context),
            tooltip: 'Add New Book',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books by title, author, or ISBN...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: FutureHandler<List<Map<String, dynamic>>>(
              future: _fetchBooks(schoolId),
              loadingWidget: const Center(child: CircularProgressIndicator()),
              emptyMessage: 'No books in catalog.',
              builder: (context, books) {
                final filteredBooks = books.where((book) {
                  final title = book['title']?.toString().toLowerCase() ?? '';
                  final author = book['author']?.toString().toLowerCase() ?? '';
                  final isbn = book['isbn']?.toString().toLowerCase() ?? '';
                  return title.contains(_searchQuery) ||
                      author.contains(_searchQuery) ||
                      isbn.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.book, color: Colors.blue),
                        ),
                        title: Text(book['title'] ?? 'Unknown Title'),
                        subtitle: Text(
                          'Author: ${book['author'] ?? 'Unknown'}\nISBN: ${book['isbn'] ?? 'N/A'} • Available: ${book['available_quantity'] ?? 0}/${book['quantity'] ?? 0}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) =>
                              _handleBookAction(context, book, value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Book'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Book'),
                            ),
                          ],
                        ),
                        onTap: () => _showBookDetails(context, book),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchBooks(String schoolId) async {
    final libraryService = LibraryService();
    try {
      final books = await libraryService.getBooks(schoolId);
      return books.map((book) => book.toMap()).toList();
    } catch (e) {
      // Return empty list on error - offline fallback will be handled by service
      return [];
    }
  }

  void _showAddBookDialog(BuildContext context) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final isbnController = TextEditingController();
    final categoryController = TextEditingController();
    final totalCopiesController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Book'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author *'),
              ),
              TextField(
                controller: isbnController,
                decoration: const InputDecoration(labelText: 'ISBN'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: totalCopiesController,
                decoration: const InputDecoration(labelText: 'Total Copies *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  authorController.text.isEmpty ||
                  totalCopiesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final userData =
                  Provider.of<UserDataProvider>(context, listen: false);
              final schoolId = userData.userProfile?.schoolId;

              if (schoolId != null) {
                try {
                  final book = Book(
                    schoolId: schoolId,
                    title: titleController.text,
                    author: authorController.text,
                    quantity: int.parse(totalCopiesController.text),
                    availableQuantity: int.parse(totalCopiesController.text),
                    isbn: isbnController.text.isEmpty
                        ? null
                        : isbnController.text,
                  );

                  final libraryService = LibraryService();
                  await libraryService.createBook(schoolId, book);

                  Navigator.of(context).pop();
                  setState(() {}); // Refresh the list

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding book: $e')),
                  );
                }
              }
            },
            child: const Text('Add Book'),
          ),
        ],
      ),
    );
  }

  void _handleBookAction(
      BuildContext context, Map<String, dynamic> book, String action) {
    switch (action) {
      case 'edit':
        _showEditBookDialog(context, book);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context, book);
        break;
    }
  }

  void _showEditBookDialog(BuildContext context, Map<String, dynamic> book) {
    final titleController = TextEditingController(text: book['title']);
    final authorController = TextEditingController(text: book['author']);
    final isbnController = TextEditingController(text: book['isbn']);
    final quantityController =
        TextEditingController(text: book['quantity']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Book'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author *'),
              ),
              TextField(
                controller: isbnController,
                decoration: const InputDecoration(labelText: 'ISBN'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Total Copies *'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  authorController.text.isEmpty ||
                  quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final userData =
                  Provider.of<UserDataProvider>(context, listen: false);
              final schoolId = userData.userProfile?.schoolId;

              if (schoolId != null && book['id'] != null) {
                try {
                  final updatedBook = Book(
                    id: book['id'],
                    schoolId: schoolId,
                    title: titleController.text,
                    author: authorController.text,
                    quantity: int.parse(quantityController.text),
                    availableQuantity: int.parse(
                        quantityController.text), // Reset available to total
                    isbn: isbnController.text.isEmpty
                        ? null
                        : isbnController.text,
                  );

                  final libraryService = LibraryService();
                  await libraryService.updateBook(schoolId, updatedBook);

                  Navigator.of(context).pop();
                  setState(() {}); // Refresh the list

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating book: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
            'Are you sure you want to delete "${book['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final userData =
                  Provider.of<UserDataProvider>(context, listen: false);
              final schoolId = userData.userProfile?.schoolId;

              if (schoolId != null && book['id'] != null) {
                try {
                  final libraryService = LibraryService();
                  await libraryService.deleteBook(schoolId, book['id']);

                  Navigator.of(context).pop();
                  setState(() {}); // Refresh the list

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting book: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBookDetails(BuildContext context, Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book['title'] ?? 'Book Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${book['author'] ?? 'Unknown'}'),
            Text('ISBN: ${book['isbn'] ?? 'N/A'}'),
            Text('Category: ${book['category'] ?? 'Uncategorized'}'),
            Text('Total Copies: ${book['totalCopies'] ?? 0}'),
            Text('Available Copies: ${book['availableCopies'] ?? 0}'),
            Text('Location: ${book['location'] ?? 'Not specified'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
