import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a report (for a book or a user)
  Future<void> submitReport({
    required String reporterId,
    required String targetId,
    required String targetType, // 'book' or 'user'
    required String reason,
    required String universityId,
    String? targetTitle, // Optional: e.g. book title
    String? chatId, // Optional: for chat reports to provide context for verification
  }) async {
    try {
      final now = DateTime.now();

      final reportData = {
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'universityId': universityId,
        'targetTitle': targetTitle,
        'chatId': chatId,
        'timestamp': now,
        'status': 'pending',
      };

      await _firestore.collection('reports').add(reportData);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all reports (for admins)
  Stream<List<Map<String, dynamic>>> getAllReports() {
    return _firestore
        .collection('reports')
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

  /// Delete a report (for admins)
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Count how many reports exist for a specific target ID
  Stream<int> getReportCount(String targetId) {
    return _firestore
        .collection('reports')
        .where('targetId', isEqualTo: targetId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get reports filtered by university ID
  Stream<List<Map<String, dynamic>>> getReportsByUniversity(String universityId) {
    return _firestore
        .collection('reports')
        .where('universityId', isEqualTo: universityId)
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
}
