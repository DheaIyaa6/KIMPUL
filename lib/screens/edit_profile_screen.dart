import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart' show UserProfile, ProfileStorage;

/// Halaman Edit Profil: Firebase Auth (nama) + Firestore (nama & foto) + lokal
class EditProfileScreen extends StatefulWidget {
  final UserProfile user;
  final Future<void> Function(UserProfile updatedUser)? onSave;

  const EditProfileScreen({
    super.key,
    required this.user,
    this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Pilih foto dari galeri / kamera (dikecilkan supaya muat di Firestore)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Wrap(
              children: [
                const ListTile(
                  title: Text(
                    'Pilih Foto Profil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF0F172A)),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF0F172A)),
                  title: const Text('Ambil Foto Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Simpan perubahan
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final String newName = _nameController.text.trim();
      String persistedAvatarPath = widget.user.avatarUrl;
      String? newLocalPath;

      // 1. Foto baru: simpan lokal + kirim ke cloud (Firestore)
      if (_selectedImageFile != null) {
        newLocalPath = await ProfileStorage.persistPickedImage(
          _selectedImageFile!,
          email: widget.user.email,
        );

        final cloudAvatar =
            await ProfileStorage.savePhotoToCloud(_selectedImageFile!);
        if (cloudAvatar != null) {
          persistedAvatarPath = cloudAvatar;
        } else {
          if (newLocalPath != null) persistedAvatarPath = newLocalPath;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Foto tersimpan di HP ini saja (gagal kirim ke cloud).'),
              ),
            );
          }
        }
      }

      // 2. Perbarui nama di Firebase Auth + Firestore (supaya ikut ke semua HP)
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        if (newName != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(newName);
        }
        await ProfileStorage.saveNameToCloud(newName);
        await firebaseUser.reload();
      }

      // 3. Objek UserProfile terbaru
      final updatedUser = UserProfile(
        name: newName,
        email: widget.user.email,
        phone: widget.user.phone,
        avatarUrl: persistedAvatarPath,
        clientCode: widget.user.clientCode,
        accountNumber: widget.user.accountNumber,
        branch: widget.user.branch,
      );

      // 4. Simpan nama + path foto lokal (bukan teks base64) di HP ini
      await ProfileStorage.saveLoginProfile(
        name: updatedUser.name,
        email: updatedUser.email,
        avatarPath: newLocalPath,
      );

      if (widget.onSave != null) {
        await widget.onSave!(updatedUser);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.pop(context, updatedUser);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Menentukan ImageProvider avatar
  ImageProvider? _getAvatarImage() {
    // 1. Foto yang baru dipilih
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    }

    final avatarPath = widget.user.avatarUrl.trim();

    // 2. Kosong / dummy
    if (avatarPath.isEmpty ||
        avatarPath == 'null' ||
        avatarPath.contains('pravatar.cc')) {
      return null;
    }

    // 3. Foto dari cloud (base64)
    if (avatarPath.startsWith('b64:')) {
      try {
        return MemoryImage(base64Decode(avatarPath.substring(4)));
      } catch (_) {
        return null;
      }
    }

    // 4. Path file lokal
    if (avatarPath.startsWith('/') ||
        avatarPath.startsWith('file://') ||
        avatarPath.contains(':\\')) {
      final cleanPath = avatarPath.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return null;
    }

    // 5. URL http/https
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return NetworkImage(
          '$avatarPath?v=${DateTime.now().millisecondsSinceEpoch}');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? avatarImage = _getAvatarImage();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Edit Profil',
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
              // FOTO PROFIL
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerModal,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: avatarImage,
                        onBackgroundImageError:
                            avatarImage != null ? (e, s) {} : null,
                        child: avatarImage == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: Color(0xFF94A3B8),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showImagePickerModal,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildLabel('Nama Lengkap'),
              _buildTextField(
                controller: _nameController,
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outlined,
                validator: _validateName,
                enabled: true,
              ),
              const SizedBox(height: 16),

              _buildLabel('Email'),
              _buildTextField(
                controller: _emailController,
                hint: 'Masukkan alamat email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                enabled: false,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
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
                          'Simpan Perubahan',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      readOnly: !enabled,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBE123C)),
        ),
      ),
    );
  }
}