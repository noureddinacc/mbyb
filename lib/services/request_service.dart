import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a book request
  Future<void> sendRequest({
    required String bookId,
    required String bookTitle,
    required String requesterId,
    required String requesterStudentId,
    required String publisherId,
    required String postType,
    String? message,
  }) async {
    try {
      final now = DateTime.now();

      final requestData = {
        'bookId': bookId,
        'bookTitle': bookTitle,
        'requesterId': requesterId,
        'requesterStudentId': requesterStudentId,
        'publisherId': publisherId,
        'timestamp': now,
        'message': message,
        'status': 'pending',
        'postType': postType,
      };

      await _firestore.collection('requests').add(requestData);
    } catch (e) {
      rethrow;
    }
  }

  /// Get pending requests for my books (I am the publisher)
  Stream<List<RequestModel>> getIncomingRequests(String publisherId) {
    return _firestore
        .collection('requests')
        .where('publisherId', isEqualTo: publisherId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get pending requests I sent
  Stream<List<RequestModel>> getOutgoingRequests(String requesterId) {
    return _firestore
        .collection('requests')
        .where('requesterId', isEqualTo: requesterId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Accept a request
  Future<String> acceptRequest(
    RequestModel request,
    String publisherId,
    String publisherStudentId,
  ) async {
    try {
      // 1. Update request status
      await _firestore.collection('requests').doc(request.id).update({
        'status': 'accepted',
      });

      // 2. Mark book as taken
      await _firestore.collection('books').doc(request.bookId).update({
        'status': 'Accepted',
      });

      // 3. Reject all other requests for this book
      final otherRequests = await _firestore
          .collection('requests')
          .where('bookId', isEqualTo: request.bookId)
          .where('publisherId', isEqualTo: publisherId) // Critical: Prove to rules we own these
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (var doc in otherRequests.docs) {
        batch.update(doc.reference, {'status': 'rejected'});
      }
      await batch.commit();

      // 4. Create a chat — store student IDs and book info so UI can show them without lookups
      final chatRef = await _firestore.collection('chats').add({
        'participantIds': [publisherId, request.requesterId],
        'participantStudentIds': {
          publisherId: publisherStudentId,
          request.requesterId: request.requesterStudentId,
        },
        'bookId': request.bookId,
        'bookTitle': request.bookTitle,
        'postType': request.postType,
        'updatedAt': DateTime.now(),
        'lastMessage': 'Request Accepted! Say Hi.',
        'isClosed': false,
      });

      return chatRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Reject a request directly without accepting
  Future<void> rejectRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream the current user's pending request for a specific book (null if none)
  Stream<RequestModel?> getMyRequestForBook(String bookId, String userId) {
    return _firestore
        .collection('requests')
        .where('bookId', isEqualTo: bookId)
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return RequestModel.fromMap(doc.data(), doc.id);
        });
  }

  /// Cancel (delete) a pending request made by the current user
  Future<void> cancelRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
