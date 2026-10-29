import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kimpul/screens/history_storage.dart';

class NestCalculation {
  final String id;
  final String formattedDate;
  final String formattedTime;
  final String pair;
  final double open;
  final double close;
  final double diff;
  final double diffPercent;
  final String signal;
  final String signalKey;
  final String summary;

  NestCalculation({
    required this.id,
    required this.formattedDate,
    required this.formattedTime,
    required this.pair,
    required this.open,
    required this.close,
    required this.diff,
    required this.diffPercent,
    required this.signal,
    required this.signalKey,
    required this.summary,
  });
}

class NestCalculator extends StatefulWidget {
  final Function(NestCalculation calculation) onSaveHistory;

  const NestCalculator({super.key, required this.onSaveHistory});

  @override
  State<NestCalculator> createState() => _NestCalculatorState();
}

class _NestCalculatorState extends State<NestCalculator> {
  final _pairController = TextEditingController(text: 'XAU/USD');
  final _openController = TextEditingController();
  final _closeController = TextEditingController();

  NestCalculation? _result;
  bool _saving = false;
  bool _savedSuccess = false;

  void _calculate() {
    final pair = _pairController.text.trim().isEmpty ? 'XAU/USD' : _pairController.text.trim();
    final open = double.tryParse(_openController.text.replaceAll(',', '.')) ?? 0;
    final close = double.tryParse(_closeController.text.replaceAll(',', '.')) ?? 0;

    if (open <= 0 || close <= 0) {
      setState(() => _result = null);
      return;
    }

    final diff = close - open;
    final diffPercent = (diff / open) * 100;

    String signal = 'NETRAL';
    String signalKey = 'netral';
    if (diffPercent > 0.15) {
      signal = 'BULLISH (BUY)';
      signalKey = 'buy';
    } else if (diffPercent < -0.15) {
      signal = 'BEARISH (SELL)';
      signalKey = 'sell';
    }

    final summary = 'Open: ${open.toStringAsFixed(2)}, Close: ${close.toStringAsFixed(2)}, '
        'Selisih: ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} (${diffPercent.toStringAsFixed(2)}%)';

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final timeStr = DateFormat('HH:mm').format(now);

    setState(() {
      _result = NestCalculation(
        id: now.millisecondsSinceEpoch.toString(),
        formattedDate: dateStr,
        formattedTime: timeStr,
        pair: pair,
        open: open,
        close: close,
        diff: diff,
        diffPercent: diffPercent,
        signal: signal,
        signalKey: signalKey,
        summary: summary,
      );
      _savedSuccess = false;
    });
  }

  Future<void> _handleSave(NestCalculation calc) async {
    if (_saving) return;
    setState(() => _saving = true);

    // Simpan parameter input dan hasil lengkap ke Firestore
    HistoryStorage.save(
      id: calc.id,
      type: 'nest',
      formattedDate: calc.formattedDate,
      formattedTime: calc.formattedTime,
      pair: calc.pair,
      bias: calc.signalKey,
      open: calc.open,
      close: calc.close,
      diff: calc.diff,
      diffPercent: calc.diffPercent,
      signal: calc.signal,
      title: '${calc.pair} • ${calc.signal}',
      description: calc.summary,
    );

    try {
      await Future.sync(() => widget.onSaveHistory(calc));
    } catch (e) {
      debugPrint('Nest: onSaveHistory error: $e');
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _savedSuccess = true;
    });

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
            'Kalkulator Nest Strategy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Analisis pergerakan harga Open & Close kemarin untuk menentukan bias arah tren (Buy/Sell).',
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
                TextField(
                  controller: _pairController,
                  decoration: InputDecoration(
                    labelText: 'Pasar / Pair',
                    hintText: 'Misal: XAU/USD atau HSI',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _calculate(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _openController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Harga Open Sesi Kemarin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _calculate(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _closeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Harga Close Sesi Kemarin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _calculate(),
                ),
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
                    child: const Text('Hitung Bias Nest', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      Text('Sinyal: ${_result!.pair}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(_savedSuccess ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                            color: _savedSuccess ? Colors.green : primaryColor),
                        onPressed: _saving ? null : () => _handleSave(_result!),
                      ),
                    ],
                  ),
                  const Divider(),
                  _row('Harga Open', _result!.open.toStringAsFixed(2)),
                  _row('Harga Close', _result!.close.toStringAsFixed(2)),
                  _row('Selisih Poin',
                      '${_result!.diff >= 0 ? '+' : ''}${_result!.diff.toStringAsFixed(2)}'),
                  _row('Perubahan (%)', '${_result!.diffPercent.toStringAsFixed(2)}%'),
                  const Divider(),
                  _row(
                    'REKOMENDASI TRADING',
                    _result!.signal,
                    isBold: true,
                    color: _result!.signalKey == 'buy'
                        ? Colors.green
                        : (_result!.signalKey == 'sell' ? Colors.red : Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            val,
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