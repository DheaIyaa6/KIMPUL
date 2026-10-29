import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Halaman Ubah Kata Sandi — terpisah dari ProfileScreen.
///
/// Halaman ini mengubah kata sandi langsung di Firebase Authentication:
/// 1) verifikasi ulang dengan kata sandi lama, 2) pasang kata sandi baru.
///
/// [onSubmit] bersifat opsional, hanya dipanggil SETELAH kata sandi di
/// Firebase berhasil diubah (misalnya untuk mencatat log atau menampilkan
/// pesan tambahan). Tidak perlu diisi.
///
/// Cara pakai:
///
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
/// );
class ChangePasswordScreen extends StatefulWidget {
  final Future<void> Function(String oldPassword, String newPassword)?
      onSubmit;

  const ChangePasswordScreen({
    super.key,
    this.onSubmit,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi lama tidak boleh kosong';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi baru tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Minimal 8 karakter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Harus mengandung 1 huruf besar';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Harus mengandung 1 angka';
    }
    if (value == _oldPasswordController.text) {
      return 'Kata sandi baru tidak boleh sama dengan yang lama';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi tidak boleh kosong';
    }
    if (value != _newPasswordController.text) {
      return 'Konfirmasi tidak cocok dengan kata sandi baru';
    }
    return null;
  }

  // Ubah kata sandi di Firebase Authentication.
  // Firebase mewajibkan verifikasi ulang (re-authenticate) sebelum
  // kata sandi boleh diganti.
  Future<void> _changePasswordInFirebase(
      String oldPassword, String newPassword) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;

    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Sesi login tidak ditemukan.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: oldPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // Pesan error yang mudah dipahami
  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Kata sandi lama salah.';
      case 'weak-password':
        return 'Kata sandi baru terlalu lemah. Gunakan yang lebih kuat.';
      case 'requires-recent-login':
        return 'Demi keamanan, keluar dari akun lalu masuk lagi, kemudian coba ubah kata sandi kembali.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
      case 'no-current-user':
      case 'user-not-found':
      case 'user-mismatch':
        return 'Sesi login tidak ditemukan. Silakan masuk ulang.';
      default:
        return 'Gagal mengubah kata sandi (${e.code}).';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBE123C),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final String oldPassword = _oldPasswordController.text;
    final String newPassword = _newPasswordController.text;

    setState(() => _isSubmitting = true);
    try {
      // 1. Ubah di Firebase Authentication (ini yang membuat login
      //    berikutnya memakai kata sandi baru)
      await _changePasswordInFirebase(oldPassword, newPassword);

      // 2. Callback opsional dari pemanggil
      if (widget.onSubmit != null) {
        await widget.onSubmit!(oldPassword, newPassword);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi berhasil diubah')),
      );
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      debugPrint('UBAH SANDI gagal: ${e.code} ${e.message}');
      _showError(_friendlyError(e));
    } catch (e) {
      debugPrint('UBAH SANDI gagal: $e');
      _showError('Gagal mengubah kata sandi: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF059669)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gunakan kombinasi huruf besar, huruf kecil, dan angka minimal 8 karakter.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Kata Sandi Lama'),
              _buildPasswordField(
                controller: _oldPasswordController,
                hint: 'Masukkan kata sandi lama',
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
                validator: _validateOldPassword,
              ),
              const SizedBox(height: 16),
              _buildLabel('Kata Sandi Baru'),
              _buildPasswordField(
                controller: _newPasswordController,
                hint: 'Masukkan kata sandi baru',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 16),
              _buildLabel('Konfirmasi Kata Sandi Baru'),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Ulangi kata sandi baru',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Perbarui Kata Sandi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 20, color: Color(0xFF64748B)),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: const Color(0xFF94A3B8),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBE123C)),
        ),
      ),
    );
  }
}