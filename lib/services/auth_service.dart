import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Check if email is verified
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String universityId,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Derive student ID from email (part before @)
      final studentId = email.split('@').first;

      // Save user profile to Firestore so lookups by UID work
      await _firestore
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'studentID': studentId,
        'universityId': universityId,
        'createdAt': DateTime.now(),
      });

      // Send verification email
      await sendVerificationEmail();

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Send verification email to current user
  Future<void> sendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Log in with email and password
  Future<UserCredential> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user profile exists in Firestore (covers accounts created before this fix)
      final studentId = email.split('@').first;
      await _firestore
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'studentID': studentId,
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Refresh user to get latest verification status
  Future<void> refreshUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Resolve a UID to its associate student ID
  Future<String?> getStudentIdFromUid(String uid) async {
    try {
      final doc = await _firestore.collection('Users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['studentID'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if a user is blocked (Stream)
  Stream<bool> isUserBlocked(String uid) {
    return _firestore
        .collection('Users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['isBlocked'] == true);
  }

  /// Block a user permanently
  Future<void> blockUser(String uid) async {
    try {
      await _firestore.collection('Users').doc(uid).set({
        'isBlocked': true,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String uid) async {
    try {
      await _firestore.collection('Users').doc(uid).set({
        'isBlocked': false,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Get all blocked users
  Stream<List<Map<String, dynamic>>> getBlockedUsers() {
    return _firestore
        .collection('Users')
        .where('isBlocked', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Get user profile data (Stream)
  Stream<Map<String, dynamic>?> getUserProfile(String uid) {
    return _firestore
        .collection('Users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Log out
  Future<void> logOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException {
      rethrow;
    }
  }
}
