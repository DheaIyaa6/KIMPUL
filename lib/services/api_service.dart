import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

/// Model NewsItem untuk Menampilkan Berita Pasar & Komoditas di App
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

class ApiService {
  // 🌟 DAFTAR RSS FEED RESMI EMAS, PASAR & MACRO (CNBC & REUTERS)
  static const List<Map<String, String>> _rssFeeds = [
    {
      'source': 'CNBC Commodities & Gold',
      'url': 'https://search.cnbc.com/rs/search/combinedondemand/rss?partnerId=wrss01&id=10000115',
      'category': 'XAU/USD',
    },
    {
      'source': 'CNBC World Economy',
      'url': 'https://search.cnbc.com/rs/search/combinedondemand/rss?partnerId=wrss01&id=20910258',
      'category': 'MACRO',
    },
    {
      'source': 'CNBC Finance & Markets',
      'url': 'https://search.cnbc.com/rs/search/combinedondemand/rss?partnerId=wrss01&id=10000664',
      'category': 'FOREX',
    },
  ];

  /// 🌟 FUNGSI: Ambil Berita Live Emas & Pasar dengan Safe Parsing
  static Future<List<NewsItem>> getTradingViewNews() async {
    final List<NewsItem> fetchedNews = [];
    int itemCounter = 0;

    for (final feed in _rssFeeds) {
      try {
        final response = await http
            .get(Uri.parse(feed['url']!))
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final rawXml = response.body;
          final document = xml.XmlDocument.parse(rawXml);
          final items = document.findAllElements('item');

          for (final item in items) {
            try {
              // Safe Extraction nilai elemen XML
              final titleElement = item.findElements('title').firstOrNull;
              final linkElement = item.findElements('link').firstOrNull;
              final descElement = item.findElements('description').firstOrNull;
              final pubDateElement = item.findElements('pubDate').firstOrNull;

              final String title = titleElement?.value ?? titleElement?.innerText ?? '';
              final String link = linkElement?.value ?? linkElement?.innerText ?? '';
              final String description = descElement?.value ?? descElement?.innerText ?? '';
              final String pubDateStr = pubDateElement?.value ?? pubDateElement?.innerText ?? '';

              if (title.trim().isEmpty || link.trim().isEmpty) continue;

              // Filter topik irrelevant jika ada
              final lowerTitle = title.toLowerCase();
              if (lowerTitle.contains('divorce') ||
                  lowerTitle.contains('probate') ||
                  lowerTitle.contains('executor')) {
                continue;
              }

              // Bersihkan Tag HTML dari deskripsi
              final cleanSummary = description
                  .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();

              // Ekstrak Gambar dari tag enclosure/media
              String imageUrl =
                  'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80';
              final enclosure = item.findElements('enclosure').firstOrNull;
              if (enclosure != null && enclosure.getAttribute('url') != null) {
                imageUrl = enclosure.getAttribute('url')!;
              }

              // Format Waktu Terbit
              String timeAgo = 'Terbaru';
              if (pubDateStr.isNotEmpty) {
                try {
                  final pubDate = DateTime.parse(pubDateStr);
                  final diff = DateTime.now().difference(pubDate);
                  if (diff.inMinutes < 60) {
                    timeAgo = '${diff.inMinutes} mnt lalu';
                  } else if (diff.inHours < 24) {
                    timeAgo = '${diff.inHours} jam lalu';
                  } else {
                    timeAgo = '${diff.inDays} hari lalu';
                  }
                } catch (_) {}
              }

              fetchedNews.add(
                NewsItem(
                  id: 'rss-$itemCounter-${DateTime.now().millisecondsSinceEpoch}',
                  title: title.trim(),
                  summary: cleanSummary.isNotEmpty
                      ? (cleanSummary.length > 130
                          ? '${cleanSummary.substring(0, 130)}...'
                          : cleanSummary)
                      : 'Klik Baca Full untuk membaca artikel berita lengkap di ${feed['source']}...',
                  source: feed['source']!,
                  timeAgo: timeAgo,
                  readTime: '3 mnt baca',
                  category: feed['category']!,
                  tagType: 'LIVE',
                  imageUrl: imageUrl,
                  fullContent: link.trim(), // Link asli menuju artikel spesifik
                  featured: itemCounter == 0,
                ),
              );

              itemCounter++;
              if (itemCounter >= 18) break;
            } catch (e) {
              // Jika 1 elemen bermasalah, lewati ke elemen berikutnya tanpa membuat crash
              continue;
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching RSS ${feed['source']}: $e");
      }
    }

    if (fetchedNews.isNotEmpty) {
      return fetchedNews;
    }

    // Jika terjadi masalah jaringan, tampilkan berita cadangan dengan link berita spesifik
    return _getFallbackNews();
  }

  /// FALLBACK BERITA EMAS & KEUANGAN
  static List<NewsItem> _getFallbackNews() {
    return [
      NewsItem(
        id: 'fb-1',
        title: 'Harga Emas Antam Naik Rp 5.000 Hari Ini, Tembus Rekor Baru',
        summary: 'Pergerakan harga emas batangan domestik terus menguat seiring dengan ketidakpastian geopolitik dan lonjakan permintaan instrumen safe-haven.',
        source: 'CNBC Indonesia',
        timeAgo: '30 mnt lalu',
        readTime: '2 mnt baca',
        category: 'XAU/USD',
        tagType: 'HOT',
        imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
        fullContent: 'https://www.cnbcindonesia.com/market/20240920081230-17-573121/harga-emas-antam-hari-ini-naik-tembus-rekor-tertinggi-sepanjang-masa',
        featured: true,
      ),
      NewsItem(
        id: 'fb-2',
        title: 'Prediksi Suku Bunga The Fed dan Dampaknya Terhadap Nilai Tukar Rupiah',
        summary: 'Sinyal pemangkasan suku bunga acuan diperkirakan akan memberi dorongan positif bagi aset komoditas emas dan indeks mata uang berkembang.',
        source: 'Reuters Finance',
        timeAgo: '1 jam lalu',
        readTime: '4 mnt baca',
        category: 'FOREX',
        tagType: 'ANALYSIS',
        imageUrl: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=600&q=80',
        fullContent: 'https://id.investing.com/currencies/xau-usd-news',
        featured: false,
      ),
      NewsItem(
        id: 'fb-3',
        title: 'Strategi Manajemen Risiko Trading Kalkulator di Pasar Volatil',
        summary: 'Ketahui cara menghitung Position Sizing dan Stop Loss yang ideal sebelum mengeksekusi transaksi pasar komoditas.',
        source: 'Bloomberg Markets',
        timeAgo: '2 jam lalu',
        readTime: '3 mnt baca',
        category: 'TRADING',
        tagType: 'TIPS',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=600&q=80',
        fullContent: 'https://www.bloomberg.com/markets/commodities',
        featured: false,
      ),
      NewsItem(
        id: 'fb-4',
        title: 'Bank Sentral China Menambah Cadangan Emas Fisik 10 Ton',
        summary: 'Langkah akumulasi beruntun selama 18 bulan mendongkrak optimisme harga emas dunia melampaui resistansi \$2.350.',
        source: 'CNBC World',
        timeAgo: '3 jam lalu',
        readTime: '3 mnt baca',
        category: 'COMMODITY',
        tagType: 'NEWS',
        imageUrl: 'https://images.unsplash.com/photo-1589758438368-0ad531db3366?auto=format&fit=crop&w=600&q=80',
        fullContent: 'https://www.cnbc.com/gold/',
        featured: false,
      ),
    ];
  }
}