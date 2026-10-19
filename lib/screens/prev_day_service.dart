import 'dart:convert';

import 'package:http/http.dart' as http;

/// Data candle harian kemarin (sudah selesai / closed).
class PrevDay {
  final double high;
  final double low;
  final double close;
  final String date; // dd/MM/yyyy

  const PrevDay({
    required this.high,
    required this.low,
    required this.close,
    required this.date,
  });
}

class _Bar {
  final int ts;
  final double high;
  final double low;
  final double close;
  const _Bar(this.ts, this.high, this.low, this.close);
}

class PrevDayService {
  /// Ambil High/Low/Close candle harian terakhir yang sudah selesai.
  /// [symbol] = simbol Yahoo Finance, contoh: GC=F, ^HSI, ^N225
  static Future<PrevDay> fetch(String symbol) async {
    final uri = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/'
      '${Uri.encodeComponent(symbol)}?range=5d&interval=1d',
    );

    final res = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('status ${res.statusCode}');
    }

    final dynamic json = jsonDecode(res.body);
    final dynamic results = json['chart']?['result'];
    if (results is! List || results.isEmpty) {
      throw Exception('data kosong');
    }

    final dynamic result = results.first;
    final int offset = (result['meta']?['gmtoffset'] as num?)?.toInt() ?? 0;
    final List times = (result['timestamp'] as List?) ?? [];
    final dynamic quote = (result['indicators']['quote'] as List).first;
    final List highs = quote['high'] as List;
    final List lows = quote['low'] as List;
    final List closes = quote['close'] as List;

    // Kumpulkan candle yang datanya lengkap (Yahoo kadang kasih null)
    final bars = <_Bar>[];
    for (int i = 0; i < times.length; i++) {
      final num? h = highs[i] as num?;
      final num? l = lows[i] as num?;
      final num? c = closes[i] as num?;
      if (h == null || l == null || c == null) continue;
      bars.add(_Bar((times[i] as num).toInt(), h.toDouble(), l.toDouble(),
          c.toDouble()));
    }
    if (bars.isEmpty) throw Exception('candle kosong');

    String dayKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    DateTime barDay(int ts) => DateTime.fromMillisecondsSinceEpoch(
        (ts + offset) * 1000,
        isUtc: true);

    final todayKey =
        dayKey(DateTime.now().toUtc().add(Duration(seconds: offset)));

    // Kalau candle terakhir adalah hari ini (masih berjalan), pakai yang sebelumnya.
    _Bar pick = bars.last;
    if (dayKey(barDay(pick.ts)) == todayKey && bars.length > 1) {
      pick = bars[bars.length - 2];
    }

    final d = barDay(pick.ts);
    return PrevDay(
      high: pick.high,
      low: pick.low,
      close: pick.close,
      date:
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
    );
  }
}