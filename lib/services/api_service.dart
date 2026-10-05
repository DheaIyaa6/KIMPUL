import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String timeAgo;
  final String readTime;
  final String category;
  final String tagType;
  final String imageUrl;
  final String fullContent;
  final bool featured;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.timeAgo,
    required this.readTime,
    required this.category,
    required this.tagType,
    required this.imageUrl,
    required this.fullContent,
    this.featured = false,
  });
}

class _Feed {
  final String source; // label default (Google News akan diganti nama penerbit asli)
  final String url;
  final String category;
  final bool filter; // true = wajib lolos filter keyword relevansi
  final bool isGoogle;
  const _Feed(this.source, this.url, this.category,
      {this.filter = true, this.isGoogle = false});
}

class ApiService {
  // Feed yang gagal tidak menggagalkan feed lain.
  static const List<_Feed> _feeds = [
    _Feed(
      'CNBC Finance',
      'https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=10000664',
      'FOREX',
    ),
    _Feed(
      'CNBC Economy',
      'https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=20910258',
      'MACRO',
    ),
    _Feed(
      'Bloomberg Markets',
      'https://feeds.bloomberg.com/markets/news.rss',
      'MARKETS',
    ),
    _Feed(
      'Bloomberg Commodities',
      'https://feeds.bloomberg.com/commodities/news.rss',
      'XAU/USD',
    ),
    _Feed(
      'CNBC Indonesia',
      'https://www.cnbcindonesia.com/market/rss',
      'EMAS',
    ),
    // Google News RSS: sudah difilter query & umur berita (2 hari)
    _Feed(
      'Google News',
      'https://news.google.com/rss/search?q=gold+price+OR+XAUUSD+OR+%22gold+futures%22+when:2d&hl=en-US&gl=US&ceid=US:en',
      'XAU/USD',
      filter: false,
      isGoogle: true,
    ),
    _Feed(
      'Reuters',
      'https://news.google.com/rss/search?q=site:reuters.com+(gold+OR+dollar+OR+Fed+OR+inflation)+when:2d&hl=en-US&gl=US&ceid=US:en',
      'MACRO',
      filter: false,
      isGoogle: true,
    ),
  ];

  static const _keywords = [
    'gold', 'xau', 'bullion', 'precious metal', 'silver', 'fed ', 'federal reserve',
    'fomc', 'powell', 'interest rate', 'rate cut', 'rate hike', 'inflation', 'cpi',
    'nonfarm', 'payroll', 'treasury', 'yield', 'dollar', 'dxy', 'forex', 'safe-haven',
    'safe haven', 'commodit', 'oil', 'central bank', 'tariff', 'recession',
    'emas', 'suku bunga', 'inflasi', 'rupiah', 'dolar', 'komoditas', 'bank sentral',
  ];

  static const Duration _maxAge = Duration(days: 3);

  static const String _defaultImage =
      'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80';

