import 'package:flutter/material.dart';

class LupaPassScreen extends StatelessWidget {
  const LupaPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // --- Ikon Amplop / Email ---
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD8DE), // Warna pink muda latar ikon
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 60,
                    color: Color(0xFFE93A56),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- Judul ---
              const Text(
                'Link Reset Terkirim',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // --- Deskripsi ---
              const Text(
                'Kami telah mengirimkan instruksi perubahan kata sandi ke email Anda. Silakan periksa kotak masuk atau folder spam.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // --- Tombol Kembali ke Login ---
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Kembali ke halaman login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE93A56),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kembali ke Login',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}