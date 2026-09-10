import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kimpul/screens/header_screen.dart';
import 'package:kimpul/screens/tradingview_screen.dart';
import 'package:kimpul/screens/pivot_calculator.dart';
import 'package:kimpul/screens/gold_calculator.dart';
import 'package:kimpul/screens/calculatorhub_screen.dart';
import 'package:kimpul/screens/news_screen.dart';
import 'package:kimpul/screens/history_screen.dart';
import 'package:kimpul/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Controller WebView untuk Mini Chart
  late final WebViewController _miniChartController;

  // State navigasi internal di tab Kalkulator
  CalcView? _selectedCalcView;

  // List Riwayat Perhitungan Local State
  final List<dynamic> _historyItems = [];

  // Dummy News Data
  final List<NewsItem> _newsItems = [
    NewsItem(
      id: '1',
      title: 'Emas Mendekati Level Tertinggi Sepanjang Masa di Tengah...',
      summary: 'Harga emas dunia (XAU/USD) terus menguat di tengah ekspektasi pasar terhadap kebijakan moneter Bank Sentral AS.',
      source: 'TradingView Newsroom',
      timeAgo: '12m lalu',
      readTime: '3 mnt baca',
      category: 'XAU/USD',
      tagType: 'BULLISH',
      imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
      fullContent: 'Isi lengkap berita...',
      featured: true,
    ),
    NewsItem(
      id: '2',
      title: 'Analisis Teknikal XAU/USD: Pola Breakout Menguji Resistance...',
      summary: 'Level Pivot harian menunjukkan indikasi konsolidasi sebelum melanjutkan tren naik.',
      source: 'TradingView / Analyst',
      timeAgo: '28m lalu',
      readTime: '2 mnt baca',
      category: 'Analisis',
      tagType: 'ANALISIS',
      imageUrl: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=600&q=80',
      fullContent: 'Isi lengkap berita...',
    ),
  ];

  // Dummy User Profile
  final UserProfile _userProfile = UserProfile(
    name: 'Dhea Ananda',
    email: 'dhea@kimpul.com',
    phone: '+62 812-3456-7890',
    avatarUrl: 'https://i.pravatar.cc/300',
    clientCode: 'KMP-8892',
    accountNumber: '9928102831',
    branch: 'Surabaya, Indonesia',
  );

  // Fungsi Pengecekan Status Aktif/Tutup Pasar Emas Dunia (XAUUSD)
  bool _isMarketActive() {
    final now = DateTime.now().toUtc();
    final weekday = now.weekday; // 1 = Senin, ..., 6 = Sabtu, 7 = Minggu
    final hour = now.hour;

    // 1. Libur Akhir Pekan (Weekend)
    if (weekday == DateTime.saturday) return false;
    if (weekday == DateTime.sunday && hour < 22) return false; // Belum jam 05.00 WIB Senin
    if (weekday == DateTime.friday && hour >= 21) return false;  // Sudah lewat jam 04.00 WIB Sabtu

    // 2. Daily Closing Break (Istirahat Harian Pasar Emas: ~04:00 - 05:00 WIB)
    if (hour == 21) {
      return false;
    }

    return true; // Pasar Aktif
  }

  @override
  void initState() {
    super.initState();
    _initMiniChartWidget();
  }

  // Inisialisasi TradingView Mini Chart Widget
  void _initMiniChartWidget() {
    final String miniChartHtml = '''
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
            "symbol": "OANDA:XAUUSD",
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

    _miniChartController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(miniChartHtml);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedCalcView = null;
    });
  }

  // Tab 0: Beranda
  Widget _buildHomeTab() {
    final bool marketActive = _isMarketActive();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting User
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang',
                style: TextStyle(fontSize: 13, color: Color(0xFF515F74)),
              ),
              const SizedBox(height: 2),
              Text(
                'Dhea Ananda',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Tentang KIMPUL
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Tentang KIMPUL',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Identitas Resmi Aplikasi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF515F74),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'K • I • M • P • U • L',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.5),
                    children: [
                      const TextSpan(
                        text: 'KIMPUL ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: 'merupakan singkatan dari '),
                      TextSpan(
                        text: 'K',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const TextSpan(text: 'alkulator '),
                      TextSpan(
                        text: 'I',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const TextSpan(text: 'nformasi '),
                      TextSpan(
                        text: 'M',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const TextSpan(text: 'arket untuk '),
                      TextSpan(
                        text: 'P',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const TextSpan(text: 'erhitungan '),
                      TextSpan(
                        text: 'U',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const TextSpan(text: 'ntung & '),
                      TextSpan(
                        text: 'L',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const TextSpan(
                        text: 'oss, yaitu aplikasi yang dirancang untuk membantu pengguna melakukan berbagai perhitungan dalam aktivitas jual beli emas.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildAbbrTile('K', 'alkulator')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAbbrTile('I', 'nformasi')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAbbrTile('M', 'arket')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildAbbrTile('P', 'erhitungan')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAbbrTile('U', 'ntung')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAbbrTile('L', 'oss')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Market Hero Card: Gold Spot
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primaryColor, // Latar belakang icon Primary Color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.white, // Icon warna Putih
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'XAU / USD Loco London',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Spot Gold Kontrak Fisik',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF515F74),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // STATUS PASAR REAL-TIME
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: marketActive ? const Color(0xFF10B981) : primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            marketActive ? 'Pasar Aktif' : 'Pasar Tutup',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: marketActive ? const Color(0xFF059669) : primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // BOX GRAFIK TRADINGVIEW
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: IgnorePointer(
                      ignoring: true,
                      child: WebViewWidget(controller: _miniChartController),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem('Tertinggi 24j', '\$2,352.10'),
                    _buildMetricItem('Terendah 24j', '\$2,328.40'),
                    _buildMetricItem('Kurs Acuan', 'Rp 16.240'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol TradingView Full (Dominan Primary Color)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TradingViewScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.candlestick_chart_rounded, size: 20, color: Colors.white),
              label: const Text('Buka Grafik Interaktif TradingView'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Menggunakan Primary Color
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // SECTION: Kalkulasi Cepat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Kalkulasi Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Pilih Model',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF515F74),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickCalcCard(
                  title: 'Pivot Point',
                  subtitle: 'Level Support &\nResistance intraday...',
                  btnText: 'Buka Kalkulator',
                  icon: Icons.calculate_outlined,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                      _selectedCalcView = CalcView.pivot;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickCalcCard(
                  title: 'Emas Fisik',
                  subtitle: 'Estimasi gramatur,\nkarat, cetak & PPh 22.',
                  btnText: 'Simulasi Fisik',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                      _selectedCalcView = CalcView.gold;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SECTION: Perhitungan Terakhir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Perhitungan Terakhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
                child: Text(
                  'Lihat Semua Riwayat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card Hasil Perhitungan Terakhir
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.access_time, size: 20, color: Color(0xFF515F74)),
                        SizedBox(width: 8),
                        Text(
                          'Pivot Point Harian',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      '02 Sep 2026, 14:30',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF515F74),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: const [
                        Text('Support 1 (S1)', style: TextStyle(fontSize: 11, color: Color(0xFF515F74))),
                        SizedBox(height: 4),
                        Text('2.317,50', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Pivot (PP)', style: TextStyle(fontSize: 11, color: Color(0xFF515F74))),
                        const SizedBox(height: 4),
                        Text('2.331,50', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
                      ],
                    ),
                    Column(
                      children: const [
                        Text('Resistance 1 (R1)', style: TextStyle(fontSize: 11, color: Color(0xFF515F74))),
                        SizedBox(height: 4),
                        Text('2.352,80', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Buka rincian kalkulasi',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECTION: Kabar Emas Terkini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Kabar Emas Terkini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Wawasan Pasar',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF515F74),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // News Card Items
          _buildHomeNewsTile(
            title: 'Emas Mendekati Level Tertinggi Sepanjang Masa di Tengah...',
            source: 'TradingView Newsroom',
            timeAgo: '12m lalu',
            tag: 'BULLISH',
            tagColor: const Color(0xFF059669),
            tagBg: const Color(0xFFECFDF5),
            imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildHomeNewsTile(
            title: 'Analisis Teknikal XAU/USD: Pola Breakout Menguji Resistance...',
            source: 'TradingView / Analyst',
            timeAgo: '28m lalu',
            tag: 'ANALISIS',
            tagColor: primaryColor,
            tagBg: primaryColor.withValues(alpha: 0.1),
            imageUrl: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=600&q=80',
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCalcCard({
    required String title,
    required String subtitle,
    required String btnText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor, // Background Primary Color
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20), // Icon Putih
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF515F74),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  btnText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeNewsTile({
    required String title,
    required String source,
    required String timeAgo,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.newspaper, color: Color(0xFF94A3B8)),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: tagColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$source • $timeAgo',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF515F74),
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

  Widget _buildAbbrTile(String letter, String word) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF515F74)),
            children: [
              TextSpan(
                text: '$letter ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              TextSpan(text: word),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorTab() {
    if (_selectedCalcView == CalcView.pivot) {
      return PivotCalculator(
        onBack: () {
          setState(() {
            _selectedCalcView = null;
          });
        },
        onSaveHistory: (calc) {
          setState(() {
            _historyItems.add(calc);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perhitungan Pivot disimpan!')),
          );
        },
        onOpenDetailModal: (calc) {},
      );
    } else if (_selectedCalcView == CalcView.gold) {
      return GoldCalculator(
        onBack: () {
          setState(() {
            _selectedCalcView = null;
          });
        },
        onSaveHistory: (calc) {
          setState(() {
            _historyItems.add(calc);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perhitungan Emas Fisik disimpan!')),
          );
        },
        onOpenDetailModal: (calc) {},
      );
    } else {
      return CalcHubScreen(
        onSelectCalc: (view) {
          setState(() {
            _selectedCalcView = view;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final List<Widget> screens = [
      _buildHomeTab(),
      NewsScreen(
        newsItems: _newsItems,
        onOpenNewsDetail: (news) {},
      ),
      _buildCalculatorTab(),
      HistoryScreen(
        historyItems: List.from(_historyItems),
        onDeleteHistory: (id) {
          setState(() {
            _historyItems.removeWhere((item) => item.id == id);
          });
        },
        onRecalculate: (item) {},
        onOpenDetailModal: (item) {},
      ),
      ProfileScreen(
        user: _userProfile,
        onOpenEditProfile: () {},
        onOpenChangePassword: () {},
        onRequestLogout: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil keluar akun')),
          );
        },
        onShowToast: (msg) {},
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderWidget(
        onOpenNotifications: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada notifikasi baru')),
          );
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF515F74),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper_rounded),
            label: 'Berita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate_rounded),
            label: 'Kalkulator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF515F74),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}