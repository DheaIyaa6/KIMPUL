import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kimpul/screens/history_storage.dart';

class PivotCalculation {
  final String id;
  final String formattedDate;
  final String formattedTime;
  final String pair;
  final String bias;
  final double high;
  final double low;
  final double close;
  final double pp;
  final double r1;
  final double r2;
  final double r3;
  final double r4;
  final double s1;
  final double s2;
  final double s3;
  final double s4;
  final double diff;

  PivotCalculation({
    required this.id,
    required this.formattedDate,
    required this.formattedTime,
    required this.pair,
    required this.bias,
    required this.high,
    required this.low,
    required this.close,
    required this.pp,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.diff,
  });
}

class PivotCalculator extends StatefulWidget {
  final Function(PivotCalculation calculation) onSaveHistory;

  const PivotCalculator({super.key, required this.onSaveHistory});

  @override
  State<PivotCalculator> createState() => _PivotCalculatorState();
}

class _PivotCalculatorState extends State<PivotCalculator> {
  final _pairController = TextEditingController(text: 'XAU/USD');
  final _highController = TextEditingController();
  final _lowController = TextEditingController();
  final _closeController = TextEditingController();
  final _openController = TextEditingController();

  PivotCalculation? _result;
  double? _resultOpen;
  bool _savedSuccess = false;

  void _calculate() {
    final pair = _pairController.text.trim().isEmpty ? 'XAU/USD' : _pairController.text.trim();
    final high = double.tryParse(_highController.text.replaceAll(',', '.')) ?? 0;
    final low = double.tryParse(_lowController.text.replaceAll(',', '.')) ?? 0;
    final close = double.tryParse(_closeController.text.replaceAll(',', '.')) ?? 0;
    final open = double.tryParse(_openController.text.replaceAll(',', '.'));

    if (high <= 0 || low <= 0 || close <= 0 || low >= high) {
      setState(() => _result = null);
      return;
    }

    // Pivot Point Standard
    final pp = (high + low + close) / 3;
    final r1 = (2 * pp) - low;
    final s1 = (2 * pp) - high;
    final r2 = pp + (high - low);
    final s2 = pp - (high - low);
    final r3 = high + 2 * (pp - low);
    final s3 = low - 2 * (high - pp);
    final r4 = r3 + (r2 - r1);
    final s4 = s3 - (s1 - s2);

    String bias = 'netral';
    if (close > pp) {
      bias = 'buy';
    } else if (close < pp) {
      bias = 'sell';
    }

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final timeStr = DateFormat('HH:mm').format(now);

    setState(() {
      _resultOpen = open;
      _result = PivotCalculation(
        id: now.millisecondsSinceEpoch.toString(),
        formattedDate: dateStr,
        formattedTime: timeStr,
        pair: pair,
        bias: bias,
        high: high,
        low: low,
        close: close,
        pp: pp,
        r1: r1,
        r2: r2,
        r3: r3,
        r4: r4,
        s1: s1,
        s2: s2,
        s3: s3,
        s4: s4,
        diff: close - pp,
      );
      _savedSuccess = false;
    });
  }

  void _handleSave() async {
    final calc = _result;
    if (calc == null) return;

    // Simpan semua parameter input dan seluruh level Support & Resistance ke Firestore
    HistoryStorage.save(
      id: calc.id,
      type: 'pivot',
      formattedDate: calc.formattedDate,
      formattedTime: calc.formattedTime,
      pair: calc.pair,
      bias: calc.bias,
      high: calc.high,
      low: calc.low,
      close: calc.close,
      open: _resultOpen,
      pp: calc.pp,
      r1: calc.r1,
      r2: calc.r2,
      r3: calc.r3,
      r4: calc.r4,
      s1: calc.s1,
      s2: calc.s2,
      s3: calc.s3,
      s4: calc.s4,
      diff: calc.diff,
    );

    widget.onSaveHistory(calc);
    setState(() => _savedSuccess = true);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _savedSuccess = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalkulator Pivot Point',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hitung Support (S1-S4) dan Resistance (R1-R4) harian berdasarkan data OHLC.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Form Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _inputField(_pairController, 'Pair / Produk', 'Contoh: XAU/USD'),
                const SizedBox(height: 12),
                _inputField(_highController, 'High', 'Harga Tertinggi Kemarin', isNumber: true),
                const SizedBox(height: 12),
                _inputField(_lowController, 'Low', 'Harga Terendah Kemarin', isNumber: true),
                const SizedBox(height: 12),
                _inputField(_closeController, 'Close', 'Harga Penutupan Kemarin', isNumber: true),
                const SizedBox(height: 12),
                _inputField(_openController, 'Open (Opsional)', 'Harga Pembukaan Kemarin', isNumber: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hitung Level Pivot', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_result != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pivot Levels: ${_result!.pair}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(_savedSuccess ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                            color: _savedSuccess ? Colors.green : primaryColor),
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                  const Divider(),
                  _levelRow('Resistance 4 (R4)', _result!.r4),
                  _levelRow('Resistance 3 (R3)', _result!.r3),
                  _levelRow('Resistance 2 (R2)', _result!.r2),
                  _levelRow('Resistance 1 (R1)', _result!.r1),
                  const Divider(),
                  _levelRow('Pivot Point (PP)', _result!.pp, isBold: true, color: primaryColor),
                  const Divider(),
                  _levelRow('Support 1 (S1)', _result!.s1),
                  _levelRow('Support 2 (S2)', _result!.s2),
                  _levelRow('Support 3 (S3)', _result!.s3),
                  _levelRow('Support 4 (S4)', _result!.s4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _levelRow(String label, double val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            val.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}