import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'firestore_service.dart';

// A simple wrapper around FirebaseAuth + Google Sign-In. All logic that
// previously lived inside AuthScreen has been factored here so the UI can be
// a thin layer and the API used from other places in the app if necessary.
class AuthService {
  AuthService._(); // no instances

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Exposes the current Firebase user as a stream. Useful to rebuild parts of
  /// the UI when authentication state changes instead of manually handling
  /// subscriptions on widgets.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The GoogleSignIn object used for web/mobile. The clientId is only supplied
  /// on web, mobile platforms read it from the Firebase configuration files.
  static GoogleSignIn get googleSignIn {
    return GoogleSignIn(
      scopes: const ['email'],
      clientId: kIsWeb
          ? '354908157298-50aud2k7amfugeqhqu2hdpstb9jf4psi.apps.googleusercontent.com'
          : null,
    );
  }

  /// Sign in with email & password.
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // post‑login initialization is harmless even if user already exists
    await _maybeInitUser(credential.user);
    return credential;
  }

  /// Create a new user with email & password.
  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _maybeInitUser(credential.user);
    return credential;
  }

  /// Send a password reset email to the provided address.
  static Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Ensure there is a corresponding Firestore document for the user.
  static Future<void> _maybeInitUser(User? user) async {
    if (user != null) {
      await FirestoreService.initializeUser(user);
    }
  }

  /// Perform Google sign‑in flow and return the resulting credential. May
  /// return null if the user cancels the dialog.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // user aborted the flow

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _maybeInitUser(userCredential.user);
      return userCredential;
    } catch (e, stack) {
      // Developer error usually means misconfigured SHA‑1/package or client ID
      debugPrint('Google sign-in failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }
}
