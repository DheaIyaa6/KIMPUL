import 'package:flutter/material.dart';

// Enum untuk navigasi tipe kalkulator
enum CalcView { pivot, gold, nest }

class CalcHubScreen extends StatelessWidget {
  final Function(CalcView view) onSelectCalc;

  const CalcHubScreen({
    super.key,
    required this.onSelectCalc,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          const Text(
            'Pusat Kalkulator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Perhitungan teknikal pivot point dan simulasi komoditas emas batangan',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Selection Container
          Column(
            children: [
              // Card 1: Pivot Point Calculator
              _buildCalculatorCard(
                context,
                title: 'Pivot Point Calculator',
                subtitle:
                    'Hitung level pivot harian, empat tingkat support (S1–S4), dan empat tingkat resistance (R1–R4) berdasarkan harga tertinggi, terendah, dan penutupan.',
                icon: Icons.query_stats_rounded,
                buttonText: 'Buka Kalkulator Pivot',
                primaryColor: primaryColor,
                onTap: () => onSelectCalc(CalcView.pivot),
              ),
              const SizedBox(height: 14),

              // Card 2: Kalkulator Emas Fisik
              _buildCalculatorCard(
                context,
                title: 'Kalkulator Emas Fisik',
                subtitle:
                    'Membantu menghitung estimasi nilai beli emas berdasarkan berat, kadar, dan harga saat ini, lengkap dengan rincian pajak, biaya cetak, serta estimasi buyback.',
                icon: Icons.account_balance_wallet_rounded,
                buttonText: 'Buka Kalkulator Emas Fisik',
                primaryColor: primaryColor,
                onTap: () => onSelectCalc(CalcView.gold),
              ),
              const SizedBox(height: 14),

              // Card 3: Nest Calculator
              _buildCalculatorCard(
                context,
                title: 'Nest Calculator',
                subtitle:
                    'Membantu menentukan aksi beli atau jual dengan konsep follow the trend, berdasarkan perbandingan harga penutupan (close) dan harga pembukaan (open).',
                icon: Icons.trending_up_rounded,
                buttonText: 'Buka Kalkulator Nest',
                primaryColor: primaryColor,
                onTap: () => onSelectCalc(CalcView.nest),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Tips / Transparency Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Transparansi Rumus & Pajak',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Setiap kalkulator menyediakan tombol "Lihat Rumus" untuk meninjau langkah pembagian matematis dan acuan tarif pajak secara transparan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String buttonText,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row (Icon & Judul)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Deskripsi
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}