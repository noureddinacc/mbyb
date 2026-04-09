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

  /// Count unread messages for a user
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('system_messages')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send a message to ALL users (Broadcast)
  Future<void> broadcastMessage({
    required String message,
  }) async {
    try {
      final now = DateTime.now();
      
      // 1. Fetch all user UIDs
      // Limit to ensure we don't accidentally fetch millions in a small app, 
      // but here we expect the user base to be manageble.
      final usersSnapshot = await _firestore.collection('Users').get();
      final adminEmail = 'solosoulacc@tutamail.com';

      // 2. Prepare batches
      // Firestore batches are limited to 500 operations.
      var batch = _firestore.batch();
      int operationCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userEmail = userData['email'] as String?;
        
        // Skip the admin themselves
        if (userEmail == adminEmail) continue;

        final msgRef = _firestore.collection('system_messages').doc();
        batch.set(msgRef, {
          'recipientId': userDoc.id,
          'message': message,
          'senderName': 'الإدارة (تعميم)', // Admin (Broadcast)
          'timestamp': now,
          'isRead': false,
        });

        operationCount++;

        // If we reach 500 operations, commit and start a new batch
        if (operationCount == 500) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // Commit the final batch
      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      rethrow;
    }
  }
}
