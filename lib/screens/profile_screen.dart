import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kimpul/screens/modals_screen.dart';
import 'package:kimpul/screens/edit_profile_screen.dart';
import 'package:kimpul/screens/change_password_screen.dart';

class ProfileStorage {
  static const String _keyName = 'profile_name';
  static const String _keyEmail = 'profile_email';

  // Kunci foto lokal dikaitkan dengan email user
  static String _getAvatarKey(String email) {
    final cleanEmail = email.trim().toLowerCase();
    return 'profile_avatar_path_$cleanEmail';
  }

  // Simpan foto ke Firestore (base64), terikat ke akun (uid).
  // Mengembalikan 'b64:<data>' kalau berhasil, null kalau gagal.
  static Future<String?> savePhotoToCloud(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final bytes = await imageFile.readAsBytes();
      // 500 KB -> base64 sekitar 680 ribu karakter (< batas rules 800 ribu)
      if (bytes.length > 500 * 1024) return null;

      final b64 = base64Encode(bytes);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoBase64': b64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 20));

      return 'b64:$b64';
    } catch (e) {
      debugPrint('Gagal simpan foto ke Firestore: $e');
      return null;
    }
  }

  // Hapus foto dari Firestore (dan salinan lokalnya). true kalau berhasil.
  static Future<bool> deletePhotoFromCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoBase64': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 20));

      final email = user.email ?? '';
      if (email.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_getAvatarKey(email));
      }
      return true;
    } catch (e) {
      debugPrint('Gagal hapus foto dari Firestore: $e');
      return false;
    }
  }

  // Simpan nama ke Firestore supaya ikut sinkron ke semua HP.
  static Future<void> saveNameToCloud(String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Gagal simpan nama ke Firestore: $e');
    }
  }

  // Ambil foto dari Firestore (sekali baca). Kosong kalau belum ada / gagal.
  static Future<String> loadPhotoFromCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '';
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final b64 = snap.data()?['photoBase64'] as String?;
      if (b64 == null || b64.isEmpty) return '';
      return 'b64:$b64';
    } catch (e) {
      debugPrint('Gagal ambil foto dari Firestore: $e');
      return '';
    }
  }

  static Future<void> saveLoginProfile({
    required String name,
    required String email,
    String? avatarPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name.trim());
    await prefs.setString(_keyEmail, email.trim());

    // Hanya simpan path lokal, jangan simpan teks base64
    if (avatarPath != null &&
        avatarPath.trim().isNotEmpty &&
        !avatarPath.startsWith('b64:')) {
      await prefs.setString(_getAvatarKey(email), avatarPath.trim());
    }
  }

  static Future<UserProfile> loadSavedProfile({
    String fallbackName = 'Pengguna',
    String fallbackEmail = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    final String savedEmail =
        firebaseUser?.email ?? prefs.getString(_keyEmail) ?? fallbackEmail;
    final String savedName = firebaseUser?.displayName ??
        prefs.getString(_keyName) ??
        fallbackName;

    // Prioritas: cloud (ikut ke semua HP) -> lokal -> photoURL berupa http
    String savedAvatar = await loadPhotoFromCloud();

    if (savedAvatar.isEmpty) {
      savedAvatar = prefs.getString(_getAvatarKey(savedEmail)) ?? '';
    }

    if (savedAvatar.isEmpty) {
      final photoUrl = firebaseUser?.photoURL ?? '';
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        savedAvatar = photoUrl;
      }
    }

    return UserProfile(
      name: savedName,
      email: savedEmail,
      avatarUrl: savedAvatar,
    );
  }

  static Future<void> saveAvatarPath(String email, String? path) async {
    if (path == null || path.trim().isEmpty) return;
    if (path.startsWith('b64:')) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getAvatarKey(email), path.trim());
  }

  static Future<String> getSavedAvatarPath(String email) async {
    final cloud = await loadPhotoFromCloud();
    if (cloud.isNotEmpty) return cloud;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_getAvatarKey(email)) ?? '';
  }

  static Future<String?> persistPickedImage(File sourceFile,
      {String? email}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destination = await sourceFile.copy('${directory.path}/$fileName');

      final userEmail = email ?? FirebaseAuth.instance.currentUser?.email ?? '';
      if (userEmail.isNotEmpty) {
        await saveAvatarPath(userEmail, destination.path);
      }
      return destination.path;
    } catch (_) {
      return null;
    }
  }
}

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
    this.avatarUrl = '',
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
  // User yang sedang ditampilkan
  late UserProfile _currentUser;

  // Listener realtime ke Firestore
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _cloudSub;
  bool _gotCloudSnapshot = false;

  // True saat foto sedang diunggah / dihapus
  bool _savingPhoto = false;

  // Cache hasil decode base64 supaya tidak decode ulang tiap build()
  String? _cachedB64Key;
  ImageProvider? _cachedB64Provider;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadStoredAvatarOnStart();
    _listenCloudProfile();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cloudSub?.cancel();
    super.dispose();
  }

  // Salinan user dengan foto baru (bagian lain tetap sama)
  UserProfile _withAvatar(String avatarUrl) {
    return UserProfile(
      name: _currentUser.name,
      email: _currentUser.email,
      phone: _currentUser.phone,
      avatarUrl: avatarUrl,
      clientCode: _currentUser.clientCode,
      accountNumber: _currentUser.accountNumber,
      branch: _currentUser.branch,
    );
  }

  // Dengarkan perubahan profil di Firestore secara realtime.
  // Menunggu sampai user login siap (authStateChanges), lalu pasang listener.
  void _listenCloudProfile() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('PROFIL auth uid=${user?.uid} email=${user?.email}');

      _cloudSub?.cancel();
      _cloudSub = null;
      if (user == null) return;

      _cloudSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
        (snap) {
          final data = snap.data();
          final b64 = data?['photoBase64'] as String?;
          debugPrint('PROFIL snapshot exists=${snap.exists} '
              'fromCache=${snap.metadata.isFromCache} '
              'panjangFoto=${b64?.length}');

          if (data == null || !mounted) return;
          _gotCloudSnapshot = true;

          final cloudName = data['name'] as String?;
          final hasCloudPhoto = b64 != null && b64.isNotEmpty;
          final currentAvatar = _currentUser.avatarUrl;

          // Foto di cloud dihapus -> kosongkan juga di layar ini.
          // Path lokal (bukan b64) dibiarkan sebagai cadangan.
          final newAvatar = hasCloudPhoto
              ? 'b64:$b64'
              : (currentAvatar.startsWith('b64:') ? '' : currentAvatar);

          setState(() {
            _currentUser = UserProfile(
              name: (cloudName != null && cloudName.trim().isNotEmpty)
                  ? cloudName
                  : _currentUser.name,
              email: _currentUser.email,
              phone: _currentUser.phone,
              avatarUrl: newAvatar,
              clientCode: _currentUser.clientCode,
              accountNumber: _currentUser.accountNumber,
              branch: _currentUser.branch,
            );
          });
        },
        onError: (e) {
          debugPrint('PROFIL ERROR: $e');
          if (mounted) widget.onShowToast('Gagal sinkron profil: $e');
        },
      );
    });
  }

  // Muat foto tersimpan (fallback lokal) saat halaman dibuka.
  // Tidak menimpa data cloud kalau listener sudah menerima data.
  Future<void> _loadStoredAvatarOnStart() async {
    final savedProfile = await ProfileStorage.loadSavedProfile(
      fallbackName: widget.user.name,
      fallbackEmail: widget.user.email,
    );

    if (!mounted || _gotCloudSnapshot) return;

    if (savedProfile.avatarUrl.isNotEmpty) {
      setState(() {
        _currentUser = UserProfile(
          name: savedProfile.name,
          email: savedProfile.email,
          phone: _currentUser.phone,
          avatarUrl: savedProfile.avatarUrl,
          clientCode: _currentUser.clientCode,
          accountNumber: _currentUser.accountNumber,
          branch: _currentUser.branch,
        );
      });
    }
  }

  // ---------- Tambah / ganti / hapus foto profil ----------

  void _showPhotoSheet() {
    final hasPhoto = _getAvatarProvider(_currentUser.avatarUrl) != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF0F172A)),
                title: Text(
                    hasPhoto ? 'Ganti dari galeri' : 'Pilih dari galeri'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded,
                    color: Color(0xFF0F172A)),
                title: const Text('Ambil dengan kamera'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFBE123C)),
                  title: const Text(
                    'Hapus foto',
                    style: TextStyle(color: Color(0xFFBE123C)),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _removePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (_savingPhoto) return;
    try {
      // Dikecilkan dulu supaya muat di batas rules Firestore (< 500 KB)
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (picked == null) return;

      if (mounted) setState(() => _savingPhoto = true);

      final result = await ProfileStorage.savePhotoToCloud(File(picked.path));
      if (!mounted) return;

      if (result == null) {
        widget.onShowToast(
            'Gagal menyimpan foto. Cek koneksi atau coba foto lain.');
      } else {
        setState(() => _currentUser = _withAvatar(result));
        widget.onShowToast('Foto profil diperbarui');
      }
    } catch (e) {
      debugPrint('PROFIL pilih foto gagal: $e');
      if (mounted) widget.onShowToast('Gagal memilih foto: $e');
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_savingPhoto) return;
    setState(() => _savingPhoto = true);

    final ok = await ProfileStorage.deletePhotoFromCloud();
    if (!mounted) return;

    setState(() {
      _savingPhoto = false;
      if (ok) _currentUser = _withAvatar('');
    });
    widget.onShowToast(
        ok ? 'Foto profil dihapus' : 'Gagal menghapus foto. Coba lagi.');
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
      if (!mounted) return;
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

  // Popup About Me (Tentang KIMPUL), tanpa file baru
  void _showAboutDialog() {
    const boldDark =
        TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFE93A56),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Me',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Identitas Resmi Aplikasi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
                // LOGO KIMPUL (di atas teks penjelasan)
                const SizedBox(height: 14),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo_apk.jpeg',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 96,
                          height: 96,
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 32,
                            color: Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '1. Arti Nama KIMPUL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF334155),
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'KIMPUL ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: 'merupakan singkatan dari '),
                      TextSpan(text: 'K', style: boldDark),
                      TextSpan(text: 'alkulator '),
                      TextSpan(text: 'I', style: boldDark),
                      TextSpan(text: 'nformasi '),
                      TextSpan(text: 'M', style: boldDark),
                      TextSpan(text: 'arket untuk '),
                      TextSpan(text: 'P', style: boldDark),
                      TextSpan(text: 'erhitungan '),
                      TextSpan(text: 'U', style: boldDark),
                      TextSpan(text: 'ntung & '),
                      TextSpan(text: 'L', style: boldDark),
                      TextSpan(
                        text:
                            'oss, yaitu aplikasi yang dirancang untuk membantu pengguna melakukan berbagai perhitungan dalam aktivitas jual beli emas.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // FILOSOFI LOGO
                const Text(
                  '2. Filosofi Logo KIMPUL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Logo KIMPUL menggabungkan huruf K sebagai identitas merek, simbol kalkulator sebagai representasi fungsi perhitungan trading, serta lingkaran terbuka yang menggambarkan dinamika pasar dan fleksibilitas analisis. Perpaduan warna pink dan biru keabu-abuan mencerminkan inovasi, kepercayaan, dan profesionalisme. Secara keseluruhan, logo ini merepresentasikan KIMPUL sebagai aplikasi kalkulator trading yang membantu pengguna melakukan perhitungan secara praktis dan memahami hasilnya sebagai bahan pertimbangan sebelum mengambil keputusan.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // TRADEMARK / CREDIT PERUSAHAAN (kotak penuh, sudut melengkung)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/trademark_apk.jpeg',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 100,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 32,
                          color: Color(0xFF64748B),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '© PT Equityworld Futures',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  // Menentukan ImageProvider yang tepat
  ImageProvider? _getAvatarProvider(String path) {
    final cleanPath = path.trim();

    // 1. Kosong / null / URL dummy -> ikon person
    if (cleanPath.isEmpty ||
        cleanPath == 'null' ||
        cleanPath.contains('pravatar.cc')) {
      return null;
    }

    // 2. Foto dari cloud (Firestore, base64) -> pakai cache
    if (cleanPath.startsWith('b64:')) {
      if (_cachedB64Key == cleanPath && _cachedB64Provider != null) {
        return _cachedB64Provider;
      }
      try {
        final provider = MemoryImage(base64Decode(cleanPath.substring(4)));
        _cachedB64Key = cleanPath;
        _cachedB64Provider = provider;
        return provider;
      } catch (e) {
        debugPrint('PROFIL decode gagal: $e');
        return null;
      }
    }

    // 3. Path file lokal di HP ini. Kalau file tidak ada (misal di HP lain), kosong.
    if (cleanPath.startsWith('/') ||
        cleanPath.startsWith('file://') ||
        cleanPath.contains(':\\')) {
      final file = File(cleanPath.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return FileImage(file);
      }
      return null;
    }

    // 4. URL http/https
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return NetworkImage(
          '$cleanPath?v=${DateTime.now().millisecondsSinceEpoch}');
    }

    return null;
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
                // Ketuk foto atau ikon kamera -> tambah / ganti / hapus foto
                GestureDetector(
                  onTap: _savingPhoto ? null : _showPhotoSheet,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: avatarImageProvider,
                        onBackgroundImageError: avatarImageProvider != null
                            ? (e, s) => debugPrint('PROFIL gambar gagal: $e')
                            : null,
                        child: avatarImageProvider == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: Color(0xFF94A3B8),
                              )
                            : null,
                      ),
                      if (_savingPhoto)
                        Positioned.fill(
                          child: ClipOval(
                            child: Container(
                              color: Colors.black38,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
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
                    ],
                  ),
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
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // UNIFIED MENU CONTAINER
          Container(
            clipBehavior: Clip.antiAlias,
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
                  subtitle: 'Ubah nama atau kontak profil',
                  onTap: _navigateToEditProfile,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.lock_reset_rounded,
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Perbarui keamanan kata sandi akun',
                  onTap: _navigateToChangePassword,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Layanan Pelanggan (CS)',
                  subtitle: 'Hubungi tim bantuan via WhatsApp',
                  onTap: () {
                    ConsultationModal.show(context);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // ABOUT ME -> buka popup
                _buildMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Me',
                  subtitle: 'Tentang KIMPUL, identitas resmi aplikasi',
                  onTap: _showAboutDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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