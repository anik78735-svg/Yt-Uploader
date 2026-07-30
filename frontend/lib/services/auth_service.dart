import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  // Har login/signup ke baad users collection me record rakho (admin stats ke liye)
  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? 'Guest',
        'email': user.email ?? '',
        'isAnonymous': user.isAnonymous,
        'premiumUntil': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'name': user.displayName ?? 'Guest',
        'email': user.email ?? '',
      });
    }
  }

  // Google Sign-In Flow
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _ensureUserDoc(userCredential.user!);
      }
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  // Skip / Guest Login Flow
  Future<User?> signInAsGuest() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) {
        await _ensureUserDoc(userCredential.user!);
      }
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  // Log Out Flow
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
