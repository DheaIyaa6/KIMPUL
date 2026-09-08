import 'package:flutter/material.dart';

// Enum untuk navigasi tipe kalkulator
enum CalcView { pivot, gold }

class CalcHubScreen extends StatelessWidget {
  final Function(CalcView view) onSelectCalc;

  const CalcHubScreen({
    super.key,
    required this.onSelectCalc,
  });

  @override
  Widget build(BuildContext context) {
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
                    'Hitung level pivot harian, tiga tingkat support (S1–S3), dan tiga tingkat resistance (R1–R3) berdasarkan harga tertinggi, terendah, dan penutupan.',
                badgeText: 'Floor Classical',
                icon: Icons.query_stats_rounded,
                buttonText: 'Buka Kalkulator Pivot',
                feature1: 'S/R 3 Tingkat',
                feature2: 'Formula Baku Intraday',
                onTap: () => onSelectCalc(CalcView.pivot),
              ),
              const SizedBox(height: 14),

              // Card 2: Kalkulator Emas Fisik
              _buildCalculatorCard(
                context,
                title: 'Kalkulator Emas Fisik',
                subtitle:
                    'Simulasi perhitungan nilai emas fisik 24 Karat (Antam / UBS), berat gramatur, tarif PPh 22 NPWP, ongkos cetak kemasan CertiCard, dan estimasi buyback.',
                badgeText: 'Logam Mulia Batangan',
                icon: Icons.account_balance_wallet_rounded,
                buttonText: 'Buka Kalkulator Emas Fisik',
                feature1: 'Regulasi Pajak PMK',
                feature2: 'Estimasi Spread Buyback',
                onTap: () => onSelectCalc(CalcView.gold),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF0F172A),
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
    required String badgeText,
    required IconData icon,
    required String buttonText,
    required String feature1,
    required String feature2,
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
          // Top Header Row (Icon & Badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title & Description
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Feature Checks
          Row(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    feature1,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '•',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    feature2,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
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