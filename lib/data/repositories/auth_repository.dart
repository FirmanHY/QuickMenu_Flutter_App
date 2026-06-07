import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/errors/app_exception.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;


  bool _isRegistering = false;

  AuthRepository({FirebaseAuth? auth, FirebaseDatabase? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges().where(
        (_) => !_isRegistering,
      );

  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        throw const AuthException('Email belum diverifikasi. Cek inbox kamu.');
      }

      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<void> registerWithEmail(
      String email, String password, String name) async {

    _isRegistering = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user!.updateDisplayName(name);

      await _db.ref('users/${cred.user!.uid}').set({
        'uid': cred.user!.uid,
        'fullName': name,
        'email': email,
        'createdAt': ServerValue.timestamp,
      });

      await cred.user!.sendEmailVerification();

  
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } finally {
    
      _isRegistering = false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found'         => 'Email tidak terdaftar.',
        'wrong-password'         => 'Password salah.',
        'invalid-email'          => 'Format email tidak valid.',
        'user-disabled'          => 'Akun ini dinonaktifkan.',
        'email-already-in-use'   => 'Email sudah digunakan.',
        'weak-password'          => 'Password terlalu lemah, minimal 6 karakter.',
        'too-many-requests'      => 'Terlalu banyak percobaan. Coba lagi nanti.',
        'network-request-failed' => 'Tidak ada koneksi internet.',
        _                        => 'Terjadi kesalahan. Silakan coba lagi.',
      };
}