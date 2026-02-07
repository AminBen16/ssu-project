import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/book_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/library_service.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  late Future<List<Book>> _booksFuture;
  final LibraryService _libraryService = LibraryService();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    final schoolId = Provider.of<UserDataProvider>(context, listen: false)
        .userProfile
        ?.schoolId;
    
    if (schoolId != null) {
      setState(() {
        _booksFuture = _libraryService.getBooks(schoolId);
      });
    }
  }

  Future<void> _showBookDialog({Book? book}) async {
    final isEditing = book != null;
    final titleController = TextEditingController(text: book?.title);
    final authorController = TextEditingController(text: book?.author);
    final quantityController =
        TextEditingController(text: book?.quantity.toString());

    final schoolId = Provider.of<UserDataProvider>(context, listen: false)
        .userProfile
        ?.schoolId;

    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot perform action: School ID not found.')));
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Book' : 'Add New Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title')),
                TextField(
                    controller: authorController,
                    decoration: const InputDecoration(labelText: 'Author')),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
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
                final newBook = Book(
                  id: book?.id,
                  schoolId: schoolId,
                  title: titleController.text,
                  author: authorController.text,
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  availableQuantity: int.tryParse(quantityController.text) ?? 1,
                );

                // Capture navigator and messenger before awaiting to avoid
                // using BuildContext across async gaps.
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  if (isEditing) {
                    await _libraryService.updateBook(schoolId, newBook);
                  } else {
                    await _libraryService.createBook(schoolId, newBook);
                  }

                  if (!mounted) return;
                  navigator.pop();
                  _loadBooks(); // Refresh the list
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                      SnackBar(content: Text('Failed to save book: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Library Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No books found. Add one to get started.'));
          }

          final books = snapshot.data!;
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.title),
                subtitle: Text(
                    'By ${book.author ?? 'Unknown'} | Available: ${book.availableQuantity}/${book.quantity}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showBookDialog(book: book),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final schoolId = Provider.of<UserDataProvider>(context, listen: false).userProfile?.schoolId;
                        if (schoolId != null) {
                          await _libraryService.deleteBook(schoolId, book.id!);
                          _loadBooks();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookDialog(),
        tooltip: 'Add New Book',
        child: const Icon(Icons.add),
      ),
    );
  }
}
