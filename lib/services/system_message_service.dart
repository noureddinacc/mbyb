import 'package:cloud_firestore/cloud_firestore.dart';

class SystemMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a one-way message from Admin to a user
  Future<void> sendAdminMessage({
    required String recipientId,
    required String message,
  }) async {
    try {
      final now = DateTime.now();
      final messageData = {
        'recipientId': recipientId,
        'message': message,
        'senderName': 'Admin',
        'timestamp': now,
        'isRead': false,
      };

      await _firestore.collection('system_messages').add(messageData);
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages for a specific user
  Stream<List<Map<String, dynamic>>> getUserMessages(String userId) {
    return _firestore
        .collection('system_messages')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Mark a message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore.collection('system_messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      // Non-critical
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('system_messages').doc(messageId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Restore a deleted message (Undo)
  Future<void> restoreMessage(Map<String, dynamic> messageData) async {
    try {
      final id = messageData['id'];
      final data = Map<String, dynamic>.from(messageData);
      data.remove('id');
      await _firestore.collection('system_messages').doc(id).set(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Count unread messages for a user
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('system_messages')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send a message to users — scoped to a university, or all users for master admin
  Future<void> broadcastMessage({
    required String message,
    String? universityId, // null = master admin, sends to all
  }) async {
    try {
      final now = DateTime.now();
      const masterAdminEmail = 'solosoulacc@tutamail.com';

      Query<Map<String, dynamic>> query = _firestore.collection('Users');

      // If a universityId is provided, restrict to that university's students only
      if (universityId != null && universityId.isNotEmpty) {
        query = query.where('universityId', isEqualTo: universityId);
      }

      final usersSnapshot = await query.get();

      var batch = _firestore.batch();
      int operationCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userEmail = userData['email'] as String?;

        // Never send to the master admin account
        if (userEmail == masterAdminEmail) continue;

        final msgRef = _firestore.collection('system_messages').doc();
        batch.set(msgRef, {
          'recipientId': userDoc.id,
          'message': message,
          'senderName': 'الإدارة (تعميم)',
          'timestamp': now,
          'isRead': false,
        });

        operationCount++;

        if (operationCount == 500) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      rethrow;
    }
  }
}
