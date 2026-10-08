import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// Model riwayat perhitungan (dipakai file lain, jangan diubah)
class HistoryItem {
  final String id;
  final String type; // 'pivot', 'gold', 'nest', atau 'history_closing'
  final String formattedDate;
  final String formattedTime;
  final String? pair;
  final String? bias;
  final double? pp;
  final double? r1;
  final double? s1;
  final double? weight;
  final String? purityLabel;
  final double? grandTotal;
  final String? title;
  final String? description;
  final String? link;

  HistoryItem({
    required this.id,
    required this.type,
    required this.formattedDate,
    required this.formattedTime,
    this.pair,
    this.bias,
    this.pp,
    this.r1,
    this.s1,
    this.weight,
    this.purityLabel,
    this.grandTotal,
    this.title,
    this.description,
    this.link,
  });
}

// ---------- Model data histori Newsmaker ----------
class _Cat {
  final String label;
  final String apiName;
  final int decimals;
  const _Cat(this.label, this.apiName, this.decimals);
}

const List<_Cat> _cats = [
  _Cat('Emas', 'LGD Daily', 2),
  _Cat('Hang Seng', 'HSI Daily', 0),
  _Cat('Nikkei', 'SNI Daily', 0),
];

class _HRow {
  final String category;
  final DateTime date;
  final double? open, high, low, close;
  final bool isHoliday;
  final String? holidayName;

  _HRow({
    required this.category,
    required this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.isHoliday = false,
    this.holidayName,
  });

  double? get changePct => (open != null && close != null && open != 0)
      ? (close! - open!) / open! * 100
      : null;
}

class HistoryScreen extends StatefulWidget {
  final List<HistoryItem> historyItems;
  final Function(String id) onDeleteHistory;
  final Function(HistoryItem item) onRecalculate;
  final Function(HistoryItem item) onOpenDetailModal;

  const HistoryScreen({
    super.key,
    required this.historyItems,
    required this.onDeleteHistory,
    required this.onRecalculate,
    required this.onOpenDetailModal,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String _url = 'https://www.newsmaker.id/api/historical-data';
  static const Color _green = Color(0xFF059669);

  final DateFormat _uiFmt = DateFormat('dd/MM/yyyy');

  // Tab aktif: 'all', 'pivot', 'gold', 'nest', 'market'
  String _tab = 'all';

  // Data Newsmaker
  List<_HRow> _all = [];
  bool _loading = false;
  bool _marketLoaded = false;
  String? _error;

  _Cat _cat = _cats[0];
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = _end.subtract(const Duration(days: 7));
  }

  void _selectTab(String id) {
    setState(() => _tab = id);
    if (id == 'market' && !_marketLoaded && !_loading) {
      _load();
    }
  }

  // ---------- Riwayat perhitungan ----------
  List<HistoryItem> get _calcItems => widget.historyItems
      .where((i) => i.type != 'history_closing')
      .toList();

  List<HistoryItem> get _filteredCalc {
    final items = _calcItems;
    if (_tab == 'all') return items;
    return items.where((i) => i.type == _tab).toList();
  }

  // ---------- Ambil data Newsmaker ----------
  static double? _d(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse(_url),
          headers: {'Accept': 'application/json'}).timeout(
        const Duration(seconds: 30),
      );
      if (res.statusCode != 200) {
        throw Exception('Server error ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? [];

      final allowed = _cats.map((c) => c.apiName).toSet();
      final map = <String, _HRow>{};

      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final cat = e['category']?.toString() ?? '';
        if (!allowed.contains(cat)) continue;

        final date = DateTime.tryParse(e['tanggal']?.toString() ?? '');
        if (date == null || date.year < 2000) continue;

        map['$cat|${date.year}-${date.month}-${date.day}'] = _HRow(
          category: cat,
          date: DateTime(date.year, date.month, date.day),
          open: _d(e['open']),
          high: _d(e['high']),
          low: _d(e['low']),
          close: _d(e['close']),
          isHoliday: e['isBankHoliday'] == true,
          holidayName: e['description']?.toString(),
        );
      }

      if (!mounted) return;
      setState(() {
        _all = map.values.toList();
        _loading = false;
        _marketLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat data histori. Periksa koneksi lalu tekan Refresh.';
      });
    }
  }

