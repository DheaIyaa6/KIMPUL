import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:kimpul/screens/tradingview_screen.dart';

class MarketInstrument {
  final String tabLabel;
  final String tabSubtitle;
  final String fullName;
  final String subtitle;
  final String tvSymbol;
  final String price;
  final String open;
  final String close;
  final String high;
  final String low;
  final String change;
  final bool changeIsPositive;
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
    required this.price,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.change,
    required this.changeIsPositive,
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

  final List<MarketInstrument> _instruments = const [
    MarketInstrument(
      tabLabel: 'HSI',
      tabSubtitle: 'Hang Seng',
      fullName: 'Hang Seng Index (HSI)',
      subtitle: 'Indeks Saham Hong Kong',
      tvSymbol: 'INDEX:HSI',
      price: '23.716,50',
      open: '23.409,70',
      close: '23.716,50',
      high: '23.842,30',
      low: '23.410,20',
      change: '+306,80 (+1,31%)',
      changeIsPositive: true,
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
      price: '2.338,80',
      open: '2.326,40',
      close: '2.338,80',
      high: '2.352,10',
      low: '2.328,40',
      change: '+12,40 (+0,53%)',
      changeIsPositive: true,
      country: 'Global (OTC)',
      type: 'Komoditas',
      tradingHours: '24 Jam (Senin-Jumat)',
      icon: Icons.monetization_on_rounded,
      iconColor: Color(0xFFCA8A04),
    ),
    MarketInstrument(
      tabLabel: 'USDJPY',
      tabSubtitle: 'USD / Yen',
      fullName: 'US Dollar / Japanese Yen',
      subtitle: 'Pasangan Mata Uang Forex',
      tvSymbol: 'OANDA:USDJPY',
      price: '149,85',
      open: '149,50',
      close: '149,85',
      high: '150,20',
      low: '149,10',
      change: '+0,35 (+0,23%)',
      changeIsPositive: true,
      country: 'Global (Forex)',
      type: 'Mata Uang',
      tradingHours: '24 Jam (Senin-Jumat)',
      icon: Icons.currency_yen_rounded,
      iconColor: Color(0xFFE93A56),
    ),
  ];

  int _selectedIndex = 0;
  late final List<WebViewController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers =
        _instruments.map((ins) => _buildController(ins.tvSymbol)).toList();
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
                    'Data grafik bersumber dari TradingView dan ditampilkan untuk tujuan informasi saja, bukan rekomendasi jual/beli.',
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
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Open', selected.open),
                      _buildMetric('Close', selected.close),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Tertinggi 24j', selected.high),
                      _buildMetric('Terendah 24j', selected.low),
                      _buildMetric(
                        'Perubahan',
                        selected.change,
                        valueColor: selected.changeIsPositive
                            ? const Color(0xFF059669)
                            : primaryPink,
                      ),
                    ],
                  ),
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
                      'Data grafik bersumber dari TradingView dan ditampilkan untuk tujuan informasi saja.',
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
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
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