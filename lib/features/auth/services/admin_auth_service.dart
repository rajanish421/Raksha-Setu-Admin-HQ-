import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  AdminAuthService._internal();

  static final AdminAuthService instance = AdminAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  /// LOGIN LOGIC WITH MUST_RESET DETECTION
  Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('No user profile found.');
      }

      final data = doc.data()!;
      final role = data['role'] ?? '';
      final status = data['status'] ?? 'pending';
      final mustReset = data['mustResetPassword'] ?? false;

      if (status != 'approved') {
        await _auth.signOut();
        throw Exception('Account not approved. Current status: $status');
      }

      if (role != 'admin' && role != 'superAdmin') {
        await _auth.signOut();
        throw Exception('Access Denied — Only HQ Admins allowed.');
      }

      /// 🔥 RETURN STATUS FOR UI
      return {
        "uid": uid,
        "mustReset": mustReset,
        "role": role,
      };

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') throw Exception("Invalid password");
      if (e.code == 'user-not-found') throw Exception("Account not found");
      throw Exception("Login failed: ${e.message}");
    }
  }

  Future<void> logout() async => _auth.signOut();

  Future<bool> isLoggedInAsAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    return (data['status'] == 'approved' &&
        (data['role'] == 'admin' || data['role'] == 'superAdmin'));
  }
}
