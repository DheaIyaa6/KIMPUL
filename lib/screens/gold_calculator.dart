import 'package:flutter/material.dart';

import 'package:kimpul/screens/result_actions.dart';

// Model Data Kalkulasi Emas Fisik
class GoldCalculation {
  final String id;
  final String timestamp;
  final String formattedDate;
  final String formattedTime;
  final double modal; // Rp
  final double kurs; // Rp per 1 USD
  final double hargaBeliUsd; // HB (USD per troy ounce)
  final double hargaJualUsd; // HJ (USD per troy ounce)
  final double hbPerGram; // Rp per gram (beli)
  final double hjPerGram; // Rp per gram (jual)
  final double selisihPerGram; // Rp
  final double gram; // emas yang didapat dari modal
  final double untung; // Rp (negatif = rugi)
  final double nilaiAkhir; // modal + untung
  final bool pembulatanKeBawah;
  final String type; // 'gold'

  GoldCalculation({
    required this.id,
    required this.timestamp,
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
    required this.nilaiAkhir,
    required this.pembulatanKeBawah,
    this.type = 'gold',
  });

  // Nama lama, supaya file lain yang masih memakainya tidak error.
  String get transactionType => 'buy';
  double get weight => gram;
  double get purityValue => 1.0;
  String get purityLabel => '24K';
  double get basePrice => hbPerGram;
  bool get hasNpwp => false;
  double get mintCost => 0;
  double get subtotal => modal;
  double get taxAmount => 0;
  double get grandTotal => nilaiAkhir;
  double get buybackEstimate => gram * hjPerGram;
}

class GoldCalculator extends StatefulWidget {
  final VoidCallback onBack;
  final Function(GoldCalculation calc) onSaveHistory;
  final Function(GoldCalculation calc) onOpenDetailModal;
  final GoldCalculation? initialValues;

  const GoldCalculator({
    super.key,
    required this.onBack,
    required this.onSaveHistory,
    required this.onOpenDetailModal,
    this.initialValues,
  });

  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator> {
  // TOZ (troy ounce -> gram): ketetapan, tidak bisa diubah (sesuai catatan)
  static const double _toz = 31.1;

  static const Color _accent = Color(0xFFBE123C);
  static const Color _profitColor = Color(0xFF059669);

  // Nilai awal = contoh dari catatan (hasil untung Rp 48.374)
  static const double _defModal = 100000000;
  static const double _defKurs = 18000;
  static const double _defHb = 4132;
  static const double _defHj = 4134;

  late final TextEditingController _modalC;
  late final TextEditingController _kursC;
  late final TextEditingController _hbC;
  late final TextEditingController _hjC;

  bool _roundDown = true;
  bool _showFormula = true;
  bool _savedSuccess = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialValues;
    _modalC = TextEditingController(text: _plain(init?.modal ?? _defModal));
    _kursC = TextEditingController(text: _plain(init?.kurs ?? _defKurs));
    _hbC = TextEditingController(text: _plain(init?.hargaBeliUsd ?? _defHb));
    _hjC = TextEditingController(text: _plain(init?.hargaJualUsd ?? _defHj));
    _roundDown = init?.pembulatanKeBawah ?? true;
  }

  @override
  void dispose() {
    _modalC.dispose();
    _kursC.dispose();
    _hbC.dispose();
    _hjC.dispose();
    super.dispose();
  }

  // ---------- Helper ----------