  static const Map<String, int> _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  static DateTime? _parseRssDate(String s) {
    final m = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4})?',
    ).firstMatch(s);
    if (m == null) return DateTime.tryParse(s)?.toUtc();
    final month = _months[m.group(2)!];
    if (month == null) return null;

    var dt = DateTime.utc(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6) ?? '0'),
    );
    final tz = m.group(7);
    if (tz != null) {
      final sign = tz.startsWith('-') ? -1 : 1;
      final h = int.parse(tz.substring(1, 3));
      final mn = int.parse(tz.substring(3, 5));
      dt = dt.subtract(Duration(minutes: sign * (h * 60 + mn)));
    }
    return dt;
  }

  static String _timeAgo(DateTime? published) {
    if (published == null) return 'Terbaru';
    final diff = DateTime.now().toUtc().difference(published);
    if (diff.isNegative || diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  static String _imageFrom(xml.XmlElement item) {
    final enc = item.findElements('enclosure').firstOrNull?.getAttribute('url');
    if (enc != null && enc.isNotEmpty) return enc;
    for (final e in item.descendants.whereType<xml.XmlElement>()) {
      final name = e.name.local;
      if (name == 'thumbnail' || name == 'content') {
        final u = e.getAttribute('url');
        if (u != null && u.startsWith('http')) return u;
      }
    }
    return _defaultImage;
  }

  static String _clean(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isRelevant(String text) {
    final t = ' ${text.toLowerCase()} ';
    return _keywords.any(t.contains);
  }

  static Future<List<MapEntry<DateTime?, NewsItem>>> _fetchFeed(
      _Feed feed, int feedIndex) async {
    final result = <MapEntry<DateTime?, NewsItem>>[];
    try {
      final response = await http.get(
        Uri.parse(feed.url),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('RSS ${feed.source} GAGAL status ${response.statusCode}');
        return result;
      }

      final document = xml.XmlDocument.parse(response.body);
      var count = 0;

      for (final item in document.findAllElements('item')) {
        try {
          var title = item.findElements('title').firstOrNull?.innerText.trim() ?? '';
          final link = item.findElements('link').firstOrNull?.innerText.trim() ?? '';
          final desc = item.findElements('description').firstOrNull?.innerText ?? '';
          final pubStr = item.findElements('pubDate').firstOrNull?.innerText ?? '';
          if (title.isEmpty || link.isEmpty) continue;

          final published = _parseRssDate(pubStr);
          // Buang berita basi
          if (published != null &&
              DateTime.now().toUtc().difference(published) > _maxAge) {
            continue;
          }

          var sourceName = feed.source;
          var summary = _clean(desc);

          if (feed.isGoogle) {
            // Judul Google News: "Judul - Penerbit"
            final pub = item.findElements('source').firstOrNull?.innerText.trim();
            final idx = title.lastIndexOf(' - ');
            if (idx > 0) title = title.substring(0, idx).trim();
            if (pub != null && pub.isNotEmpty) sourceName = pub;
            // deskripsi Google hanya berisi link berulang, tidak berguna
            summary = 'Dari $sourceName. Ketuk untuk membaca selengkapnya.';
          }

          final lower = title.toLowerCase();
          if (lower.contains('divorce') ||
              lower.contains('probate') ||
              lower.contains('executor')) {
            continue;
          }

          // Filter relevansi: hanya berita seputar emas/forex/makro
          if (feed.filter && !_isRelevant('$title $summary')) continue;

          result.add(MapEntry(
            published,
            NewsItem(
              id: 'rss-$feedIndex-$count-${published?.millisecondsSinceEpoch ?? 0}',
              title: title,
              summary: summary.isEmpty
                  ? 'Ketuk untuk membaca artikel lengkap di $sourceName.'
                  : (summary.length > 130
                      ? '${summary.substring(0, 130)}...'
                      : summary),
              source: sourceName,
              timeAgo: _timeAgo(published),
              readTime: '3 mnt baca',
              category: feed.category,
              tagType: 'LIVE',
              imageUrl: _imageFrom(item),
              fullContent: link,
            ),
          ));

          count++;
          if (count >= 10) break;
        } catch (_) {
          continue;
        }
      }
      debugPrint('RSS ${feed.source}: $count berita lolos filter');
    } catch (e) {
      debugPrint('RSS ${feed.source} ERROR: $e');
    }
    return result;
  }

  /// Ambil berita live dari semua feed paralel.
  /// Mengembalikan list KOSONG jika semua gagal (tanpa berita palsu).
  static Future<List<NewsItem>> getTradingViewNews() async {
    final results = await Future.wait(
      List.generate(_feeds.length, (i) => _fetchFeed(_feeds[i], i)),
    );

    final all = results.expand((e) => e).toList();
    if (all.isEmpty) {
      debugPrint('Semua RSS gagal / tidak ada berita relevan');
      return [];
    }

    // Hapus duplikat (judul sama persis setelah dinormalisasi)
    final seen = <String>{};
    final unique = all.where((e) {
      final key = e.value.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      return seen.add(key);
    }).toList();

    // Terbaru di atas; tanpa tanggal di bawah
    unique.sort((a, b) {
      if (a.key == null && b.key == null) return 0;
      if (a.key == null) return 1;
      if (b.key == null) return -1;
      return b.key!.compareTo(a.key!);
    });

    final news = unique.take(20).map((e) => e.value).toList();

    return [
      for (var i = 0; i < news.length; i++)
        NewsItem(
          id: news[i].id,
          title: news[i].title,
          summary: news[i].summary,
          source: news[i].source,
          timeAgo: news[i].timeAgo,
          readTime: news[i].readTime,
          category: news[i].category,
          tagType: news[i].tagType,
          imageUrl: news[i].imageUrl,
          fullContent: news[i].fullContent,
          featured: i == 0,
        ),
    ];
  }
}