import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload a new book
  Future<String> uploadBook({
    required String publisherId,
    required String title,
    required String author,
    required String faculty,
    required String description,
    required String condition,
    required bool isExchange,
    String? exchangeDetails,
  }) async {
    try {
      final now = DateTime.now();
      final bookData = {
        'publisherId': publisherId,
        'title': title,
        'author': author,
        'faculty': faculty,
        'description': description,
        'condition': condition,
        'isExchange': isExchange,
        'exchangeDetails': exchangeDetails,
        'status': 'Available',
        'createdAt': now,
      };

      final docRef = await _firestore.collection('books').add(bookData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all available books (stream for real-time updates)
  Stream<List<BookModel>> getAvailableBooks() {
    return _firestore
        .collection('books')
        .where('status', isEqualTo: 'Available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get available books filtered by faculty
  Stream<List<BookModel>> getAvailableBooksByFaculty(String faculty) {
    return _firestore
        .collection('books')
        .where('status', isEqualTo: 'Available')
        .where('faculty', isEqualTo: faculty)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get books by publisher ID
  Stream<List<BookModel>> getBooksByPublisher(String publisherId) {
    return _firestore
        .collection('books')
        .where('publisherId', isEqualTo: publisherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Delete a book by id
  Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single book by ID
  Future<BookModel?> getBookById(String bookId) async {
    try {
      final doc = await _firestore.collection('books').doc(bookId).get();
      if (doc.exists && doc.data() != null) {
        return BookModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Hide all books belonging to a specific user (used when blocking)
  Future<void> hideBooksByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection('books')
          .where('publisherId', isEqualTo: userId)
          .where('status', isEqualTo: 'Available')
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'status': 'Hidden'});
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Restore all books belonging to a specific user (used when unblocking)
  Future<void> unhideBooksByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection('books')
          .where('publisherId', isEqualTo: userId)
          .where('status', isEqualTo: 'Hidden')
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'status': 'Available'});
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