  String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  // Modal & kurs: titik pemisah ribuan (100.000.000) boleh diketik
  double? _parseMoney(String s) {
    var t = s.trim();
    if (RegExp(r'^\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(t)) {
      t = t.replaceAll('.', '');
    }
    return double.tryParse(t.replaceAll(',', '.'));
  }

  // Harga USD: koma atau titik sama-sama dianggap desimal
  double? _parseDecimal(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  String _rp(double v) {
    final neg = v < 0;
    final s = v.abs().round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return neg ? '-$s' : s;
  }

  String _gramText(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  String _usd(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _handleReset() {
    setState(() {
      _modalC.text = _plain(_defModal);
      _kursC.text = _plain(_defKurs);
      _hbC.text = _plain(_defHb);
      _hjC.text = _plain(_defHj);
      _roundDown = true;
    });
  }

  // ---------- Perhitungan (sesuai catatan) ----------
  //
  // 1) HB x Kurs / TOZ          -> Rp per gram (beli)
  // 2) HJ x Kurs / TOZ          -> Rp per gram (jual)
  // 3) hasil 2 - hasil 1        -> selisih per gram
  // 4) Modal / hasil 1          -> gram yang didapat
  // 5) hasil 3 x hasil 4        -> untung

  GoldCalculation? _calculate() {
    final modal = _parseMoney(_modalC.text);
    final kurs = _parseMoney(_kursC.text);
    final hb = _parseDecimal(_hbC.text);
    final hj = _parseDecimal(_hjC.text);

    if (modal == null || kurs == null || hb == null || hj == null) return null;
    if (modal <= 0 || kurs <= 0 || hb <= 0 || hj <= 0) return null;

    double hbGram = hb * kurs / _toz;
    double hjGram = hj * kurs / _toz;
    if (_roundDown) {
      hbGram = (hbGram + 1e-9).floorToDouble();
      hjGram = (hjGram + 1e-9).floorToDouble();
    }
    if (hbGram <= 0) return null;

    double gram = modal / hbGram;
    if (_roundDown) {
      gram = ((gram * 100) + 1e-9).floorToDouble() / 100;
    }

    final selisih = hjGram - hbGram;
    final untung = selisih * gram;

    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return GoldCalculation(
      id: 'gold-${now.millisecondsSinceEpoch}',
      timestamp: now.toIso8601String(),
      formattedDate:
          '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}',
      formattedTime:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      modal: modal,
      kurs: kurs,
      hargaBeliUsd: hb,
      hargaJualUsd: hj,
      hbPerGram: hbGram,
      hjPerGram: hjGram,
      selisihPerGram: selisih,
      gram: gram,
      untung: untung,
      nilaiAkhir: modal + untung,
      pembulatanKeBawah: _roundDown,
    );
  }

  void _handleSave(GoldCalculation calc) async {
    widget.onSaveHistory(calc);
    setState(() => _savedSuccess = true);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _savedSuccess = false);
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final calc = _calculate();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Emas Fisik • Kurs',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569))),
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
          const SizedBox(height: 2),
          const Text(
            'Hitung untung/rugi emas dari modal, kurs, harga beli (HB), dan harga jual (HJ) dalam USD per ons.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // SECTION 1: INPUT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parameter',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: _accent)),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildField('Modal', _modalC, prefix: 'Rp '),
                const SizedBox(height: 12),
                _buildField('Kurs (Rp per 1 USD)', _kursC, prefix: 'Rp '),
                const SizedBox(height: 12),
                _buildField('Harga Beli / HB (USD per ons)', _hbC,
                    suffix: 'USD'),
                const SizedBox(height: 12),
                _buildField('Harga Jual / HJ (USD per ons)', _hjC,
                    suffix: 'USD'),
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
                const SizedBox(height: 10),

                // Pembulatan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pembulatan seperti catatan',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _accent)),
                            Text(
                              'Rp per gram dibulatkan ke bawah, gram 2 desimal.',
                              style: TextStyle(
                                  fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _roundDown,
                        activeThumbColor: _accent,
                        onChanged: (v) => setState(() => _roundDown = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nilai awal di atas adalah contoh dari catatan (untung Rp 48.374).',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),

                // Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _handleReset,
                      child: const Row(
                        children: [
                          Icon(Icons.restart_alt_rounded,
                              size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text('Reset Form',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
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
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: _accent, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i][0],
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(steps[i][1],
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text(steps[i][2],
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildResult(GoldCalculation? c) {
    if (c == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Column(
          children: [
            Icon(Icons.calculate_outlined, size: 32, color: Color(0xFF94A3B8)),
            SizedBox(height: 8),
            Text('Belum ada hasil',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            SizedBox(height: 4),
            Text(
              'Isi Modal, Kurs, HB, dan HJ dengan angka lebih dari 0.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    final bool rugi = c.untung < 0;
    final Color color = rugi ? _accent : _profitColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HASIL PERHITUNGAN',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rugi ? 'RUGI' : 'UNTUNG',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Rp ',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    Text(_rp(c.untung.abs()),
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: -0.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _row('Emas yang didapat', '${_gramText(c.gram)} gram'),
          const SizedBox(height: 6),
          _row('Harga beli per gram', 'Rp ${_rp(c.hbPerGram)}'),
          const SizedBox(height: 6),
          _row('Harga jual per gram', 'Rp ${_rp(c.hjPerGram)}'),
          const SizedBox(height: 6),
          _row('Selisih per gram', 'Rp ${_rp(c.selisihPerGram)}'),
          const SizedBox(height: 6),
          _row('Nilai akhir', 'Rp ${_rp(c.nilaiAkhir)}'),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleSave(c),
              icon: Icon(
                  _savedSuccess
                      ? Icons.check_circle_rounded
                      : Icons.bookmark_add_rounded,
                  size: 18),
              label: Text(_savedSuccess
                  ? 'Tersimpan di Riwayat!'
                  : 'Simpan ke Riwayat'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _savedSuccess ? _profitColor : _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onOpenDetailModal(c),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Lihat Rincian Lengkap'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                foregroundColor: _accent,
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
          ResultActions(
            title: 'Kalkulator Emas Fisik',
            rows: _shareRows(c),
            color: _accent,
          ),
        ],
      ),
    );
  }

  // Baris untuk dibagikan / dicetak
  List<MapEntry<String, String>> _shareRows(GoldCalculation c) {
    final bool rugi = c.untung < 0;
    return [
      MapEntry('Tanggal', '${c.formattedDate} ${c.formattedTime}'),
      const MapEntry('Input', ''),
      MapEntry('Modal', 'Rp ${_rp(c.modal)}'),
      MapEntry('Kurs', 'Rp ${_rp(c.kurs)} per USD'),
      MapEntry('Harga beli (HB)', '${_usd(c.hargaBeliUsd)} USD per ons'),
      MapEntry('Harga jual (HJ)', '${_usd(c.hargaJualUsd)} USD per ons'),
      const MapEntry('Hasil', ''),
      MapEntry('Harga beli per gram', 'Rp ${_rp(c.hbPerGram)}'),
      MapEntry('Harga jual per gram', 'Rp ${_rp(c.hjPerGram)}'),
      MapEntry('Selisih per gram', 'Rp ${_rp(c.selisihPerGram)}'),
      MapEntry('Emas yang didapat', '${_gramText(c.gram)} gram'),
      MapEntry(rugi ? 'RUGI' : 'UNTUNG', 'Rp ${_rp(c.untung.abs())}'),
      MapEntry('Nilai akhir', 'Rp ${_rp(c.nilaiAkhir)}'),
    ];
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
        Text(value,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}