import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. REGISTER USER
  static Future<Map<String, dynamic>> registerUser({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan Nama ke DisplayName Firebase
      await userCredential.user?.updateDisplayName(nama);

      return {
        'status': 'success',
        'message': 'Registrasi berhasil',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan registrasi';
      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah (minimal 6 karakter)';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      }
      return {'status': 'error', 'message': message};
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung: $e'};
    }
  }

  // 2. LOGIN USER
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {
        'status': 'success',
        'message': 'Login berhasil',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal login';
      if (e.code == 'user-not-found') {
        message = 'Email belum terdaftar';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah';
      } else if (e.code == 'invalid-credential') {
        message = 'Email atau password salah';
      }
      return {'status': 'error', 'message': message};
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung: $e'};
    }
  }

  // 3. LOGOUT USER
  static Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // 4. UPDATE PROFIL USER
  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    String? photoUrl,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(nama);
        if (photoUrl != null && photoUrl.isNotEmpty) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload(); // Refresh data user terbaru
        return {'status': 'success', 'message': 'Profil berhasil diperbarui'};
      }
      return {'status': 'error', 'message': 'User tidak ditemukan'};
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal perbarui profil: $e'};
    }
  }

  // 5. AMBIL USER AKTIF
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}