  List<_HRow> get _rows {
    final list = _all.where((r) {
      if (r.category != _cat.apiName) return false;
      if (r.date.isBefore(_start)) return false;
      if (r.date.isAfter(_end)) return false;
      return true;
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  String _fmt(double? v, int decimals) {
    if (v == null) return '-';
    final negative = v < 0;
    final parts = v.abs().toStringAsFixed(decimals).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    final result = parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
    return negative ? '-$result' : result;
  }

  String _rupiah(double v) =>
      'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  String _pct(double? v) {
    if (v == null) return '-';
    final s = v.toStringAsFixed(2).replaceAll('.', ',');
    return v > 0 ? '+$s%' : '$s%';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    final d = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      if (isStart) {
        _start = d;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = d;
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  // ---------- Unduh CSV / PDF ----------
  String get _fileBase =>
      'histori_${_cat.label.toLowerCase().replaceAll(' ', '_')}_'
      '${DateFormat('yyyyMMdd').format(_start)}-${DateFormat('yyyyMMdd').format(_end)}';

  Future<void> _exportCsv() async {
    final rows = _rows;
    if (rows.isEmpty) {
      _toast('Tidak ada data untuk diunduh.');
      return;
    }
    try {
      final d = _cat.decimals;
      final sb = StringBuffer('Tanggal,Open,High,Low,Close,Perubahan %\n');
      for (final r in rows) {
        final tgl = DateFormat('yyyy-MM-dd').format(r.date);
        if (r.isHoliday) {
          sb.writeln('$tgl,Libur,,,,');
        } else {
          sb.writeln('$tgl,'
              '${r.open?.toStringAsFixed(d) ?? ''},'
              '${r.high?.toStringAsFixed(d) ?? ''},'
              '${r.low?.toStringAsFixed(d) ?? ''},'
              '${r.close?.toStringAsFixed(d) ?? ''},'
              '${r.changePct?.toStringAsFixed(2) ?? ''}');
        }
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileBase.csv');
      await file.writeAsString(sb.toString());
      await Share.shareXFiles([XFile(file.path)],
          text: 'Data historis ${_cat.label}');
    } catch (e) {
      _toast('Gagal membuat CSV.');
    }
  }

  Future<void> _exportPdf() async {
    final rows = _rows;
    if (rows.isEmpty) {
      _toast('Tidak ada data untuk diunduh.');
      return;
    }
    try {
      final d = _cat.decimals;
      final doc = pw.Document();

      pw.Widget cell(String t, {bool bold = false, pw.Alignment? al}) =>
          pw.Container(
            alignment: al ?? pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(
              t,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          );

      final tableRows = <pw.TableRow>[
        pw.TableRow(
          children: [
            cell('Tanggal', bold: true, al: pw.Alignment.centerLeft),
            cell('Open', bold: true),
            cell('High', bold: true),
            cell('Low', bold: true),
            cell('Close', bold: true),
            cell('Perubahan', bold: true),
          ],
        ),
        for (final r in rows)
          pw.TableRow(
            children: [
              cell(_uiFmt.format(r.date), al: pw.Alignment.centerLeft),
              cell(r.isHoliday ? 'Libur' : _fmt(r.open, d)),
              cell(r.isHoliday ? '-' : _fmt(r.high, d)),
              cell(r.isHoliday ? '-' : _fmt(r.low, d)),
              cell(r.isHoliday ? '-' : _fmt(r.close, d)),
              cell(r.isHoliday ? '-' : _pct(r.changePct)),
            ],
          ),
      ];

      doc.addPage(
        pw.MultiPage(
          build: (ctx) => [
            pw.Text('Data Historis ${_cat.label}',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              'Periode ${_uiFmt.format(_start)} - ${_uiFmt.format(_end)}  |  Sumber: Newsmaker',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: tableRows,
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileBase.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Data historis ${_cat.label}');
    } catch (e) {
      _toast('Gagal membuat PDF.');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ======================= UI =======================
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isMarket = _tab == 'market';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMarket ? 'Data Historis' : 'Riwayat Perhitungan',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isMarket
                ? (_loading
                    ? 'Memuat data dari Newsmaker...'
                    : '${_rows.length} baris | Sumber: Newsmaker')
                : 'Daftar kalkulasi pivot point, emas fisik, dan nest yang tersimpan secara lokal.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Tab
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabChip('all', 'Semua', primaryColor,
                    count: _calcItems.length),
                const SizedBox(width: 6),
                _tabChip('pivot', 'Pivot Point', primaryColor,
                    icon: Icons.show_chart_rounded),
                const SizedBox(width: 6),
                _tabChip('gold', 'Emas Fisik', primaryColor,
                    icon: Icons.view_in_ar_rounded),
                const SizedBox(width: 6),
                _tabChip('nest', 'Nest', primaryColor,
                    icon: Icons.layers_rounded),
                const SizedBox(width: 6),
                _tabChip('market', 'Data Pasar', primaryColor,
                    icon: Icons.candlestick_chart_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isMarket)
            _buildMarketSection(primaryColor)
          else
            _buildCalcSection(primaryColor),
        ],
      ),
    );
  }

  // ---------- Isi tab perhitungan ----------
  Widget _buildCalcSection(Color primaryColor) {
    final items = _filteredCalc;
    if (items.isEmpty) {
      return _messageBox(
        Icons.folder_open_rounded,
        'Belum Ada Riwayat',
        'Hasil kalkulasi pivot point, emas fisik, atau nest yang Anda simpan akan muncul di sini.',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.type == 'pivot') return _buildPivotCard(item, primaryColor);
        if (item.type == 'gold') return _buildGoldCard(item, primaryColor);
        return _buildGenericCard(item, 'Nest', Icons.layers_rounded, primaryColor);
      },
    );
  }

  // ---------- Isi tab Data Pasar ----------
  Widget _buildMarketSection(Color primaryColor) {
    final rows = _rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < _cats.length; i++) ...[
              Expanded(child: _catChip(_cats[i], primaryColor)),
              if (i != _cats.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: _dateField(
                    'Mulai', _start, () => _pickDate(isStart: true))),
            const SizedBox(width: 10),
            Expanded(
                child: _dateField(
                    'Akhir', _end, () => _pickDate(isStart: false))),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _exportCsv,
                icon: Icon(Icons.table_chart_outlined,
                    size: 18, color: primaryColor),
                label: Text('Unduh CSV', style: TextStyle(color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _exportPdf,
                icon: Icon(Icons.picture_as_pdf_outlined,
                    size: 18, color: primaryColor),
                label: Text('Unduh PDF', style: TextStyle(color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _messageBox(Icons.wifi_off_rounded, 'Gagal Memuat', _error!)
        else if (rows.isEmpty)
          _messageBox(
            Icons.folder_open_rounded,
            'Tidak Ada Data',
            'Tidak ada data ${_cat.label} pada rentang tanggal ini. Coba perlebar tanggal Mulai.',
          )
        else
          _buildTable(rows, primaryColor),
      ],
    );
  }

  // ---------- Widget kecil ----------
  Widget _tabChip(String id, String label, Color primaryColor,
      {IconData? icon, int? count}) {
    final active = _tab == id;
    return InkWell(
      onTap: () => _selectTab(id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? primaryColor : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: active ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF64748B))),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            active ? Colors.white : const Color(0xFF475569))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _catChip(_Cat c, Color primaryColor) {
    final active = c.apiName == _cat.apiName;
    return InkWell(
      onTap: () => setState(() => _cat = c),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? primaryColor : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          c.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(_uiFmt.format(value),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF0F172A))),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<_HRow> rows, Color primaryColor) {
    final d = _cat.decimals;
    const head = TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B));
    const body = TextStyle(fontSize: 12, color: Color(0xFF0F172A));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 22,
            headingRowHeight: 40,
            dataRowMinHeight: 38,
            dataRowMaxHeight: 38,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('Tanggal', style: head)),
              DataColumn(label: Text('Open', style: head)),
              DataColumn(label: Text('High', style: head)),
              DataColumn(label: Text('Low', style: head)),
              DataColumn(label: Text('Close', style: head)),
              DataColumn(label: Text('Perubahan', style: head)),
            ],
            rows: rows.map((r) {
              if (r.isHoliday) {
                final name = (r.holidayName ?? '').trim();
                return DataRow(cells: [
                  DataCell(Text(_uiFmt.format(r.date), style: body)),
                  DataCell(Text(name.isEmpty ? 'Libur' : 'Libur: $name',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B)))),
                  const DataCell(Text('-', style: body)),
                  const DataCell(Text('-', style: body)),
                  const DataCell(Text('-', style: body)),
                  const DataCell(Text('-', style: body)),
                ]);
              }
              final pct = r.changePct;
              final color = pct == null
                  ? const Color(0xFF0F172A)
                  : (pct >= 0 ? _green : primaryColor);
              return DataRow(cells: [
                DataCell(Text(_uiFmt.format(r.date), style: body)),
                DataCell(Text(_fmt(r.open, d), style: body)),
                DataCell(Text(_fmt(r.high, d), style: body)),
                DataCell(Text(_fmt(r.low, d), style: body)),
                DataCell(Text(_fmt(r.close, d),
                    style: body.copyWith(fontWeight: FontWeight.w700))),
                DataCell(Text(_pct(pct),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _messageBox(IconData icon, String title, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ---------- Kartu riwayat perhitungan ----------
  Widget _typeBadge(String label, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }

  Widget _cardHeader(HistoryItem item, String label, IconData icon, Color c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              _typeBadge(label, icon, c),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${item.formattedDate} • ${item.formattedTime}',
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            widget.onDeleteHistory(item.id);
            _toast('Item perhitungan telah dihapus.');
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.delete_outline_rounded,
                size: 20, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _actionButtons(HistoryItem item, Color c) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => widget.onOpenDetailModal(item),
            icon: Icon(Icons.visibility_outlined, size: 16, color: c),
            label: Text('Rincian', style: TextStyle(color: c)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: c.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => widget.onRecalculate(item),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Hitung Ulang'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: c,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      );

  Widget _buildPivotCard(HistoryItem item, Color primaryColor) {
    final bool isBullish = item.bias == 'bullish';
    final bool isBearish = item.bias == 'bearish';

    Color biasBg = const Color(0xFFF8FAFC);
    Color biasText = const Color(0xFF334155);
    Color biasBorder = const Color(0xFFE2E8F0);
    IconData biasIcon = Icons.swap_horiz_rounded;

    if (isBullish) {
      biasBg = const Color(0xFFECFDF5);
      biasText = const Color(0xFF047857);
      biasBorder = const Color(0xFFA7F3D0);
      biasIcon = Icons.trending_up_rounded;
    } else if (isBearish) {
      biasBg = primaryColor.withValues(alpha: 0.1);
      biasText = primaryColor;
      biasBorder = primaryColor.withValues(alpha: 0.3);
      biasIcon = Icons.trending_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(item, 'Pivot Point', Icons.show_chart_rounded, primaryColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PASAR KOMODITAS',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  Text(item.pair ?? '-',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: biasBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: biasBorder),
                ),
                child: Row(
                  children: [
                    Icon(biasIcon, size: 15, color: biasText),
                    const SizedBox(width: 4),
                    Text((item.bias ?? 'NETRAL').toUpperCase(),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: biasText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('PIVOT (PP)',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(item.pp?.toStringAsFixed(2) ?? '0.00',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: primaryColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Text('RESIST 1 (R1)',
                            style: TextStyle(
                                fontSize: 10.5,
                                color: primaryColor,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(item.r1?.toStringAsFixed(2) ?? '0.00',
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('SUPPORT 1 (S1)',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(item.s1?.toStringAsFixed(2) ?? '0.00',
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _actionButtons(item, primaryColor),
        ],
      ),
    );
  }

  Widget _buildGoldCard(HistoryItem item, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(item, 'Emas Fisik', Icons.view_in_ar_rounded, primaryColor),
          const SizedBox(height: 12),
          const Text('SPESIFIKASI FISIK',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${item.weight ?? 0}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A))),
              const SizedBox(width: 4),
              const Text('gram',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B))),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(item.purityLabel ?? '24K',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimasi Total Akhir',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(_rupiah(item.grandTotal ?? 0),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _actionButtons(item, primaryColor),
        ],
      ),
    );
  }

  Widget _buildGenericCard(
      HistoryItem item, String title, IconData icon, Color c) {
    final text =
        item.description ?? 'Data ${title.toLowerCase()} tersimpan pada riwayat ini.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(item, title, icon, c),
          const SizedBox(height: 12),
          Text(item.title ?? item.pair ?? 'Riwayat $title',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 12),
          _actionButtons(item, c),
        ],
      ),
    );
  }
}