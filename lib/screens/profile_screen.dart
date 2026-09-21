import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kimpul/screens/modals_screen.dart';
import 'package:kimpul/screens/edit_profile_screen.dart';
import 'package:kimpul/screens/change_password_screen.dart';

// Model User Profile untuk Flutter
class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String clientCode;
  final String accountNumber;
  final String branch;

  UserProfile({
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl = '', // Berisi nama file foto dari DB MySQL (misal: "profile_1_1726000000.jpg")
    this.clientCode = 'KMP-8892',
    this.accountNumber = '9928102831',
    this.branch = 'Surabaya, Indonesia',
  });
}

class ProfileScreen extends StatefulWidget {
  final UserProfile user;
  final Future<void> Function(UserProfile updatedUser)? onSaveProfile;
  final Future<void> Function(String oldPassword, String newPassword)?
      onChangePassword;
  final VoidCallback onRequestLogout;
  final Function(String msg) onShowToast;
  final VoidCallback? onReplaySplash;

  const ProfileScreen({
    super.key,
    required this.user,
    this.onSaveProfile,
    this.onChangePassword,
    required this.onRequestLogout,
    required this.onShowToast,
    this.onReplaySplash,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showPrivacyInfo = false;

  // User yang sedang ditampilkan
  late UserProfile _currentUser;

  // Base URL server Laragon
  static const String _serverBaseUrl = "http://192.168.1.207/api_flutter/uploads";

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  // Navigasi ke Halaman Edit Profil
  void _navigateToEditProfile() async {
    final updatedUser = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
      if (widget.onSaveProfile != null) {
        widget.onSaveProfile!(updatedUser);
      }
      widget.onShowToast('Profil berhasil diperbarui');
    }
  }

  // Navigasi ke Halaman Ubah Kata Sandi
  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  // 🌟 HELPER FOTO: Menentukan ImageProvider yang tepat (Server Laragon vs File HP vs Null/Icon)
  ImageProvider? _getAvatarProvider(String path) {
    final cleanPath = path.trim();

    // 1. Jika path kosong, null, atau URL dummy internet, kembalikan null (akan tampil ikon person)
    if (cleanPath.isEmpty || cleanPath == 'null' || cleanPath.contains('pravatar.cc')) {
      return null;
    }

    // 2. Jika berupa path file lokal dari galeri/kamera HP pengguna
    if (cleanPath.startsWith('/') || cleanPath.startsWith('file://') || cleanPath.contains(':\\')) {
      final file = File(cleanPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    // 3. Jika berupa URL HTTP/HTTPS lengkap dari internet/server
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return NetworkImage('$cleanPath?v=${DateTime.now().millisecondsSinceEpoch}');
    }

    // 4. Jika hanya berupa nama file dari DB MySQL (misal: "profile_1_1726000000.jpg")
    // Ambil file foto langsung dari folder uploads Laragon
    final serverImageUrl = '$_serverBaseUrl/$cleanPath?v=${DateTime.now().millisecondsSinceEpoch}';
    return NetworkImage(serverImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final avatarImageProvider = _getAvatarProvider(_currentUser.avatarUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil Pengguna',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // USER PROFILE CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    // CIRCLE AVATAR (Mendukung Foto Server Laragon, File HP, & Ikon Bawaan)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: avatarImageProvider,
                      onBackgroundImageError: avatarImageProvider != null
                          ? (exception, stackTrace) {}
                          : null,
                      child: avatarImageProvider == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: Color(0xFF94A3B8),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _navigateToEditProfile,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentUser.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _navigateToEditProfile,
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUser.email,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // UNIFIED MENU CONTAINER
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // 1. Edit Profil
                _buildMenuItem(
                  icon: Icons.person_outlined,
                  title: 'Edit Profil',
                  subtitle: 'Ubah nama atau kontak profil',
                  onTap: _navigateToEditProfile,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // 2. Ubah Kata Sandi
                _buildMenuItem(
                  icon: Icons.lock_reset_rounded,
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Perbarui keamanan kata sandi akun',
                  onTap: _navigateToChangePassword,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // 3. Layanan Pelanggan (CS)
                _buildMenuItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Layanan Pelanggan (CS)',
                  subtitle: 'Hubungi tim bantuan via WhatsApp',
                  onTap: () {
                    ConsultationModal.show(context);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // 4. Privasi Data Perhitungan
                InkWell(
                  onTap: () {
                    setState(() {
                      _showPrivacyInfo = !_showPrivacyInfo;
                    });
                  },
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.privacy_tip_outlined,
                            size: 20,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Privasi Data Perhitungan',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Data perhitungan Anda disimpan privat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showPrivacyInfo
                              ? Icons.expand_less_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dropdown Info Privasi Data Perhitungan saat Panah Ditekan
          if (_showPrivacyInfo) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 18,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seluruh data kalkulasi, riwayat transaksi, dan parameter perhitungan Anda tersimpan secara privat & aman hanya pada penyimpanan lokal perangkat Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // BUTTON KELUAR AKUN
          if (widget.onReplaySplash != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onReplaySplash,
                icon: const Icon(Icons.play_circle_outline_rounded,
                    size: 18, color: Color(0xFF64748B)),
                label: const Text('Putar Ulang Animasi Pembuka'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onRequestLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Keluar Akun'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F2),
                foregroundColor: const Color(0xFFBE123C),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFFECDD3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}