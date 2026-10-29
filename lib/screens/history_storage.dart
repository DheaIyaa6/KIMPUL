import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Penyimpanan riwayat perhitungan di Firestore, terikat ke akun (uid).
/// Lokasi: users/{uid}/history/{id}
class HistoryStorage {
  static CollectionReference<Map<String, dynamic>>? _col() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history');
  }

  /// Simpan riwayat lengkap.
  static void save({
    required String id,
    required String type, // 'pivot' | 'gold' | 'nest'
    required String formattedDate,
    required String formattedTime,
    String? pair,
    String? bias,
    String? title,
    String? description,
    
    // Field Pivot
    double? high,
    double? low,
    double? close,
    double? open,
    double? pp,
    double? r1,
    double? r2,
    double? r3,
    double? r4,
    double? s1,
    double? s2,
    double? s3,
    double? s4,
    double? diff,

    // Field Gold
    double? modal,
    double? kurs,
    double? hargaBeliUsd,
    double? hargaJualUsd,
    double? hbPerGram,
    double? hjPerGram,
    double? selisihPerGram,
    double? weight,
    double? untung,
    String? purityLabel,
    double? grandTotal,

    // Field Nest
    double? diffPercent,
    String? signal,
  }) {
    final col = _col();
    if (col == null) {
      debugPrint('RIWAYAT: belum login, tidak disimpan ke cloud');
      return;
    }

    final data = <String, dynamic>{
      'id': id,
      'type': type,
      'formattedDate': formattedDate,
      'formattedTime': formattedTime,
      'createdMs': DateTime.now().millisecondsSinceEpoch,
      'pair': pair,
      'bias': bias,
      'title': title,
      'description': description,
      
      // Pivot
      'high': high,
      'low': low,
      'close': close,
      'open': open,
      'pp': pp,
      'r1': r1,
      'r2': r2,
      'r3': r3,
      'r4': r4,
      's1': s1,
      's2': s2,
      's3': s3,
      's4': s4,
      'diff': diff,

      // Gold
      'modal': modal,
      'kurs': kurs,
      'hargaBeliUsd': hargaBeliUsd,
      'hargaJualUsd': hargaJualUsd,
      'hbPerGram': hbPerGram,
      'hjPerGram': hjPerGram,
      'selisihPerGram': selisihPerGram,
      'weight': weight,
      'untung': untung,
      'purityLabel': purityLabel,
      'grandTotal': grandTotal,

      // Nest
      'diffPercent': diffPercent,
      'signal': signal,
    };

    // Bersihkan entri dengan nilai null agar tidak mengotori Firestore
    data.removeWhere((key, value) => value == null);

    col.doc(id).set(data).catchError((e) {
      debugPrint('RIWAYAT: gagal simpan: $e');
    });
  }

  /// Dengarkan riwayat milik [uid] secara realtime
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