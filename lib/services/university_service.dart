import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/university.dart';

class UniversityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all supported universities
  Future<List<University>> getUniversities() async {
    final snapshot = await _firestore.collection('Universities').get();
    return snapshot.docs
        .map((doc) => University.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Get a specific university by its ID
  Future<University?> getUniversityById(String id) async {
    final doc = await _firestore.collection('Universities').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return University.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
  /// Stream of all supported universities
  Stream<List<University>> getUniversitiesStream() {
    return _firestore.collection('Universities').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => University.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
