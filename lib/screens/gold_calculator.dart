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
  // TOZ (troy ounce -> gram): ketetapan, tidak bisa diubah (sesuai catatan)
  static const double _toz = 31.1;

  // Warna utama KIMPUL (pink)
  static const Color _accent = Color(0xFFE93A56);
  static const Color _profitColor = Color(0xFF059669);

  // Contoh angka awal (bisa diedit pengguna)
  static const double _exModal = 100000000;
  static const double _exKurs = 18000; // diganti kurs live kalau berhasil diambil
  static const double _exHb = 4132;
  static const double _exHj = 4134;

  // Kurs USD -> IDR (tanpa API key, update harian)
  static const String _kursUrl = 'https://open.er-api.com/v6/latest/USD';

  late final TextEditingController _modalC;
  late final TextEditingController _kursC;
  late final TextEditingController _hbC;
  late final TextEditingController _hjC;

  // Pembulatan seperti catatan: selalu aktif
  late final bool _roundDown;
  bool _showFormula = true;
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
          // Top Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          size: 18, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text('Kembali',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Header
          const Text(
            'Kalkulator Emas Fisik',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _accent,
                letterSpacing: -0.5),
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
                const Text('Parameter',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: _accent)),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildField('Modal', _modalC, prefix: 'Rp '),
                const SizedBox(height: 12),
                _buildTextField(_kursController, 'Kurs USD to IDR', 'Contoh: 15500'),
                const SizedBox(height: 12),
                _buildTextField(_hargaBeliController, 'Harga Beli Gold (USD/oz)', 'Contoh: 2650.50'),
                const SizedBox(height: 12),
                _buildTextField(_hargaJualController, 'Harga Jual Gold (USD/oz)', 'Contoh: 2660.00'),
                const SizedBox(height: 12),

                // TOZ (tetap)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TOZ (troy ounce) = 31,1 gram. Ketetapan, tidak bisa diubah.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showFormula = !_showFormula),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded,
                              size: 16, color: _accent),
                          const SizedBox(width: 4),
                          Text(
                            _showFormula ? 'Tutup Rumus' : 'Lihat Rumus',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SECTION 2: LANGKAH PERHITUNGAN
          if (_showFormula) ...[
            _buildSteps(calc),
            const SizedBox(height: 12),
          ],

          // SECTION 3: HASIL
          _buildResult(calc),
        ],
      ),
    );
  }

  // ---------- Widget bantu ----------

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      );

  Widget _buildField(String label, TextEditingController c,
      {String? prefix, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155))),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: _accent),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCBD5E1)),
            prefixText: prefix,
            prefixStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)),
            suffixText: suffix,
            suffixStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
        ),
      ],
    );
  }

  // Status kurs live + tombol Perbarui
  Widget _buildKursStatus() {
    String text;
    Color color = const Color(0xFF94A3B8);
    if (_loadingKurs) {
      text = 'Mengambil kurs USD ke IDR...';
    } else if (_kursError) {
      text = 'Gagal mengambil kurs. Isi manual atau coba lagi.';
      color = const Color(0xFF9A3412);
    } else if (_kursInfo.isNotEmpty) {
      text = _kursInfo;
    } else {
      text = 'Kurs diambil otomatis, bisa diubah manual.';
    }

    return Row(
      children: [
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11, color: color)),
        ),
        InkWell(
          onTap: _loadingKurs ? null : _fetchKurs,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded,
                    size: 15,
                    color: _loadingKurs ? const Color(0xFF94A3B8) : _accent),
                const SizedBox(width: 3),
                Text(
                  'Perbarui',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _loadingKurs ? const Color(0xFF94A3B8) : _accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSteps(GoldCalculation? c) {
    final steps = <List<String>>[
      [
        'Harga beli per gram',
        'HB × Kurs ÷ TOZ',
        c == null
            ? '-'
            : '${_usd(c.hargaBeliUsd)} × ${_rp(c.kurs)} ÷ 31,1 = Rp ${_rp(c.hbPerGram)}',
      ],
      [
        'Harga jual per gram',
        'HJ × Kurs ÷ TOZ',
        c == null
            ? '-'
            : '${_usd(c.hargaJualUsd)} × ${_rp(c.kurs)} ÷ 31,1 = Rp ${_rp(c.hjPerGram)}',
      ],
      [
        'Selisih per gram',
        'Hasil 2 − Hasil 1',
        c == null
            ? '-'
            : '${_rp(c.hjPerGram)} − ${_rp(c.hbPerGram)} = Rp ${_rp(c.selisihPerGram)}',
      ],
      [
        'Jumlah emas (anggap itu gram emasnya)',
        'Modal ÷ Hasil 1',
        c == null
            ? '-'
            : '${_rp(c.modal)} ÷ ${_rp(c.hbPerGram)} = ${_gramText(c.gram)} gram',
      ],
      [
        'Untung / Rugi',
        'Hasil 3 × Hasil 4',
        c == null
            ? '-'
            : '${_rp(c.selisihPerGram)} × ${_gramText(c.gram)} = Rp ${_rp(c.untung)}',
      ],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.functions_rounded, size: 18, color: _accent),
              SizedBox(width: 6),
              Text('Langkah Perhitungan',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _accent)),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++) ...[
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