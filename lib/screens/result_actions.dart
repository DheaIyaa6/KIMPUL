import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tombol "WhatsApp", "Bagikan", dan "Cetak" untuk hasil kalkulator.
///
/// [rows] berisi pasangan label -> nilai. Kalau nilainya kosong (''),
/// baris itu dianggap judul bagian (misalnya "Level").
class ResultActions extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> rows;
  final Color color;

  const ResultActions({
    super.key,
    required this.title,
    required this.rows,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = buildShareText(title, rows);

    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            fg: const Color(0xFF16A34A),
            onTap: () => shareToWhatsApp(context, text),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            icon: Icons.share_rounded,
            label: 'Bagikan',
            fg: color,
            onTap: () => shareToApps(context, title, text),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            icon: Icons.print_rounded,
            label: 'Cetak',
            fg: const Color(0xFF334155),
            onTap: () => printResult(context, title, rows),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: fg),
      label: Text(label, style: TextStyle(color: fg)),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: fg.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------- Teks untuk dibagikan ----------

String buildShareText(String title, List<MapEntry<String, String>> rows) {
  final b = StringBuffer('*$title*\n');
  for (final r in rows) {
    if (r.value.isEmpty) {
      b.writeln('\n*${r.key}*');
    } else {
      b.writeln('${r.key}: ${r.value}');
    }
  }
  b.write('\nDihitung dengan KIMPUL. Hanya simulasi, bukan saran investasi.');
  return b.toString();
}

void _snack(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ---------- WhatsApp langsung ----------

Future<void> shareToWhatsApp(BuildContext context, String text) async {
  try {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _snack(context, 'Tidak bisa membuka WhatsApp.');
  } catch (_) {
    _snack(context, 'Tidak bisa membuka WhatsApp.');
  }
}

// ---------- Menu bagikan bawaan HP (Instagram, Telegram, dll) ----------

Future<void> shareToApps(BuildContext context, String title, String text) async {
  try {
    await SharePlus.instance.share(ShareParams(text: text, subject: title));
  } catch (_) {
    _snack(context, 'Gagal membuka menu bagikan.');
  }
}

// ---------- Cetak / simpan PDF ----------

// Font bawaan PDF tidak punya simbol seperti × ÷ → −, jadi diganti ASCII.
String _ascii(String s) => s
    .replaceAll('×', 'x')
    .replaceAll('÷', '/')
    .replaceAll('−', '-')
    .replaceAll('→', '->')
    .replaceAll('•', '-')
    .replaceAll('’', "'");

Future<Uint8List> _buildPdf(
    String title, List<MapEntry<String, String>> rows) async {
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('KIMPUL',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink700)),
            pw.SizedBox(height: 4),
            pw.Text(_ascii(title),
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            ...rows.map((r) {
              if (r.value.isEmpty) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
                  child: pw.Text(_ascii(r.key),
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                );
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(_ascii(r.key), style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(_ascii(r.value),
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 20),
            pw.Text(
              'Dihitung dengan KIMPUL. Hanya simulasi, bukan saran investasi.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<void> printResult(BuildContext context, String title,
    List<MapEntry<String, String>> rows) async {
  try {
    final bytes = await _buildPdf(title, rows);
    final name = 'KIMPUL-${title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: name,
    );
  } catch (_) {
    _snack(context, 'Gagal menyiapkan dokumen cetak.');
  }
}