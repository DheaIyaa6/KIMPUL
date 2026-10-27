import 'package:flutter/material.dart';

import 'package:kimpul/screens/history_storage.dart';
import 'package:kimpul/screens/nest_prev_day.dart';
import 'package:kimpul/screens/result_actions.dart';

// Model Data Kalkulasi Nest
class NestCalculation {
  final String id;
  final String timestamp;
  final String formattedDate;
  final String formattedTime;
  final String pair; // XUL / HKK / JPK
  final double open;
  final double close;
  final double diff; // close - open
  final double diffPercent;
  final String signal; // 'BUY' | 'SELL' | 'NETRAL'
  final String type; // 'nest'

  NestCalculation({
    required this.id,
    required this.timestamp,
    required this.formattedDate,
    required this.formattedTime,
    required this.pair,
    required this.open,
    required this.close,
    required this.diff,
    required this.diffPercent,
    required this.signal,
    this.type = 'nest',
  });

  // Sinyal huruf kecil ('buy' / 'sell' / 'netral'), sama seperti kartu Pivot
  // di Riwayat. Dipakai saat membuat HistoryItem.
  String get signalKey => signal.toLowerCase();

  // Ringkasan satu baris untuk deskripsi di Riwayat.
  String get summary {
    final sign = diff > 0 ? '+' : '';
    return 'Open ${open.toStringAsFixed(2)} • Close ${close.toStringAsFixed(2)} '
        '• Selisih $sign${diff.toStringAsFixed(2)} '
        '($sign${diffPercent.toStringAsFixed(2)}%)';
  }
}

// Produk yang bisa dipilih
class _NestProduct {
  final String label;
  final String subtitle;
  final String tvSymbol; // grafik TradingView
  final String yahooSymbol; // data candle kemarin
  final String unit;
  final IconData icon;

  const _NestProduct({
    required this.label,
    required this.subtitle,
    required this.tvSymbol,
    required this.yahooSymbol,
    required this.unit,
    required this.icon,
  });
}

class NestCalculator extends StatefulWidget {
  final VoidCallback onBack;
  final Function(NestCalculation calc) onSaveHistory;

  // Opsional, disamakan dengan GoldCalculator / PivotCalculator supaya
  // pemanggil yang sama tidak error. Kalau tidak dikirim, tidak masalah.
  final Function(NestCalculation calc)? onOpenDetailModal;
  final NestCalculation? initialValues;

  const NestCalculator({
    super.key,
    required this.onBack,
    required this.onSaveHistory,
    this.onOpenDetailModal,
    this.initialValues,
  });

  @override
  State<NestCalculator> createState() => _NestCalculatorState();
}

class _NestCalculatorState extends State<NestCalculator> {
  static const Color _buyColor = Color(0xFF059669);
  static const Color _sellColor = Color(0xFFE11D48);
  static const Color _neutralColor = Color(0xFF64748B);

  static const List<_NestProduct> _products = [
    _NestProduct(
      label: 'XUL',
      subtitle: 'Gold / USD',
      tvSymbol: 'OANDA:XAUUSD',
      yahooSymbol: 'GC=F',
      unit: 'USD',
      icon: Icons.monetization_on_rounded,
    ),
    _NestProduct(
      label: 'HKK',
      subtitle: 'Hang Seng',
      tvSymbol: 'OANDA:HK33HKD',
      yahooSymbol: '^HSI',
      unit: 'poin',
      icon: Icons.bar_chart_rounded,
    ),
    _NestProduct(
      label: 'JPK',
      subtitle: 'Nikkei 225',
      tvSymbol: 'OANDA:JP225USD',
      yahooSymbol: '^N225',
      unit: 'poin',
      icon: Icons.show_chart_rounded,
    ),
  ];

  final TextEditingController _openC = TextEditingController();
  final TextEditingController _closeC = TextEditingController();

  int _productIndex = 0;
  bool _autoMode = true;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String _info = '';
  NestCalculation? _result;
  bool _savedSuccess = false;

  _NestProduct get _product => _products[_productIndex];

  @override
  void initState() {
    super.initState();
    final init = widget.initialValues;
    if (init != null) {
      // Dibuka dari riwayat (hitung ulang): isi angka lama, mode manual
      final idx = _products.indexWhere((p) => p.label == init.pair);
      if (idx >= 0) _productIndex = idx;
      _openC.text = _f(init.open);
      _closeC.text = _f(init.close);
      _autoMode = false;
    } else {
      _loadPrev();
    }
  }

  @override
  void dispose() {
    _openC.dispose();
    _closeC.dispose();
    super.dispose();
  }

  // ---------- Helper ----------

  String _f(double v) => v.toStringAsFixed(2);
  String _signed(double v) => v >= 0 ? '+${_f(v)}' : _f(v);
  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Data candle kemarin (mode otomatis) ----------

