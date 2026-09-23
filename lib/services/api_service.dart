import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  // Base URL Public/API untuk layanan Fetch Berita Live
  static const String newsApiUrl = "https://api.statickim.com/get_news.php";

  /// 🌟 FUNGSI: Ambil Berita Live Pasar & Komoditas (XAU/USD)
  static Future<List<NewsItem>> getTradingViewNews() async {
    try {
      final response = await http
          .get(Uri.parse(newsApiUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success' && result['data'] != null) {
          final List<dynamic> articles = result['data'];
          final List<NewsItem> fetchedItems = [];

          for (int i = 0; i < articles.length; i++) {
            final item = articles[i];

            fetchedItems.add(
              NewsItem(
                id: '$i-${DateTime.now().millisecondsSinceEpoch}',
                title: item['title'] ?? 'Analisa & Berita Pasar Komoditas Terkini',
                summary:
                    item['summary'] ?? 'Klik untuk membaca detail pergerakan pasar emas dan valuta asing...',
                source: item['source'] ?? 'Market News',
                timeAgo: item['pub_date'] ?? 'Terbaru',
                readTime: '3 mnt baca',
                category: 'XAU/USD',
                tagType: 'MARKET',
                imageUrl: item['image'] ??
                    'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
                fullContent: item['link'] ?? '',
                featured: i == 0,
              ),
            );
          }
          return fetchedItems;
        }
      }
      return _getFallbackNews();
    } catch (e) {
      debugPrint("Koneksi API Berita eksternal bermasalah, memuat berita dummy: $e");
      return _getFallbackNews();
    }
  }

  /// 🌟 FALLBACK BERITA: Menampilkan data dummy jika API berita offline/timeout
  static List<NewsItem> _getFallbackNews() {
    return [
      NewsItem(
        id: '1',
        title: 'Harga Emas Antam Naik Rp 5.000 Hari Ini, Tembus Rekor Baru',
        summary: 'Pergerakan harga emas batangan domestik terus menguat seiring dengan ketidakpastian pasar global.',
        source: 'KIMPUL Market Research',
        timeAgo: '1 jam lalu',
        readTime: '2 mnt baca',
        category: 'XAU/USD',
        tagType: 'HOT',
        imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
        fullContent: 'https://google.com',
        featured: true,
      ),
      NewsItem(
        id: '2',
        title: 'Prediksi Suku Bunga The Fed dan Dampaknya Terhadap Nilai Tukar Rupiah',
        summary: 'Sinyal pemangkasan suku bunga acuan diperkirakan akan memberi dorongan positif bagi aset kripto dan mata uang berkembang.',
        source: 'Financial News',
        timeAgo: '3 jam lalu',
        readTime: '4 mnt baca',
        category: 'FOREX',
        tagType: 'ANALYSIS',
        imageUrl: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=600&q=80',
        fullContent: 'https://google.com',
        featured: false,
      ),
      NewsItem(
        id: '3',
        title: 'Strategi Manajemen Risiko Trading Kalkulator di Pasar Volatil',
        summary: 'Ketahui cara menghitung Position Sizing dan Stop Loss yang ideal sebelum mengeksekusi transaksi pasar.',
        source: 'KIMPUL Edukasi',
        timeAgo: '5 jam lalu',
        readTime: '3 mnt baca',
        category: 'TRADING',
        tagType: 'TIPS',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=600&q=80',
        fullContent: 'https://google.com',
        featured: false,
      ),
    ];
  }
}