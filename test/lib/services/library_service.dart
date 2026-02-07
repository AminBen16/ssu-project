import 'package:uuid/uuid.dart';
import 'package:test/models/book_model.dart';
import 'dart:convert';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class LibraryService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  Future<List<Book>> getBooks(String schoolId) async {
    final cacheKey = 'books_$schoolId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/schools/$schoolId/library/books');
        final List<dynamic> bookList = response['books'] as List<dynamic>;
        return bookList
            .map((json) => Book.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      offlineFallback: () async {
        // 1. Try to get cached books (list)
        final cachedJson = await _localDb.getCache(cacheKey);
        if (cachedJson != null) {
          final List<dynamic> data = jsonDecode(cachedJson);
          return data
              .map((json) => Book.fromMap(json as Map<String, dynamic>))
              .toList();
        }

        // 2. If no cached list, try to get all individual books from booksTable
        final allLocalBooks = await _localDb.getAllData('books');
        return allLocalBooks
            .map((json) => Book.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      cacheKey: cacheKey,
    );
  }

  Future<Book> createBook(String schoolId, Book book) async {
    Book bookToCreate = book;
    if (bookToCreate.id == null) {
      // Generate a client-side UUID for optimistic updates and local storage
      bookToCreate = bookToCreate.copyWith(id: Uuid().v4());
    }

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        final response = await _apiClient
            .post('/api/schools/$schoolId/library/books', body: bookToCreate.toMap());
        final createdBook = Book.fromMap(response as Map<String, dynamic>);
        await _localDb.saveData('books', createdBook.id!, createdBook.toMap()); // Save to local database
        return createdBook;
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'books',
          'schoolId': schoolId,
          ...bookToCreate.toMap(),
        });
        await _localDb.saveData('books', bookToCreate.id!, bookToCreate.toMap()); // Save to local database for immediate local availability
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'books',
        'schoolId': schoolId,
        ...bookToCreate.toMap(),
      });
      await _localDb.saveData('books', bookToCreate.id!, bookToCreate.toMap()); // Save to local database for immediate local availability
      // Return the book as if it was created (optimistic update)
      return bookToCreate;
    }
  }

  Future<Book> updateBook(String schoolId, Book book) async {
    if (book.id == null) {
      throw Exception('Book ID cannot be null for an update.');
    }

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        final response = await _apiClient.put(
            '/api/schools/$schoolId/library/books/${book.id}',
            body: book.toMap());
        final updatedBook = Book.fromMap(response as Map<String, dynamic>);
        await _localDb.saveData('books', updatedBook.id!, updatedBook.toMap());
        return updatedBook;
      } catch (e) {
        await _offlineService.queueForSync('update', {
          'table': 'books',
          'schoolId': schoolId,
          ...book.toMap(),
        });
        await _localDb.saveData('books', book.id!, book.toMap());
        rethrow;
      }
    } else {
      await _offlineService.queueForSync('update', {
        'table': 'books',
        'schoolId': schoolId,
        ...book.toMap(),
      });
      await _localDb.saveData('books', book.id!, book.toMap());
      return book;
    }
  }

  Future<void> deleteBook(String schoolId, String bookId) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.delete('/api/schools/$schoolId/library/books/$bookId');
        await _localDb.deleteData('books', bookId); // Delete from local database
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('delete', {
          'table': 'books',
          'schoolId': schoolId,
          'id': bookId,
        });
        await _localDb.deleteData('books', bookId); // Delete from local database for immediate local reflection
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('delete', {
        'table': 'books',
        'schoolId': schoolId,
        'id': bookId,
      });
      await _localDb.deleteData('books', bookId); // Delete from local database for immediate local reflection
    }
  }

  Future<void> borrowBook(
      String schoolId, Map<String, dynamic> borrowingData) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post('/api/schools/$schoolId/library/borrow',
            body: borrowingData);
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'book_borrowings',
          'schoolId': schoolId,
          ...borrowingData,
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'book_borrowings',
        'schoolId': schoolId,
        ...borrowingData,
      });
    }
  }

  Future<void> returnBook(String schoolId, String borrowingId) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient
            .put('/api/schools/$schoolId/library/return/$borrowingId');
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('update', {
          'table': 'book_borrowings',
          'schoolId': schoolId,
          'borrowingId': borrowingId,
          'action': 'return',
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('update', {
        'table': 'book_borrowings',
        'schoolId': schoolId,
        'borrowingId': borrowingId,
        'action': 'return',
      });
    }
  }

  Future<List<Book>> getBorrowedBooks(String schoolId, String studentId) async {
    final cacheKey = 'borrowed_books_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient
            .get('/api/students/$studentId/library/borrowed-books');
        final List<dynamic> bookList =
            response['borrowed_books'] as List<dynamic>;
        return bookList
            .map((json) => Book.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      offlineFallback: () async {
        // 1. Try to get cached borrowed books (list)
        final cachedJson = await _localDb.getCache(cacheKey);
        if (cachedJson != null) {
          final List<dynamic> data = jsonDecode(cachedJson);
          return data
              .map((json) => Book.fromMap(json as Map<String, dynamic>))
              .toList();
        }

        // 2. If no cached list, try to get all individual books from booksTable
        // Note: A more precise implementation would involve a dedicated 'borrowed_books' table
        // or enriching the 'books' table with borrower information.
        // For now, returning all local books as a fallback, assuming filtering
        // might happen upstream or this is a placeholder.
        final allLocalBooks = await _localDb.getAllData('books');
        return allLocalBooks
            .map((json) => Book.fromMap(json as Map<String, dynamic>))
            .toList();
      },
      cacheKey: cacheKey,
    );
  }
}
