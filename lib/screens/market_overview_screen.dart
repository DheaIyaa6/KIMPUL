import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import 'package:kimpul/screens/tradingview_screen.dart';

class MarketInstrument {
  final String tabLabel;
  final String tabSubtitle;
  final String fullName;
  final String subtitle;
  final String tvSymbol; // simbol TradingView (grafik)
  final String nmSymbol; // simbol Newsmaker (angka live)
  final int decimals; // angka di belakang koma
  final String country;
  final String type;
  final String tradingHours;
  final IconData icon;
  final Color iconColor;

  const MarketInstrument({
    required this.tabLabel,
    required this.tabSubtitle,
    required this.fullName,
    required this.subtitle,
    required this.tvSymbol,
    required this.nmSymbol,
    required this.decimals,
    required this.country,
    required this.type,
    required this.tradingHours,
    required this.icon,
    required this.iconColor,
  });
}

class MarketOverviewScreen extends StatefulWidget {
  const MarketOverviewScreen({super.key});

  @override
  State<MarketOverviewScreen> createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends State<MarketOverviewScreen> {
  static const Color primaryPink = Color(0xFFE93A56);
  static const Color upGreen = Color(0xFF059669);
  static const String _quoteUrl = 'https://www.newsmaker.id/api/live-quotes';

  final List<MarketInstrument> _instruments = const [
    MarketInstrument(
      tabLabel: 'HSI',
      tabSubtitle: 'Hang Seng',
      fullName: 'Hang Seng Index (HSI)',
      subtitle: 'Indeks Saham Hong Kong',
      tvSymbol: 'OANDA:HK33HKD',
      nmSymbol: 'HKK50_BBJ',
      decimals: 0,
      country: 'Hong Kong',
      type: 'Indeks Saham',
      tradingHours: '09.30 - 16.00 (HKT)',
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFFDC2626),
    ),
    MarketInstrument(
      tabLabel: 'XAUUSD',
      tabSubtitle: 'Gold / USD',
      fullName: 'Gold Spot (XAU/USD)',
      subtitle: 'Emas Batangan Dunia',
      tvSymbol: 'OANDA:XAUUSD',
      nmSymbol: 'XUL10',
      decimals: 2,
      country: 'Global (OTC)',
      type: 'Komoditas',
      tradingHours: '24 Jam (Senin-Jumat)',
      icon: Icons.monetization_on_rounded,
      iconColor: Color(0xFFCA8A04),
    ),
    MarketInstrument(
      tabLabel: 'NIKKEI',
      tabSubtitle: 'Nikkei 225',
      fullName: 'Nikkei 225 (JPK)',
      subtitle: 'Indeks Saham Jepang',
      tvSymbol: 'OANDA:JP225USD',
      nmSymbol: 'JPK50_BBJ',
      decimals: 0,
      country: 'Jepang',
      type: 'Indeks Saham',
      tradingHours: '09.00 - 15.30 (JST)',
      icon: Icons.show_chart_rounded,
      iconColor: Color(0xFF1E3A8A),
    ),
  ];

  int _selectedIndex = 0;
  late final List<WebViewController> _controllers;

  // ---- Data live Newsmaker ----
  Timer? _quoteTimer;
  Map<String, Map<String, dynamic>> _quotes = {};
  bool _quoteBusy = false;
  bool _quoteError = false;

