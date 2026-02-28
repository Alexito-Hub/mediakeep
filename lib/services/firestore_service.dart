import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of the current user's document
  static Stream<DocumentSnapshot<Map<String, dynamic>>?> getUserDataStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).snapshots();
  }

  // Get current session token for API requests
  static Future<String?> getAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // Example: Check if a user can download based on local snapshot
  static Future<bool> canDownload() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Logic for unauthenticated users is fully enforced on the backend via fingerprint.
      // But we could keep a local counter for UX purposes.
      return true; // The backend will reject if limits are passed anyway
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return true; // Account just created, will be initialized by backend
      }

      final data = doc.data()!;
      final requestsCount = data['requestsCount'] as int? ?? 0;
      final totalLimit = data['totalLimit'] as int? ?? 10;
      final plan = data['plan'] as String? ?? 'free';

      if (plan == 'free' && requestsCount >= totalLimit) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking download limits locally: $e');
      return true; // Let the backend decide on error
    }
  }

  // Initialize a user profile in Firestore after registration
  static Future<void> initializeUser(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'requestsCount': 0,
        'totalLimit': 10,
        'plan': 'free',
      });
    }
  }
}
