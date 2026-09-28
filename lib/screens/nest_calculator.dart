import 'package:flutter/material.dart';

class NestCalculator extends StatefulWidget {
  /// Opsional: dipanggil saat tombol kembali ditekan.
  final VoidCallback? onBack;

  const NestCalculator({super.key, this.onBack});

  @override
  State<NestCalculator> createState() => _NestCalculatorState();
}

class _NestCalculatorState extends State<NestCalculator> {
  final _openController = TextEditingController();
  final _closeController = TextEditingController();

  String? _signal; // 'BUY' | 'SELL' | 'NETRAL'
  String? _errorText;

  @override
  void dispose() {
    _openController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  double? _parse(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _hitung() {
    final open = _parse(_openController.text);
    final close = _parse(_closeController.text);

    if (open == null || close == null) {
      setState(() {
        _signal = null;
        _errorText = 'Isi harga Open dan Close dengan angka yang valid.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      if (close > open) {
        _signal = 'BUY';
      } else if (close < open) {
        _signal = 'SELL';
      } else {
        _signal = 'NETRAL';
      }
    });
  }

  void _reset() {
    setState(() {
      _openController.clear();
      _closeController.clear();
      _signal = null;
      _errorText = null;
    });
  }

  Color _signalColor() {
    switch (_signal) {
      case 'BUY':
        return const Color(0xFF059669);
      case 'SELL':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _signalDescription() {
    switch (_signal) {
      case 'BUY':
        return 'Harga penutupan (Close) lebih tinggi dari harga pembukaan (Open), tren mengarah naik.';
      case 'SELL':
        return 'Harga penutupan (Close) lebih rendah dari harga pembukaan (Open), tren mengarah turun.';
      default:
        return 'Harga Close sama dengan Open, belum ada arah tren yang jelas.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onBack != null)
            TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: EdgeInsets.zero,
              ),
            ),
          const Text(
            'Nest Calculator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Konsep follow the trend berdasarkan harga penutupan (close).',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Input
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('Harga Open', _openController),
                const SizedBox(height: 12),
                _buildField('Harga Close', _closeController),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _hitung,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hitung',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 18),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hasil
          if (_signal != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _signalColor().withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _signalColor().withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sinyal',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _signal!,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _signalColor(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _signalDescription(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Konsep Transaksi (Nest)
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konsep Transaksi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nest',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Konsep follow the trend yang mengacu pada harga penutupan (close).',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                _buildRuleRow('Close > Open', 'BUY', const Color(0xFF059669)),
                _buildRuleRow('Close < Open', 'SELL', const Color(0xFFE11D48)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String condition, String action, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              condition,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              action,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}