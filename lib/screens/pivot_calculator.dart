import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:kimpul/screens/history_storage.dart';
import 'package:kimpul/screens/prev_day_service.dart';
import 'package:kimpul/screens/result_actions.dart';

// Model Data Kalkulasi Pivot
class PivotCalculation {
  final String id;
  final String timestamp;
  final String formattedDate;
  final String formattedTime;
  final String pair;
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
  final String bias; // 'bullish', 'bearish', 'sideway' (hasil hitung) / 'buy', 'sell', 'netral' (di Riwayat)
  final double diff;
  final String type; // 'pivot'

  PivotCalculation({
    required this.id,
    required this.timestamp,
    required this.formattedDate,
    required this.formattedTime,
    required this.pair,
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
    required this.bias,
    required this.diff,
    this.type = 'pivot',
  });
}

// Produk yang bisa dipilih di kalkulator
class _PivotProduct {
  final String label; // XUL / HKK / JPK
  final String subtitle;
  final String nmSymbol; // simbol Newsmaker (data live)
  final String tvSymbol; // simbol TradingView (grafik)
  final String yahooSymbol; // sumber High/Low/Close kemarin (mode otomatis)
  final String unit; // satuan harga
  final int decimals;
  final IconData icon;

  const _PivotProduct({
    required this.label,
    required this.subtitle,
    required this.nmSymbol,
    required this.tvSymbol,
    required this.yahooSymbol,
    required this.unit,
    required this.decimals,
    required this.icon,
  });
}

// Rincian langkah hitung satu level (dipakai di bottom sheet)
class _LevelDetail {
  final String title;
  final String formula;
  final List<String> steps;
  final double value;
  final Color color;
  final String note;

  const _LevelDetail({
    required this.title,
    required this.formula,
    required this.steps,
    required this.value,
    required this.color,
    required this.note,
  });
}

class PivotCalculator extends StatefulWidget {
  final VoidCallback onBack;
  final Function(PivotCalculation calc) onSaveHistory;
  final Function(PivotCalculation calc) onOpenDetailModal;
  final PivotCalculation? initialValues;

  const PivotCalculator({
    super.key,
    required this.onBack,
    required this.onSaveHistory,
    required this.onOpenDetailModal,
    this.initialValues,
  });

  @override
  State<PivotCalculator> createState() => _PivotCalculatorState();
}

class _PivotCalculatorState extends State<PivotCalculator> {
  static const String _quoteUrl = 'https://www.newsmaker.id/api/live-quotes';
  static const Color _buyColor = Color(0xFF059669);
  static const Color _sellColor = Color(0xFFE11D48);
  static const Color _neutralColor = Color(0xFF64748B);

  static const List<_PivotProduct> _products = [
    _PivotProduct(
      label: 'XUL',
      subtitle: 'Gold / USD',
      nmSymbol: 'XUL10',
      tvSymbol: 'OANDA:XAUUSD',
      yahooSymbol: 'GC=F',
      unit: 'USD',
      decimals: 2,
      icon: Icons.monetization_on_rounded,
    ),
    _PivotProduct(
      label: 'HKK',
      subtitle: 'Hang Seng',
      nmSymbol: 'HKK50_BBJ',
      tvSymbol: 'OANDA:HK33HKD',
      yahooSymbol: '^HSI',
      unit: 'poin',
      decimals: 0,
      icon: Icons.bar_chart_rounded,
    ),
    _PivotProduct(
      label: 'JPK',
      subtitle: 'Nikkei 225',
      nmSymbol: 'JPK50_BBJ',
      tvSymbol: 'OANDA:JP225USD',
      yahooSymbol: '^N225',
      unit: 'poin',
      decimals: 0,
      icon: Icons.show_chart_rounded,
    ),
  ];

  late TextEditingController _highController;
  late TextEditingController _lowController;
  late TextEditingController _closeController;
  late TextEditingController _openController;

  int _productIndex = 0;
  PivotCalculation? _result;
  double? _resultOpen; // Open yang dipakai saat tombol Hitung ditekan

  bool _showFormula = true;
  bool _savedSuccess = false;

  // Mode input: otomatis (data kemarin diambil sendiri) atau manual
  bool _autoMode = true;
  bool _loadingPrev = false;
  String? _prevError;
  String _prevInfo = '';

