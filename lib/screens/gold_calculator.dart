import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kimpul/screens/history_storage.dart';

class GoldCalculation {
  final String id;
  final String formattedDate;
  final String formattedTime;
  final double modal;
  final double kurs;
  final double hargaBeliUsd;
  final double hargaJualUsd;
  final double hbPerGram;
  final double hjPerGram;
  final double selisihPerGram;
  final double gram;
  final double untung;
  final String purityLabel;
  final double nilaiAkhir;

  GoldCalculation({
    required this.id,
    required this.formattedDate,
    required this.formattedTime,
    required this.modal,
    required this.kurs,
    required this.hargaBeliUsd,
    required this.hargaJualUsd,
    required this.hbPerGram,
    required this.hjPerGram,
    required this.selisihPerGram,
    required this.gram,
    required this.untung,
    required this.purityLabel,
    required this.nilaiAkhir,
  });
}

class GoldCalculator extends StatefulWidget {
  final Function(GoldCalculation calculation) onSaveHistory;

  const GoldCalculator({super.key, required this.onSaveHistory});

  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator> {
  final _modalController = TextEditingController();
  final _kursController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();

  String _selectedPurity = '24K (99.9%)';
  double _purityFactor = 1.0;

  GoldCalculation? _result;
  bool _savedSuccess = false;

  final Map<String, double> _purityOptions = {
    '24K (99.9%)': 1.0,
    '22K (91.6%)': 0.916,
    '18K (75.0%)': 0.750,
    '14K (58.3%)': 0.583,
  };

  void _calculate() {
    final modal = double.tryParse(_modalController.text.replaceAll(',', '.')) ?? 0;
    final kurs = double.tryParse(_kursController.text.replaceAll(',', '.')) ?? 0;
    final hbUsd = double.tryParse(_hargaBeliController.text.replaceAll(',', '.')) ?? 0;
    final hjUsd = double.tryParse(_hargaJualController.text.replaceAll(',', '.')) ?? 0;

    if (modal <= 0 || kurs <= 0 || hbUsd <= 0 || hjUsd <= 0) {
      setState(() => _result = null);
      return;
    }

    // 1 Troy Ounce = 31.1035 gram
    const troyOunce = 31.1035;

    final hbPerGramBase = (hbUsd * kurs) / troyOunce;
    final hjPerGramBase = (hjUsd * kurs) / troyOunce;

    final hbPerGram = hbPerGramBase * _purityFactor;
    final hjPerGram = hjPerGramBase * _purityFactor;

    final gram = modal / hbPerGram;
    final nilaiAkhir = gram * hjPerGram;
    final untung = nilaiAkhir - modal;
    final selisihPerGram = hjPerGram - hbPerGram;

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final timeStr = DateFormat('HH:mm').format(now);

    setState(() {
      _result = GoldCalculation(
        id: now.millisecondsSinceEpoch.toString(),
        formattedDate: dateStr,
        formattedTime: timeStr,
        modal: modal,
        kurs: kurs,
        hargaBeliUsd: hbUsd,
        hargaJualUsd: hjUsd,
        hbPerGram: hbPerGram,
        hjPerGram: hjPerGram,
        selisihPerGram: selisihPerGram,
        gram: gram,
        untung: untung,
        purityLabel: _selectedPurity,
        nilaiAkhir: nilaiAkhir,
      );
      _savedSuccess = false;
    });
  }

  void _handleSave(GoldCalculation calc) async {
    // Simpan data lengkap ke Firestore melalui HistoryStorage
    HistoryStorage.save(
      id: calc.id,
      type: 'gold',
      formattedDate: calc.formattedDate,
      formattedTime: calc.formattedTime,
      modal: calc.modal,
      kurs: calc.kurs,
      hargaBeliUsd: calc.hargaBeliUsd,
      hargaJualUsd: calc.hargaJualUsd,
      hbPerGram: calc.hbPerGram,
      hjPerGram: calc.hjPerGram,
      selisihPerGram: calc.selisihPerGram,
      weight: calc.gram,
      untung: calc.untung,
      purityLabel: calc.purityLabel,
      grandTotal: calc.nilaiAkhir,
    );

    widget.onSaveHistory(calc);
    setState(() => _savedSuccess = true);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _savedSuccess = false);
  }

  String _rupiah(double val) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(val);
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
            'Kalkulator Emas Fisik',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hitung estimasi berat emas yang didapat dan potensi keuntungan investasi emas fisik.',
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
                _buildTextField(_modalController, 'Modal Pembelian (IDR)', 'Contoh: 10000000'),
                const SizedBox(height: 12),
                _buildTextField(_kursController, 'Kurs USD to IDR', 'Contoh: 15500'),
                const SizedBox(height: 12),
                _buildTextField(_hargaBeliController, 'Harga Beli Gold (USD/oz)', 'Contoh: 2650.50'),
                const SizedBox(height: 12),
                _buildTextField(_hargaJualController, 'Harga Jual Gold (USD/oz)', 'Contoh: 2660.00'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPurity,
                  decoration: InputDecoration(
                    labelText: 'Kadar Kemurnian Emas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _purityOptions.keys.map((label) {
                    return DropdownMenuItem(value: label, child: Text(label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPurity = val;
                        _purityFactor = _purityOptions[val]!;
                      });
                      _calculate();
                    }
                  },
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
                    child: const Text('Hitung Emas', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Hasil Perhitungan
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
                      const Text('Hasil Perhitungan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(_savedSuccess ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                            color: _savedSuccess ? Colors.green : primaryColor),
                        onPressed: () => _handleSave(_result!),
                      ),
                    ],
                  ),
                  const Divider(),
                  _resultRow('Modal IDR', _rupiah(_result!.modal)),
                  _resultRow('Harga Beli / Gram', _rupiah(_result!.hbPerGram)),
                  _resultRow('Harga Jual / Gram', _rupiah(_result!.hjPerGram)),
                  _resultRow('Emas Didapat', '${_result!.gram.toStringAsFixed(4)} gram', isBold: true),
                  _resultRow('Estimasi Untung/Rugi', _rupiah(_result!.untung),
                      color: _result!.untung >= 0 ? Colors.green : Colors.red, isBold: true),
                  const Divider(),
                  _resultRow('Nilai Akhir', _rupiah(_result!.nilaiAkhir), isBold: true, color: primaryColor),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _resultRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            value,
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