import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/errors/app_exception.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  AuthRepository({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Login gagal');
    }
  }

  Future<User> registerWithEmail(
      String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user!.updateDisplayName(name);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registrasi gagal');
    }
  }

  Future<User> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) throw const AuthException('Login Google dibatalkan');
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken);
      final result = await _auth.signInWithCredential(cred);
      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Login Google gagal');
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _google.signOut()]);
  }
}