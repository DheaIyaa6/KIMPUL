import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';

// 1. Model NewsItem ditaruh langsung di sini agar tidak error import
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
  // URL dasar folder backend di Laragon
  static const String apiBase = "http://192.168.1.207/api_flutter";
  
  // URL Backend Lokal (Laragon)
  static const String baseUrl = "$apiBase/get_data.php";

  // URL TradingView RSS
  static const String tradingViewUrl = "https://www.tradingview.com/feed/";

  // FUNGSI 1: Ambil Data User dari Laragon (PHP)
  static Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result['data'];
        }
      }
      return [];
    } catch (e) {
      print("Error koneksi API Laragon: $e");
      return [];
    }
  }

  // FUNGSI 2: Ambil Berita Live dari TradingView
  static Future<List<NewsItem>> getTradingViewNews() async {
    try {
      final response = await http.get(
        Uri.parse(tradingViewUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final rssFeed = RssFeed.parse(response.body);

        if (rssFeed.items != null && rssFeed.items!.isNotEmpty) {
          final List<NewsItem> fetchedItems = [];

          for (int i = 0; i < rssFeed.items!.length; i++) {
            final item = rssFeed.items![i];

            String timeFormatted = 'Terbaru';
            if (item.pubDate != null) {
              final diff = DateTime.now().difference(item.pubDate!);
              if (diff.inMinutes < 60) {
                timeFormatted = '${diff.inMinutes}m lalu';
              } else if (diff.inHours < 24) {
                timeFormatted = '${diff.inHours}j lalu';
              } else {
                timeFormatted = '${diff.inDays}hr lalu';
              }
            }

            String cleanSummary = (item.description ?? '')
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .trim();
            if (cleanSummary.isEmpty) {
              cleanSummary =
                  'Klik untuk membaca analisa dan detail berita pasar terkini...';
            }

            fetchedItems.add(
              NewsItem(
                id: item.guid ?? '$i-${DateTime.now().millisecondsSinceEpoch}',
                title: item.title ?? 'Berita Pasar Emas & Komoditas',
                summary: cleanSummary,
                source: 'TradingView Newsroom',
                timeAgo: timeFormatted,
                readTime: '3 mnt baca',
                category: 'XAU/USD',
                tagType: 'MARKET',
                imageUrl:
                    'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
                fullContent: item.link ?? '',
                featured: i == 0,
              ),
            );
          }
          return fetchedItems;
        }
      }
      return [];
    } catch (e) {
      print("Error koneksi API TradingView: $e");
      return [];
    }
  }

  // FUNGSI 3: Register user baru
  static Future<Map<String, dynamic>> registerUser(
      String nama, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/register.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": nama,
          "email": email,
          "password": password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Gagal konek ke server: $e"};
    }
  }

  // FUNGSI 4: Login user
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Gagal konek ke server: $e"};
    }
  }
}