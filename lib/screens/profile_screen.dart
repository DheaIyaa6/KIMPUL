import 'package:flutter/material.dart';

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
    this.avatarUrl = 'https://i.pravatar.cc/300',
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
  bool _showSessionInfo = false;
  bool _showPrivacyInfo = false;

  // User yang sedang ditampilkan
  late UserProfile _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  // Dialog internal untuk edit profil cepat
  void _openEditProfileModal() {
    final nameController = TextEditingController(text: _currentUser.name);
    final emailController = TextEditingController(text: _currentUser.email);
    final phoneController = TextEditingController(text: _currentUser.phone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              _buildModalTextField('NAMA LENGKAP', nameController),
              const SizedBox(height: 12),
              _buildModalTextField('EMAIL', emailController),
              const SizedBox(height: 12),
              _buildModalTextField('NOMOR TELEPON', phoneController),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentUser = UserProfile(
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        avatarUrl: _currentUser.avatarUrl,
                        clientCode: _currentUser.clientCode,
                        accountNumber: _currentUser.accountNumber,
                        branch: _currentUser.branch,
                      );
                    });
                    Navigator.pop(context);
                    widget.onShowToast('Profil berhasil diperbarui');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: NetworkImage(_currentUser.avatarUrl),
                      onBackgroundImageError: (_, __) {},
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _openEditProfileModal,
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
                      onTap: _openEditProfileModal,
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
                Text(
                  _currentUser.phone,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GROUP 1: AKUN & PENGATURAN
          const Text(
            'AKUN & PENGATURAN',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outlined,
                  title: 'Edit Profil',
                  subtitle: 'Ubah nama, nomor telepon, atau kontak',
                  onTap: _openEditProfileModal,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.lock_reset_rounded,
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Perbarui keamanan kata sandi akun',
                  onTap: () => widget.onShowToast('Fitur Ubah Sandi Aktif'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GROUP 2: KEAMANAN & SESI
          const Text(
            'KEAMANAN & SESI',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Keamanan Akun',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Terkonfigurasi • Enkripsi AES-256',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: Color(0xFF059669),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showSessionInfo = !_showSessionInfo;
                    });
                  },
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                            Icons.devices_rounded,
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
                                'Aktivitas Sesi',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '1 Sesi Aktif • Mobile Application',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showSessionInfo
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
          if (_showSessionInfo) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sesi Saat Ini',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Aktif Sekarang',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Perangkat: Mobile App • Flutter Android/iOS',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Penyimpanan: Secure Storage Terenkripsi',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // GROUP 3: KEBIJAKAN & PRIVASI
          const Text(
            'KEBIJAKAN & PRIVASI',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _showPrivacyInfo = !_showPrivacyInfo;
                });
              },
              borderRadius: BorderRadius.circular(16),
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
          ),
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
              child: const Text(
                'Aplikasi melindungi seluruh data kalkulasi pengguna. Seluruh riwayat dan parameter perhitungan disimpan secara privat pada perangkat Anda.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // GROUP 4: ACTION BUTTONS
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