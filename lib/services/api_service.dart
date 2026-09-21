import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 1. Model NewsItem
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

  // URL Backend PHP untuk Proxy Berita Live (Laragon)
  static const String newsUrl = "$apiBase/get_news.php";

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
      debugPrint("Error koneksi API Laragon: $e");
      return [];
    }
  }

  // FUNGSI 2: Ambil Berita Live via Backend Laragon (PHP)
  static Future<List<NewsItem>> getTradingViewNews() async {
    try {
      final response = await http.get(Uri.parse(newsUrl));

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
                title: item['title'] ?? 'Berita Pasar Emas & Komoditas',
                summary: 'Klik untuk membaca analisa dan detail berita pasar terkini...',
                source: item['source'] ?? 'Market News',
                timeAgo: item['pub_date'] ?? 'Terbaru',
                readTime: '3 mnt baca',
                category: 'XAU/USD',
                tagType: 'MARKET',
                imageUrl:
                    'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
                fullContent: item['link'] ?? '',
                featured: i == 0,
              ),
            );
          }
          return fetchedItems;
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error koneksi API Berita Backend: $e");
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

  // FUNGSI 5: Update Profil User (Nama, Email, dan Foto Profil)
  static Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String nama,
    required String email,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$apiBase/update_profile.php"),
      );

      // Mengirim field teks
      request.fields['id'] = id;
      request.fields['nama'] = nama;
      request.fields['email'] = email;

      // Mengirim file foto jika ada foto baru yang dipilih
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Gagal konek ke server: $e"};
    }
  }
}