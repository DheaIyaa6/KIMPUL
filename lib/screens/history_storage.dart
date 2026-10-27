import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Penyimpanan riwayat perhitungan di Firestore, terikat ke akun (uid).
/// Lokasi: users/{uid}/history/{id}
///
/// Karena tersimpan di cloud per akun, riwayat tetap ada setelah logout,
/// setelah install ulang, dan terlihat di semua HP dengan akun yang sama.
class HistoryStorage {
  static CollectionReference<Map<String, dynamic>>? _col() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history');
  }

  /// Simpan satu riwayat. Tidak perlu di-await: kalau HP sedang offline,
  /// Firestore menyimpannya dulu dan mengirimnya saat online lagi.
  static void save({
    required String id,
    required String type, // 'pivot' | 'gold' | 'nest'
    required String formattedDate,
    required String formattedTime,
    String? pair,
    String? bias,
    double? pp,
    double? r1,
    double? s1,
    double? weight,
    String? purityLabel,
    double? grandTotal,
    String? title,
    String? description,
  }) {
    final col = _col();
    if (col == null) {
      debugPrint('RIWAYAT: belum login, tidak disimpan ke cloud');
      return;
    }

    col.doc(id).set({
      'id': id,
      'type': type,
      'formattedDate': formattedDate,
      'formattedTime': formattedTime,
      'createdMs': DateTime.now().millisecondsSinceEpoch,
      'pair': ?pair,
      'bias': ?bias,
      'pp': ?pp,
      'r1': ?r1,
      's1': ?s1,
      'weight': ?weight,
      'purityLabel': ?purityLabel,
      'grandTotal': ?grandTotal,
      'title': ?title,
      'description': ?description,
    }).catchError((e) {
      debugPrint('RIWAYAT: gagal simpan: $e');
    });
  }

  /// Dengarkan riwayat milik [uid] secara realtime, terbaru di atas.
  static Stream<List<Map<String, dynamic>>> watch(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('createdMs', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  static void delete(String id) {
    final col = _col();
    if (col == null) return;
    col.doc(id).delete().catchError((e) {
      debugPrint('RIWAYAT: gagal hapus: $e');
    });
  }
}