  @override
  void initState() {
    super.initState();
    _controllers =
        _instruments.map((ins) => _buildController(ins.tvSymbol)).toList();

    _loadQuotes();
    _quoteTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _loadQuotes());
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    if (_quoteBusy) return;
    _quoteBusy = true;
    try {
      final res = await http
          .get(Uri.parse(_quoteUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        throw Exception('status ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? [];
      final map = <String, Map<String, dynamic>>{};
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          map[(e['symbol'] ?? '').toString()] = e;
        }
      }
      if (!mounted) return;
      setState(() {
        _quotes = map;
        _quoteError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _quoteError = true);
    } finally {
      _quoteBusy = false;
    }
  }

  // Ambil angka dari data (bisa number atau string)
  double? _num(Map<String, dynamic>? q, String key) {
    if (q == null || q[key] == null) return null;
    return double.tryParse(q[key].toString());
  }

  // Format Indonesia: 24.526 / 4.144,68
  String _fmt(double? v, int decimals) {
    if (v == null) return '-';
    final negative = v < 0;
    final parts = v.abs().toStringAsFixed(decimals).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    final result = parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
    return negative ? '-$result' : result;
  }

  WebViewController _buildController(String symbol) {
    final String html = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body, html { height: 100%; width: 100%; overflow: hidden; background-color: transparent; }
          .tradingview-widget-container { height: 100%; width: 100%; }
        </style>
      </head>
      <body>
        <div class="tradingview-widget-container">
          <div class="tradingview-widget-container__widget"></div>
          <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async>
          {
            "symbol": "$symbol",
            "width": "100%",
            "height": "100%",
            "locale": "id",
            "dateRange": "1D",
            "colorTheme": "light",
            "trendLineColor": "rgba(233, 58, 86, 1)",
            "underLineColor": "rgba(233, 58, 86, 0.12)",
            "isTransparent": true,
            "autosize": true,
            "largeChartUrl": ""
          }
          </script>
        </div>
      </body>
      </html>
    ''';

    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _instruments[_selectedIndex];
    final quote = _quotes[selected.nmSymbol];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Grafik Pasar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tentang Grafik Pasar'),
                  content: const Text(
                    'Grafik bersumber dari TradingView dan data harga dari Newsmaker. Keduanya ditampilkan untuk tujuan informasi saja, bukan rekomendasi jual/beli.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Mengerti'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pantau pergerakan pasar secara real-time melalui TradingView.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Tab Pilihan Instrumen
            Row(
              children: List.generate(_instruments.length, (index) {
                final ins = _instruments[index];
                final bool isSelected = index == _selectedIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == _instruments.length - 1 ? 0 : 8,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryPink : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected ? primaryPink : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              ins.icon,
                              size: 18,
                              color: isSelected ? Colors.white : ins.iconColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ins.tabLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              ins.tabSubtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Card Instrumen Terpilih
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected.iconColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(selected.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.fullName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              selected.subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF515F74),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Pasar Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Grafik Mini Live (TradingView)
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _controllers
                            .map((c) => WebViewWidget(controller: c))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 12),

                  // List data pasar live (Newsmaker)
                  _buildQuoteList(quote, selected.decimals),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Grafik Interaktif Penuh
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TradingViewScreen(
                        symbol: selected.tvSymbol,
                        title: selected.tabLabel,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.candlestick_chart_rounded,
                    size: 20, color: Colors.white),
                label: const Text('Buka Grafik Interaktif TradingView'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle:
                      const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Informasi Instrumen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Instrumen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Nama', selected.fullName),
                  _buildInfoRow('Simbol', selected.tabLabel),
                  _buildInfoRow('Negara', selected.country),
                  _buildInfoRow('Jenis', selected.type),
                  _buildInfoRow('Jam Trading', selected.tradingHours),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: primaryPink),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Grafik bersumber dari TradingView dan data harga dari Newsmaker. Ditampilkan untuk tujuan informasi saja.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9F1239),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List: Last, Perubahan, Bid, Ask, Open, High, Low, Waktu
  Widget _buildQuoteList(Map<String, dynamic>? q, int d) {
    final String changePct = (q?['change%'] ?? '-').toString();
    Color changeColor = const Color(0xFF0F172A);
    if (changePct.startsWith('+')) changeColor = upGreen;
    if (changePct.startsWith('-') && changePct.length > 1) {
      changeColor = primaryPink;
    }

    final String time = (q?['time'] ?? '-').toString();

    return Column(
      children: [
        if (_quoteError)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Data live gagal dimuat, mencoba lagi...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Color(0xFF9A3412)),
            ),
          ),
        _buildQuoteRow('Last', _fmt(_num(q, 'last') ?? _num(q, 'price'), d),
            valueColor: changeColor),
        _buildQuoteRow('Perubahan', changePct, valueColor: changeColor),
        _buildQuoteRow('Bid', _fmt(_num(q, 'buy'), d)),
        _buildQuoteRow('Ask', _fmt(_num(q, 'sell'), d)),
        _buildQuoteRow('Open', _fmt(_num(q, 'open'), d)),
        _buildQuoteRow('High', _fmt(_num(q, 'high'), d)),
        _buildQuoteRow('Low', _fmt(_num(q, 'low'), d)),
        _buildQuoteRow('Waktu', time),
      ],
    );
  }

  Widget _buildQuoteRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}