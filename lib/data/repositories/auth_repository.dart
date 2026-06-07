import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/errors/app_exception.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  AuthRepository({FirebaseAuth? auth, FirebaseDatabase? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Blokir kalau email belum diverifikasi
      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        throw const AuthException('Email belum diverifikasi. Cek inbox kamu.');
      }

      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<User> registerWithEmail(
      String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await cred.user!.updateDisplayName(name);

      // Simpan user profile ke Realtime Database
    
      await _db.ref('users/${cred.user!.uid}').set({
        'uid': cred.user!.uid,
        'fullName': name,
        'email': email,
        'createdAt': ServerValue.timestamp,
      });

      // Kirim verifikasi email lalu langsung sign out
      await cred.user!.sendEmailVerification();
      await _auth.signOut();

      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Map Firebase error code → pesan Indonesia
  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found'       => 'Email tidak terdaftar.',
        'wrong-password'       => 'Password salah.',
        'invalid-email'        => 'Format email tidak valid.',
        'user-disabled'        => 'Akun ini dinonaktifkan.',
        'email-already-in-use' => 'Email sudah digunakan.',
        'weak-password'        => 'Password terlalu lemah, minimal 6 karakter.',
        'too-many-requests'    => 'Terlalu banyak percobaan. Coba lagi nanti.',
        'network-request-failed' => 'Tidak ada koneksi internet.',
        _                      => 'Terjadi kesalahan. Silakan coba lagi.',
      };
}