  // Data Open live
  bool _loadingOpen = false;
  bool _openError = false;
  String _liveTime = '';

  _PivotProduct get _product => _products[_productIndex];
  String get _unit => _product.unit;

  @override
  void initState() {
    super.initState();
    final init = widget.initialValues;
    _highController =
        TextEditingController(text: init != null ? _f(init.high) : '');
    _lowController =
        TextEditingController(text: init != null ? _f(init.low) : '');
    _closeController =
        TextEditingController(text: init != null ? _f(init.close) : '');
    _openController = TextEditingController();

    if (init != null) {
      final idx = _products.indexWhere((p) => p.label == init.pair);
      if (idx >= 0) _productIndex = idx;
    }

    // Kalau dibuka dari riwayat (hitung ulang), pakai mode manual
    _autoMode = init == null;

    _fetchOpen();
    if (_autoMode) _loadPrevDay();
  }

  @override
  void dispose() {
    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();
    _openController.dispose();
    super.dispose();
  }

  // ---------- Helper ----------

  String _f(double v) => v.toStringAsFixed(2);
  String _signed(double v) => v >= 0 ? '+${_f(v)}' : _f(v);
  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Data live (Open hari ini) ----------

  Future<void> _fetchOpen() async {
    final product = _product;
    setState(() {
      _loadingOpen = true;
      _openError = false;
    });

    try {
      final res = await http
          .get(Uri.parse(_quoteUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        throw Exception('status ${res.statusCode}');
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? [];

      Map<String, dynamic>? quote;
      for (final e in list) {
        if (e is Map<String, dynamic> &&
            (e['symbol'] ?? '').toString() == product.nmSymbol) {
          quote = e;
          break;
        }
      }

      final double? open =
          quote == null ? null : double.tryParse(quote['open'].toString());

      if (!mounted) return;
      // Abaikan hasil kalau user sudah pindah produk saat menunggu
      if (product.label != _product.label) return;

      setState(() {
        _loadingOpen = false;
        if (open != null) {
          _openController.text = open.toStringAsFixed(product.decimals);
          _liveTime = (quote?['time'] ?? '').toString();
          _openError = false;
        } else {
          _openError = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      if (product.label != _product.label) return;
      setState(() {
        _loadingOpen = false;
        _openError = true;
      });
    }
  }

  // ---------- Data kemarin (High/Low/Close) untuk mode otomatis ----------

  Future<void> _loadPrevDay() async {
    final product = _product;
    setState(() {
      _loadingPrev = true;
      _prevError = null;
    });
    try {
      final d = await PrevDayService.fetch(product.yahooSymbol);
      if (!mounted || product.label != _product.label) return;
      setState(() {
        _highController.text = d.high.toStringAsFixed(2);
        _lowController.text = d.low.toStringAsFixed(2);
        _closeController.text = d.close.toStringAsFixed(2);
        _prevInfo = 'Data kemarin (${d.date}) dari Yahoo Finance';
        _loadingPrev = false;
      });
    } catch (_) {
      if (!mounted || product.label != _product.label) return;
      setState(() {
        _loadingPrev = false;
        _prevError =
            'Gagal ambil data kemarin. Coba lagi atau pindah ke mode Manual.';
      });
    }
  }

  void _selectProduct(int index) {
    if (index == _productIndex) return;
    setState(() {
      _productIndex = index;
      _highController.clear();
      _lowController.clear();
      _closeController.clear();
      _openController.clear();
      _liveTime = '';
      _prevInfo = '';
      _prevError = null;
      _result = null;
      _savedSuccess = false;
    });
    _fetchOpen();
    if (_autoMode) _loadPrevDay();
  }

  void _handleReset() {
    setState(() {
      _highController.clear();
      _lowController.clear();
      _closeController.clear();
      _result = null;
    });
    if (_autoMode) _loadPrevDay();
  }

  // ---------- Perhitungan ----------

  PivotCalculation _calculate(double high, double low, double close) {
    final double pp = double.parse(((high + low + close) / 3).toStringAsFixed(2));
    final double r1 = double.parse(((2 * pp) - low).toStringAsFixed(2));
    final double s1 = double.parse(((2 * pp) - high).toStringAsFixed(2));
    final double r2 = double.parse((pp + (high - low)).toStringAsFixed(2));
    final double s2 = double.parse((pp - (high - low)).toStringAsFixed(2));
    final double r3 = double.parse((pp + (high - low) * 2).toStringAsFixed(2));
    final double s3 = double.parse((pp - (high - low) * 2).toStringAsFixed(2));
    final double r4 = double.parse((pp + (high - low) * 3).toStringAsFixed(2));
    final double s4 = double.parse((pp - (high - low) * 3).toStringAsFixed(2));

    final double diff = double.parse((close - pp).toStringAsFixed(2));
    final String bias =
        diff > 0.5 ? 'bullish' : (diff < -0.5 ? 'bearish' : 'sideway');

    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final String formattedDate =
        '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
    final String formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return PivotCalculation(
      id: 'pivot-${now.millisecondsSinceEpoch}',
      timestamp: now.toIso8601String(),
      formattedDate: formattedDate,
      formattedTime: formattedTime,
      pair: _product.label,
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
      bias: bias,
      diff: diff,
    );
  }

  Future<void> _handleCalculate() async {
    FocusScope.of(context).unfocus();

    // Mode otomatis: segarkan data kemarin dan Open dulu, baru hitung
    if (_autoMode) {
      await Future.wait([_loadPrevDay(), _fetchOpen()]);
      if (!mounted) return;
    }

    final double? high = _parse(_highController.text);
    final double? low = _parse(_lowController.text);
    final double? close = _parse(_closeController.text);

    if (high == null || low == null || close == null) {
      _snack(_autoMode
          ? 'Data kemarin belum berhasil diambil. Coba lagi atau pakai mode Manual.'
          : 'Isi High, Low, dan Close kemarin dengan angka yang valid.');
      return;
    }
    if (high < low) {
      _snack('High tidak boleh lebih kecil dari Low.');
      return;
    }

    setState(() {
      _result = _calculate(high, low, close);
      _resultOpen = _parse(_openController.text);
      _savedSuccess = false;
    });
  }

  // Salinan hasil hitung untuk Riwayat: field bias diisi sinyal BUY/SELL
  // (PP dibanding Open hari ini). Kalau Open belum ada, bias = 'none'
  // sehingga badge di Riwayat tidak ditampilkan.
  PivotCalculation _withSignal(PivotCalculation c) {
    final double? open = _resultOpen;
    final String signal = open == null
        ? 'none'
        : (c.pp > open ? 'buy' : (c.pp < open ? 'sell' : 'netral'));

    return PivotCalculation(
      id: c.id,
      timestamp: c.timestamp,
      formattedDate: c.formattedDate,
      formattedTime: c.formattedTime,
      pair: c.pair,
      high: c.high,
      low: c.low,
      close: c.close,
      pp: c.pp,
      r1: c.r1,
      r2: c.r2,
      r3: c.r3,
      r4: c.r4,
      s1: c.s1,
      s2: c.s2,
      s3: c.s3,
      s4: c.s4,
      bias: signal,
      diff: c.diff,
    );
  }

  void _handleSave() async {
    final calc = _result;
    if (calc == null) return;
    final saved = _withSignal(calc);

    // Simpan ke cloud (per akun): tetap ada setelah logout & terlihat di semua HP
    HistoryStorage.save(
      id: saved.id,
      type: 'pivot',
      formattedDate: saved.formattedDate,
      formattedTime: saved.formattedTime,
      pair: saved.pair,
      bias: saved.bias,
      pp: saved.pp,
      r1: saved.r1,
      s1: saved.s1,
    );

    widget.onSaveHistory(saved);
    setState(() {
      _savedSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      setState(() {
        _savedSuccess = false;
      });
    }
  }

  // Baris untuk dibagikan / dicetak
  List<MapEntry<String, String>> _shareRows(PivotCalculation c) {
    final double? open = _resultOpen;
    final String signal = open == null
        ? '-'
        : (c.pp > open ? 'BUY' : (c.pp < open ? 'SELL' : 'NETRAL'));
    return [
      MapEntry('Produk', '${_product.label} (${_product.subtitle})'),
      MapEntry('Tanggal', '${c.formattedDate} ${c.formattedTime}'),
      if (open != null) MapEntry('Open hari ini', _f(open)),
      MapEntry('Sinyal', signal),
      const MapEntry('Data kemarin', ''),
      MapEntry('High', _f(c.high)),
      MapEntry('Low', _f(c.low)),
      MapEntry('Close', _f(c.close)),
      const MapEntry('Level Pivot', ''),
      MapEntry('R4', _f(c.r4)),
      MapEntry('R3', _f(c.r3)),
      MapEntry('R2', _f(c.r2)),
      MapEntry('R1', _f(c.r1)),
      MapEntry('PP', _f(c.pp)),
      MapEntry('S1', _f(c.s1)),
      MapEntry('S2', _f(c.s2)),
      MapEntry('S3', _f(c.s3)),
      MapEntry('S4', _f(c.s4)),
    ];
  }

  // ---------- Rincian langkah hitung (bisa diketuk) ----------

  _LevelDetail _detailFor(String key, PivotCalculation c, Color primaryColor) {
    const Color supportColor = Color(0xFF047857);
    final double h = c.high;
    final double l = c.low;
    final double cl = c.close;
    final double pp = c.pp;
    final double range = h - l;

    switch (key) {
      case 'PP':
        return _LevelDetail(
          title: 'Pivot Point (PP)',
          formula: 'PP = (High + Low + Close) / 3',
          steps: [
            '= (${_f(h)} + ${_f(l)} + ${_f(cl)}) / 3',
            '= ${_f(h + l + cl)} / 3',
          ],
          value: pp,
          color: primaryColor,
          note:
              'Harga wajar / rata-rata dari High, Low, dan Close hari kemarin. Jika PP di atas harga open hari ini = Buy, jika PP di bawah harga open = Sell.',
        );
      case 'R1':
        return _LevelDetail(
          title: 'R1 Minor',
          formula: 'R1 = (2 × PP) - Low',
          steps: [
            '= (2 × ${_f(pp)}) - ${_f(l)}',
            '= ${_f(2 * pp)} - ${_f(l)}',
          ],
          value: c.r1,
          color: primaryColor,
          note: 'Resistance minor: level pertama di atas PP.',
        );
      case 'R2':
        return _LevelDetail(
          title: 'R2 Moderat',
          formula: 'R2 = PP + (High - Low)',
          steps: [
            '= ${_f(pp)} + (${_f(h)} - ${_f(l)})',
            '= ${_f(pp)} + ${_f(range)}',
          ],
          value: c.r2,
          color: primaryColor,
          note: 'Resistance moderat: level kedua di atas PP.',
        );
      case 'R3':
        return _LevelDetail(
          title: 'R3 Kuat',
          formula: 'R3 = PP + (High - Low) × 2',
          steps: [
            '= ${_f(pp)} + (${_f(h)} - ${_f(l)}) × 2',
            '= ${_f(pp)} + ${_f(range)} × 2',
            '= ${_f(pp)} + ${_f(range * 2)}',
          ],
          value: c.r3,
          color: primaryColor,
          note: 'Resistance kuat: level ketiga di atas PP.',
        );
      case 'R4':
        return _LevelDetail(
          title: 'R4 Ekstrem',
          formula: 'R4 = PP + (High - Low) × 3',
          steps: [
            '= ${_f(pp)} + (${_f(h)} - ${_f(l)}) × 3',
            '= ${_f(pp)} + ${_f(range)} × 3',
            '= ${_f(pp)} + ${_f(range * 3)}',
          ],
          value: c.r4,
          color: primaryColor,
          note: 'Resistance ekstrem: level paling jauh di atas PP.',
        );
      case 'S1':
        return _LevelDetail(
          title: 'S1 Minor',
          formula: 'S1 = (2 × PP) - High',
          steps: [
            '= (2 × ${_f(pp)}) - ${_f(h)}',
            '= ${_f(2 * pp)} - ${_f(h)}',
          ],
          value: c.s1,
          color: supportColor,
          note: 'Support minor: level pertama di bawah PP.',
        );
      case 'S2':
        return _LevelDetail(
          title: 'S2 Moderat',
          formula: 'S2 = PP - (High - Low)',
          steps: [
            '= ${_f(pp)} - (${_f(h)} - ${_f(l)})',
            '= ${_f(pp)} - ${_f(range)}',
          ],
          value: c.s2,
          color: supportColor,
          note: 'Support moderat: level kedua di bawah PP.',
        );
      case 'S3':
        return _LevelDetail(
          title: 'S3 Kuat',
          formula: 'S3 = PP - (High - Low) × 2',
          steps: [
            '= ${_f(pp)} - (${_f(h)} - ${_f(l)}) × 2',
            '= ${_f(pp)} - ${_f(range)} × 2',
            '= ${_f(pp)} - ${_f(range * 2)}',
          ],
          value: c.s3,
          color: supportColor,
          note: 'Support kuat: level ketiga di bawah PP.',
        );
      default: // S4
        return _LevelDetail(
          title: 'S4 Ekstrem',
          formula: 'S4 = PP - (High - Low) × 3',
          steps: [
            '= ${_f(pp)} - (${_f(h)} - ${_f(l)}) × 3',
            '= ${_f(pp)} - ${_f(range)} × 3',
            '= ${_f(pp)} - ${_f(range * 3)}',
          ],
          value: c.s4,
          color: supportColor,
          note: 'Support ekstrem: level paling jauh di bawah PP.',
        );
    }
  }

  void _showLevelDetail(String key, PivotCalculation calc, Color primaryColor) {
    final d = _detailFor(key, calc, primaryColor);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${d.title} • ${_product.label}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            size: 22, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'RUMUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    d.formula,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'LANGKAH HITUNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final step in d.steps)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            step,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '= ${_f(d.value)} $_unit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: d.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _f(d.value),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: d.color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _unit,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF515F74),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    if (key != 'PP')
                      Expanded(
                        child: _buildSheetMetric(
                          'Selisih dari PP',
                          _signed(d.value - calc.pp),
                        ),
                      ),
                    Expanded(
                      child: _buildSheetMetric(
                        'Selisih dari Close',
                        _signed(d.value - calc.close),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  d.note,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: _f(d.value)));
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!mounted) return;
                          _snack('${d.title} disalin: ${_f(d.value)}');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Hasil'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: d.color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final PivotCalculation? calc = _result;

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
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          size: 18, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Header
          const Text(
            'Pivot Point Calculator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pilih produk, lalu tekan Hitung. Mode Otomatis mengisi data sendiri, mode Manual bisa kamu isi sendiri.',
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
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(p.icon,
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF64748B)),
                          const SizedBox(height: 4),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            p.subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // SECTION 1: INPUT DATA HARGA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Input Harga',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '${_product.label} • ${_product.subtitle}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF515F74),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),

                // Pilihan mode: Otomatis / Manual
                _buildModeToggle(primaryColor),
                const SizedBox(height: 12),

                _buildInputField('High Kemarin (Tertinggi)', 'H',
                    _highController, Icons.arrow_upward_rounded, primaryColor),
                const SizedBox(height: 12),
                _buildInputField('Low Kemarin (Terendah)', 'L', _lowController,
                    Icons.arrow_downward_rounded, primaryColor),
                const SizedBox(height: 12),
                _buildInputField('Close Kemarin (Penutupan)', 'C',
                    _closeController, Icons.flag_rounded, primaryColor),
                const SizedBox(height: 6),
                _buildPrevStatus(),
                const SizedBox(height: 6),
                _buildInputField('Open Hari Ini', 'O', _openController,
                    Icons.login_rounded, primaryColor),
                const SizedBox(height: 6),
                _buildOpenStatus(primaryColor),
                const SizedBox(height: 14),

                // Tombol Hitung
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_loadingPrev || _loadingOpen)
                        ? null
                        : _handleCalculate,
                    icon: (_loadingPrev || _loadingOpen)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.calculate_rounded, size: 18),
                    label: Text(
                        (_loadingPrev || _loadingOpen) ? 'Memuat data...' : 'Hitung'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primaryColor.withValues(alpha: 0.6),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _handleReset,
                      child: Row(
                        children: const [
                          Icon(Icons.restart_alt_rounded,
                              size: 16, color: Color(0xFF515F74)),
                          SizedBox(width: 4),
                          Text(
                            'Reset Nilai',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF515F74),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showFormula = !_showFormula;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(Icons.functions_rounded,
                              size: 16, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            _showFormula ? 'Tutup Rumus' : 'Lihat Rumus',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
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

          // SECTION 2: PROSES & RUMUS PERHITUNGAN (bisa diketuk)
          if (_showFormula) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 18, color: primaryColor),
                          const SizedBox(width: 6),
                          const Text(
                            'Formula Baku Classical Floor',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Langkah Matematis',
                        style: TextStyle(fontSize: 11, color: Color(0xFF515F74)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.touch_app_outlined,
                          size: 14, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Ketuk rumus untuk melihat langkah hitungnya (setelah tombol Hitung ditekan).',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Kotak PP
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          if (calc == null) {
                            _snack('Tekan Hitung dulu untuk melihat langkahnya.');
                          } else {
                            _showLevelDetail('PP', calc, primaryColor);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Titik Pivot Inti (PP):',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF515F74)),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'PP = (High + Low + Close) / 3',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (calc != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '= (${_f(calc.high)} + ${_f(calc.low)} + ${_f(calc.close)}) / 3 = ${_f(calc.pp)} $_unit',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF515F74),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormulaTile('R1', 'R1 = (2 × PP) - Low',
                                    calc, primaryColor),
                                _buildFormulaTile('S1', 'S1 = (2 × PP) - High',
                                    calc, primaryColor),
                                _buildFormulaTile('R2', 'R2 = PP + (High - Low)',
                                    calc, primaryColor),
                                _buildFormulaTile('S2', 'S2 = PP - (High - Low)',
                                    calc, primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormulaTile(
                                    'R3',
                                    'R3 = PP + (High - Low) × 2',
                                    calc,
                                    primaryColor),
                                _buildFormulaTile(
                                    'S3',
                                    'S3 = PP - (High - Low) × 2',
                                    calc,
                                    primaryColor),
                                _buildFormulaTile(
                                    'R4',
                                    'R4 = PP + (High - Low) × 3',
                                    calc,
                                    primaryColor),
                                _buildFormulaTile(
                                    'S4',
                                    'S4 = PP - (High - Low) × 3',
                                    calc,
                                    primaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // SECTION 3: SINYAL + HASIL PERHITUNGAN
          if (calc == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.calculate_outlined,
                      size: 32, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada hasil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tekan Hitung untuk melihat level pivot dan sinyal Buy/Sell.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else ...[
            _buildSignalCard(calc, primaryColor),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HASIL PIVOT POINT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF515F74),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'STANDARD PIVOT POINT (PP)',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF515F74)),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: () =>
                                _showLevelDetail('PP', calc, primaryColor),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _f(calc.pp),
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _unit,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF515F74)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Harga penutupan ${_f(calc.close)} berada ${calc.diff >= 0 ? "di atas" : "di bawah"} Pivot Point (${_signed(calc.diff)}).',
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xFF515F74)),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.touch_app_outlined,
                                size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Ketuk PP atau level R/S untuk melihat langkah hitungnya.',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Level Grid
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(
                        top: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.north_east_rounded,
                                      size: 15, color: primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Resistance (Jual)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildLevelCard('R4 Ekstrem', calc.r4,
                                  () => _showLevelDetail('R4', calc, primaryColor)),
                              const SizedBox(height: 6),
                              _buildLevelCard('R3 Kuat', calc.r3,
                                  () => _showLevelDetail('R3', calc, primaryColor)),
                              const SizedBox(height: 6),
                              _buildLevelCard('R2 Moderat', calc.r2,
                                  () => _showLevelDetail('R2', calc, primaryColor)),
                              const SizedBox(height: 6),
                              _buildLevelCard('R1 Minor', calc.r1,
                                  () => _showLevelDetail('R1', calc, primaryColor)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.south_east_rounded,
                                      size: 15, color: Color(0xFF047857)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Support (Beli)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildLevelCard('S1 Minor', calc.s1,
                                  () => _showLevelDetail('S1', calc, primaryColor)),
                              const SizedBox(height: 6),
                              _buildLevelCard('S2 Moderat', calc.s2,
                                  () => _showLevelDetail('S2', calc, primaryColor)),
                              const SizedBox(height: 6),
                              _buildLevelCard('S3 Kuat', calc.s3,
                                  () => _showLevelDetail('S3', calc, primaryColor)),
                              const SizedBox(height: 6),
                              _buildLevelCard('S4 Ekstrem', calc.s4,
                                  () => _showLevelDetail('S4', calc, primaryColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Actions
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: Icon(
                          _savedSuccess
                              ? Icons.check_circle_rounded
                              : Icons.bookmark_add_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _savedSuccess
                              ? 'Tersimpan di Riwayat!'
                              : 'Simpan ke Riwayat',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _savedSuccess
                              ? const Color(0xFF059669)
                              : primaryColor,
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
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Bagikan / cetak hasil
          if (calc != null) ...[
            ResultActions(
              title: 'Pivot Point ${_product.label}',
              rows: _shareRows(calc),
              color: primaryColor,
            ),
            const SizedBox(height: 12),
          ],

          // SECTION 4: KONSEP TRANSAKSI
          _buildKonsepTransaksi(),
        ],
      ),
    );
  }

  // ---------- Widget bantu ----------

  // Pilihan mode input: Otomatis / Manual
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
            if (auto) {
              _loadPrevDay();
              _fetchOpen();
            }
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
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

  Widget _buildPrevStatus() {
    if (!_autoMode) return const SizedBox.shrink();
    String text;
    Color color = const Color(0xFF94A3B8);
    if (_loadingPrev) {
      text = 'Mengambil data kemarin...';
    } else if (_prevError != null) {
      text = _prevError!;
      color = const Color(0xFF9A3412);
    } else if (_prevInfo.isNotEmpty) {
      text = _prevInfo;
    } else {
      text = 'High/Low/Close kemarin diambil otomatis.';
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _buildOpenStatus(Color primaryColor) {
    String text;
    Color color = const Color(0xFF94A3B8);
    if (_loadingOpen) {
      text = 'Mengambil Open live...';
    } else if (_openError) {
      text = 'Gagal mengambil Open live. Isi manual atau coba lagi.';
      color = const Color(0xFF9A3412);
    } else if (_liveTime.isNotEmpty) {
      text = 'Open live dari Newsmaker • $_liveTime';
    } else {
      text = 'Open hari ini diambil otomatis, bisa diubah di mode Manual.';
    }

    return Row(
      children: [
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11, color: color)),
        ),
        InkWell(
          onTap: _loadingOpen ? null : _fetchOpen,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded,
                    size: 15,
                    color: _loadingOpen ? const Color(0xFF94A3B8) : primaryColor),
                const SizedBox(width: 3),
                Text(
                  'Perbarui',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _loadingOpen ? const Color(0xFF94A3B8) : primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Kartu sinyal Buy / Sell: PP dibanding Open hari ini
  Widget _buildSignalCard(PivotCalculation calc, Color primaryColor) {
    final double? open = _resultOpen;

    if (open == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Open hari ini belum terisi. Tekan Perbarui (atau isi manual), lalu tekan Hitung lagi untuk melihat sinyal Buy/Sell.',
                style: TextStyle(
                    fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final String signal =
        calc.pp > open ? 'BUY' : (calc.pp < open ? 'SELL' : 'NETRAL');
    final Color color = signal == 'BUY'
        ? _buyColor
        : (signal == 'SELL' ? _sellColor : _neutralColor);
    final String relation = calc.pp > open
        ? 'di atas'
        : (calc.pp < open ? 'di bawah' : 'sama dengan');

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
              const Text(
                'SINYAL PIVOT POINT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF515F74),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  signal,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'PP ${_f(calc.pp)} berada $relation Open ${_f(open)} (${_product.label}).',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aturan: PP di atas harga open hari ini = Buy, PP di bawah harga open = Sell.',
            style: TextStyle(
                fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaTile(
      String key, String text, PivotCalculation? calc, Color primaryColor) {
    return InkWell(
      onTap: () {
        if (calc == null) {
          _snack('Tekan Hitung dulu untuk melihat langkahnya.');
        } else {
          _showLevelDetail(key, calc, primaryColor);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            height: 1.3,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildKonsepTransaksi() {
    return Container(
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
          _buildConceptItem(
            title: 'Pivot Point',
            description:
                'Harga wajar atau harga pasaran untuk menentukan aksi beli dan jual, mengacu pada harga pembukaan (open).',
            rules: [
              _buildRuleRow('Open < Pivot Point', 'BUY', _buyColor),
              _buildRuleRow('Open > Pivot Point', 'SELL', _sellColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConceptItem({
    required String title,
    required String description,
    required List<Widget> rules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        ...rules,
      ],
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
          readOnly: _autoMode, // terkunci di mode otomatis
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            // Hasil lama tidak berlaku lagi, perlu tekan Hitung ulang
            if (_result != null) {
              setState(() {
                _result = null;
              });
            }
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCBD5E1)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            suffixText: _unit,
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

  Widget _buildLevelCard(String label, double val, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF515F74))),
                Text(
                  _f(val),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}