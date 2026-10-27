import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Candle harian kemarin (Open & Close) dari Yahoo Finance, khusus Nest.
/// Dibuat terpisah supaya PrevDayService (dipakai Pivot) tidak diubah.
class NestPrevDay {
  final double open;
  final double close;
  final String date; // yyyy-MM-dd

  const NestPrevDay({
    required this.open,
    required this.close,
    required this.date,
  });

  static const List<String> _hosts = [
    'query1.finance.yahoo.com',
    'query2.finance.yahoo.com',
  ];

  static Future<NestPrevDay> fetch(String symbol) async {
    Object? lastError;
    for (final host in _hosts) {
      try {
        return await _fetchFrom(host, symbol);
      } catch (e) {
        lastError = e;
        debugPrint('NEST prev-day $host gagal: $e');
      }
    }
    throw Exception('Gagal ambil data kemarin: $lastError');
  }

  static Future<NestPrevDay> _fetchFrom(String host, String symbol) async {
    final uri = Uri.https(
      host,
      '/v8/finance/chart/$symbol',
      {'range': '10d', 'interval': '1d'},
    );

    final res = await http.get(uri, headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('status ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['chart']?['result'];
    if (results is! List || results.isEmpty) {
      throw Exception('data kosong');
    }

    final r = results.first as Map<String, dynamic>;
    final ts = (r['timestamp'] as List?) ?? const [];
    final quoteList = (r['indicators']?['quote'] as List?) ?? const [];
    if (ts.isEmpty || quoteList.isEmpty) {
      throw Exception('candle kosong');
    }

    final q = quoteList.first as Map<String, dynamic>;
    final opens = (q['open'] as List?) ?? const [];
    final closes = (q['close'] as List?) ?? const [];
    final offset = (r['meta']?['gmtoffset'] as num?)?.toInt() ?? 0;

    final n = [ts.length, opens.length, closes.length]
        .reduce((a, b) => a < b ? a : b);

    final bars = <_Bar>[];
    for (var i = 0; i < n; i++) {
      final t = ts[i];
      final o = opens[i];
      final c = closes[i];
      if (t is! num || o is! num || c is! num) continue;

      final local = DateTime.fromMillisecondsSinceEpoch(
        t.toInt() * 1000,
        isUtc: true,
      ).add(Duration(seconds: offset));
      bars.add(_Bar(
        DateTime.utc(local.year, local.month, local.day),
        o.toDouble(),
        c.toDouble(),
      ));
    }
    if (bars.isEmpty) throw Exception('tidak ada candle valid');

    // Candle hari ini (masih berjalan) dibuang, ambil candle kemarin
    final nowLocal = DateTime.now().toUtc().add(Duration(seconds: offset));
    final today = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);
    if (bars.length > 1 && !bars.last.day.isBefore(today)) {
      bars.removeLast();
    }

    final b = bars.last;
    final mm = b.day.month.toString().padLeft(2, '0');
    final dd = b.day.day.toString().padLeft(2, '0');
    return NestPrevDay(
      open: b.open,
      close: b.close,
      date: '${b.day.year}-$mm-$dd',
    );
  }
}

class _Bar {
  final DateTime day;
  final double open;
  final double close;
  const _Bar(this.day, this.open, this.close);
}