  Future<void> _loadPrev() async {
    final product = _product;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await NestPrevDay.fetch(product.yahooSymbol);
      if (!mounted || product.label != _product.label) return;
      setState(() {
        _openC.text = d.open.toStringAsFixed(2);
        _closeC.text = d.close.toStringAsFixed(2);
        _info = 'Candle kemarin (${d.date}) dari Yahoo Finance';
        _loading = false;
      });
    } catch (_) {
      if (!mounted || product.label != _product.label) return;
      setState(() {
        _loading = false;
        _error =
            'Gagal ambil data kemarin. Coba lagi atau pindah ke mode Manual.';
      });
    }
  }

  void _selectProduct(int index) {
    if (index == _productIndex) return;
    setState(() {
      _productIndex = index;
      _openC.clear();
      _closeC.clear();
      _info = '';
      _error = null;
      _result = null;
      _savedSuccess = false;
    });
    if (_autoMode) _loadPrev();
  }

  void _handleReset() {
    setState(() {
      _openC.clear();
      _closeC.clear();
      _result = null;
      _savedSuccess = false;
    });
    if (_autoMode) _loadPrev();
  }

  // ---------- Perhitungan ----------
  //
  // Follow the trend:
  //   Close > Open  -> tren naik   -> BUY
  //   Close < Open  -> tren turun  -> SELL
  //   Close = Open  -> NETRAL

  Future<void> _handleCalculate() async {
    FocusScope.of(context).unfocus();

    if (_autoMode) {
      await _loadPrev();
      if (!mounted) return;
      // Kalau pengambilan data gagal, jangan hitung pakai angka lama
      if (_error != null) {
        _snack(_error!);
        return;
      }
    }

    final double? open = _parse(_openC.text);
    final double? close = _parse(_closeC.text);

    if (open == null || close == null || open <= 0 || close <= 0) {
      _snack(_autoMode
          ? 'Data kemarin belum berhasil diambil. Coba lagi atau pakai mode Manual.'
          : 'Isi Open dan Close dengan angka yang valid (lebih dari 0).');
      return;
    }

    final double diff = double.parse((close - open).toStringAsFixed(2));
    final double pct = double.parse((diff / open * 100).toStringAsFixed(2));
    final String signal = diff > 0 ? 'BUY' : (diff < 0 ? 'SELL' : 'NETRAL');

    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    setState(() {
      _result = NestCalculation(
        id: 'nest-${now.millisecondsSinceEpoch}',
        timestamp: now.toIso8601String(),
        formattedDate:
            '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}',
        formattedTime:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        pair: _product.label,
        open: open,
        close: close,
        diff: diff,
        diffPercent: pct,
        signal: signal,
      );
      _savedSuccess = false;
    });
  }

  Future<void> _handleSave(NestCalculation calc) async {
    if (_saving) return;
    setState(() => _saving = true);
    // 1) Simpan ke cloud (per akun): tetap ada setelah logout
    HistoryStorage.save(
      id: calc.id,
      type: 'nest',
      formattedDate: calc.formattedDate,
      formattedTime: calc.formattedTime,
      pair: calc.pair,
      bias: calc.signalKey,
      title: 'Nest ${calc.pair} • ${calc.signal}',
      description: calc.summary,
    );
    // 2) Tetap kabari halaman induk (daftar riwayat di memori)
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

  List<MapEntry<String, String>> _shareRows(NestCalculation c) {
    return [
      MapEntry('Produk', '${_product.label} (${_product.subtitle})'),
      MapEntry('Tanggal', '${c.formattedDate} ${c.formattedTime}'),
      const MapEntry('Candle kemarin', ''),
      MapEntry('Open', _f(c.open)),
      MapEntry('Close', _f(c.close)),
      MapEntry('Selisih (Close - Open)', _signed(c.diff)),
      MapEntry('Perubahan', '${_signed(c.diffPercent)}%'),
      const MapEntry('Hasil', ''),
      MapEntry('Sinyal', c.signal),
    ];
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final NestCalculation? calc = _result;

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
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          size: 18, color: primaryColor),
                      const SizedBox(width: 4),
                      Text('Kembali',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Nest Calculator',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tentukan aksi Buy atau Sell dengan konsep follow the trend, dari perbandingan harga Close dan Open.',
            style: TextStyle(fontSize: 13, color: Color(0xFF515F74)),
          ),
          const SizedBox(height: 16),

          // Pilihan produk
          Row(
            children: List.generate(_products.length, (index) {
              final p = _products[index];
              final bool selected = index == _productIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: index == _products.length - 1 ? 0 : 8),
                  child: InkWell(
                    onTap: () => _selectProduct(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected
                                ? primaryColor
                                : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(p.icon,
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF64748B)),
                          const SizedBox(height: 4),
                          Text(p.label,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF0F172A))),
                          Text(p.subtitle,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // INPUT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Input Harga',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text('${_product.label} • ${_product.subtitle}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF515F74))),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildModeToggle(primaryColor),
                const SizedBox(height: 12),
                _buildInputField('Open Kemarin (Pembukaan)', 'O', _openC,
                    Icons.login_rounded, primaryColor),
                const SizedBox(height: 12),
                _buildInputField('Close Kemarin (Penutupan)', 'C', _closeC,
                    Icons.flag_rounded, primaryColor),
                const SizedBox(height: 6),
                _buildStatus(primaryColor),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _handleCalculate,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.calculate_rounded, size: 18),
                    label: Text(_loading ? 'Memuat data...' : 'Hitung'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primaryColor.withValues(alpha: 0.6),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: _handleReset,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt_rounded,
                            size: 16, color: Color(0xFF515F74)),
                        SizedBox(width: 4),
                        Text('Reset Nilai',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF515F74))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // HASIL
          if (calc == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(),
              child: const Column(
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 32, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text('Belum ada hasil',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Tekan Hitung untuk melihat sinyal Buy/Sell.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                ],
              ),
            )
          else ...[
            _buildSignalCard(calc),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _handleSave(calc),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _savedSuccess
                            ? Icons.check_circle_rounded
                            : Icons.bookmark_add_rounded,
                        size: 18),
                label: Text(_saving
                    ? 'Menyimpan...'
                    : (_savedSuccess
                        ? 'Tersimpan di Riwayat!'
                        : 'Simpan ke Riwayat')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _savedSuccess ? _buyColor : primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white,
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
            ResultActions(
              title: 'Nest ${_product.label}',
              rows: _shareRows(calc),
              color: primaryColor,
            ),
          ],
          const SizedBox(height: 12),

          _buildKonsep(),
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

  Widget _buildModeToggle(Color primaryColor) {
    Widget opt(String label, IconData icon, bool auto) {
      final bool selected = _autoMode == auto;
      return Expanded(
        child: InkWell(
          onTap: () {
            if (_autoMode == auto) return;
            setState(() {
              _autoMode = auto;
              _result = null;
            });
            if (auto) _loadPrev();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? primaryColor : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF334155))),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opt('Otomatis', Icons.auto_awesome_rounded, true),
        const SizedBox(width: 8),
        opt('Manual', Icons.edit_rounded, false),
      ],
    );
  }

  Widget _buildStatus(Color primaryColor) {
    if (!_autoMode) return const SizedBox.shrink();
    String text;
    Color color = const Color(0xFF94A3B8);
    if (_loading) {
      text = 'Mengambil data kemarin...';
    } else if (_error != null) {
      text = _error!;
      color = const Color(0xFF9A3412);
    } else if (_info.isNotEmpty) {
      text = _info;
    } else {
      text = 'Open dan Close kemarin diambil otomatis.';
    }
    return Row(
      children: [
        Expanded(
            child: Text(text, style: TextStyle(fontSize: 11, color: color))),
        InkWell(
          onTap: _loading ? null : _loadPrev,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded,
                    size: 15,
                    color:
                        _loading ? const Color(0xFF94A3B8) : primaryColor),
                const SizedBox(width: 3),
                Text('Perbarui',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _loading
                            ? const Color(0xFF94A3B8)
                            : primaryColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String badge,
      TextEditingController controller, IconData icon, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155))),
            Text(badge,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: _autoMode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) {
            if (_result != null) setState(() => _result = null);
          },
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCBD5E1)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            suffixText: _product.unit,
            suffixStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF515F74)),
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
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalCard(NestCalculation c) {
    final Color color = c.signal == 'BUY'
        ? _buyColor
        : (c.signal == 'SELL' ? _sellColor : _neutralColor);
    final String trend = c.signal == 'BUY'
        ? 'naik'
        : (c.signal == 'SELL' ? 'turun' : 'datar');
    final String relation = c.close > c.open
        ? 'di atas'
        : (c.close < c.open ? 'di bawah' : 'sama dengan');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SINYAL NEST',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF515F74),
                      letterSpacing: 0.5)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(c.signal,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Close ${_f(c.close)} berada $relation Open ${_f(c.open)}, jadi tren $trend (${c.pair}).',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _metric('Selisih (Close - Open)', _signed(c.diff),
                      color)),
              Expanded(
                  child: _metric(
                      'Perubahan', '${_signed(c.diffPercent)}%', color)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Aturan: ikuti arah tren. Close di atas Open = Buy, Close di bawah Open = Sell.',
            style:
                TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildKonsep() {
    Widget rule(String cond, String action, Color color) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(cond,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(action,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Konsep Transaksi',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          const Text('Nest (Follow the Trend)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text(
            'Menentukan aksi beli atau jual dengan mengikuti arah tren, berdasarkan perbandingan harga penutupan (Close) dan harga pembukaan (Open).',
            style: TextStyle(
                fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 4),
          rule('Close > Open', 'BUY', _buyColor),
          rule('Close < Open', 'SELL', _sellColor),
        ],
      ),
    );
  }
}