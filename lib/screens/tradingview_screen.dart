import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingViewScreen extends StatefulWidget {
  const TradingViewScreen({super.key});

  @override
  State<TradingViewScreen> createState() => _TradingViewScreenState();
}

class _TradingViewScreenState extends State<TradingViewScreen> {
  late final WebViewController controller;
  bool _isLoading = true; // State untuk mengontrol visibilitas loading

  @override
  void initState() {
    super.initState();

    // HTML wrapper untuk memuat widget Chart TradingView Interaktif Emas (XAUUSD)
    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body, html { height: 100%; width: 100%; overflow: hidden; background-color: #131722; }
          #tradingview_chart { height: 100vh; width: 100vw; }
        </style>
      </head>
      <body>
        <div class="tradingview-widget-container" style="height:100%;width:100%">
          <div id="tradingview_chart"></div>
          <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
          <script type="text/javascript">
            new TradingView.widget({
              "autosize": true,
              "symbol": "OANDA:XAUUSD",
              "interval": "60",
              "timezone": "Asia/Jakarta",
              "theme": "dark",
              "style": "1", // Candlestick Style
              "locale": "id",
              "toolbar_bg": "#f1f3f6",
              "enable_publishing": false,
              "hide_side_toolbar": false,
              "allow_symbol_change": true,
              "container_id": "tradingview_chart",
              // Menampilkan Indikator Pivot Points Standard (R1, R2, R3 & S1, S2, S3)
              "studies": [
                "STD;Pivot%1Points%1Standard"
              ]
            });
          </script>
        </div>
      </body>
      </html>
    ''';

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF131722))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false; // Matikan loading saat halaman selesai dimuat
              });
            }
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131722),
      appBar: AppBar(
        title: const Text(
          'Grafik Interaktif XAU/USD',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF131722),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 1: WebView Grafik
            WebViewWidget(controller: controller),

            // Layer 2: Indikator Loading
            if (_isLoading)
              Container(
                color: const Color(0xFF131722),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(
                        color: Color(0xFF10B981), // Warna hijau aksen Kimpul
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat Grafik TradingView...',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}