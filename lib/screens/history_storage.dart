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

  // ---------- Helper detail lengkap (untuk halaman detail Riwayat) ----------

  /// Satu bagian detail: judul + baris label/nilai (sudah berupa teks).
  /// [headline] + [tone] ('buy' / 'sell' / 'neutral') menampilkan kartu
  /// berwarna dengan judul besar, seperti kartu sinyal / hasil di kalkulator.
  static Map<String, dynamic> section(
    String title,
    List<MapEntry<String, String>> rows, {
    String? headline,
    String? tone,
  }) {
    return {
      'title': title,
      'rows': rows.map((e) => {'l': e.key, 'v': e.value}).toList(),
      'headline': ?headline,
      'tone': ?tone,
    };
  }

  /// Ubah daftar baris (format _shareRows di kalkulator) menjadi bagian-bagian.
  /// Baris dengan nilai kosong dianggap judul bagian baru.
  static List<Map<String, dynamic>> sectionsFromRows(
    List<MapEntry<String, String>> rows, {
    String firstTitle = 'Ringkasan',
  }) {
    final out = <Map<String, dynamic>>[];
    var title = firstTitle;
    var cur = <MapEntry<String, String>>[];

    void flush() {
      if (cur.isNotEmpty) out.add(section(title, cur));
      cur = <MapEntry<String, String>>[];
    }

    for (final e in rows) {
      if (e.value.isEmpty) {
        flush();
        title = e.key;
      } else {
        cur.add(e);
      }
    }
    flush();
    return out;
  }

  /// Simpan satu riwayat. Tidak perlu di-await: kalau HP sedang offline,
  /// Firestore menyimpannya dulu dan mengirimnya saat online lagi.
  ///
  /// Semua field angka di bawah dibaca balik oleh halaman Riwayat untuk
  /// menampilkan rincian lengkap. Field yang tidak diisi (null) dilewati.
  static void save({
    required String id,
    required String type, // 'pivot' | 'gold' | 'nest'
    required String formattedDate,
    required String formattedTime,
    String? pair,
    String? bias,
    String? title,
    String? description,

    // --- Pivot ---
    double? high,
    double? low,
    double? close,
    double? open, // dipakai Pivot (Open hari ini) dan Nest (Open kemarin)
    double? pp,
    double? r1,
    double? r2,
    double? r3,
    double? r4,
    double? s1,
    double? s2,
    double? s3,
    double? s4,
    double? diff, // Pivot: Close - PP, Nest: Close - Open

    // --- Emas Fisik ---
    double? modal,
    double? kurs,
    double? hargaBeliUsd,
    double? hargaJualUsd,
    double? hbPerGram,
    double? hjPerGram,
    double? selisihPerGram,
    double? weight, // gram emas yang didapat
    double? untung,
    String? purityLabel,
    double? grandTotal, // nilai akhir

    // --- Nest ---
    double? diffPercent,
    String? signal, // 'BUY' | 'SELL' | 'NETRAL'

    List<Map<String, dynamic>>? sections, // detail lengkap perhitungan
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
      'title': ?title,
      'description': ?description,
      // Pivot
      'high': ?high,
      'low': ?low,
      'close': ?close,
      'open': ?open,
      'pp': ?pp,
      'r1': ?r1,
      'r2': ?r2,
      'r3': ?r3,
      'r4': ?r4,
      's1': ?s1,
      's2': ?s2,
      's3': ?s3,
      's4': ?s4,
      'diff': ?diff,
      // Emas Fisik
      'modal': ?modal,
      'kurs': ?kurs,
      'hargaBeliUsd': ?hargaBeliUsd,
      'hargaJualUsd': ?hargaJualUsd,
      'hbPerGram': ?hbPerGram,
      'hjPerGram': ?hjPerGram,
      'selisihPerGram': ?selisihPerGram,
      'weight': ?weight,
      'untung': ?untung,
      'purityLabel': ?purityLabel,
      'grandTotal': ?grandTotal,
      // Nest
      'diffPercent': ?diffPercent,
      'signal': ?signal,
      'sections': ?sections,
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