import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:kimpul/services/api_service.dart';
import 'package:kimpul/screens/calculatorhub_screen.dart';
import 'package:kimpul/screens/gold_calculator.dart';
import 'package:kimpul/screens/header_screen.dart';
import 'package:kimpul/screens/history_screen.dart';
import 'package:kimpul/screens/login_screen.dart';
import 'package:kimpul/screens/market_overview_screen.dart';
import 'package:kimpul/screens/modals_screen.dart';
import 'package:kimpul/screens/news_screen.dart';
import 'package:kimpul/screens/pivot_calculator.dart';
import 'package:kimpul/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    this.userName = 'Pengguna',
    this.userEmail = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Warna Primary Pink KIMPUL
  static const primaryPink = Color(0xFFE93A56);

  // Timer & Waktu Real-time
  late Timer _timer;
  late DateTime _currentTime;

  // Controller & Timer Slider Berita Auto-Slide
  late PageController _newsPageController;
  Timer? _newsTimer;
  int _currentNewsPage = 0;

  // State navigasi internal di tab Kalkulator
  CalcView? _selectedCalcView;

  // List Riwayat Perhitungan Local State
  final List<dynamic> _historyItems = [];

  // State Berita Live
  List<NewsItem> _liveNewsItems = [];
  bool _isLoadingLiveNews = true;

  List<HistoryItem> _buildLiveHistoryClosingItems() {
    return _liveNewsItems.map((news) {
      return HistoryItem(
        id: 'news-${news.id}',
        type: 'history_closing',
        formattedDate: news.timeAgo,
        formattedTime: news.readTime,
        pair: news.source,
        title: news.title,
        description: news.summary,
        link: news.fullContent,
      );
    }).toList();
  }

  // User Profile
  late UserProfile _userProfile;

  // FUNGSI FETCH LIVE NEWS VIA API SERVICE
  Future<void> _fetchLiveNews() async {
    try {
      final fetchedItems = await ApiService.getTradingViewNews();

      if (mounted) {
        setState(() {
          _liveNewsItems = fetchedItems;
          _isLoadingLiveNews = false;
        });
        if (_liveNewsItems.isNotEmpty) {
          _startNewsAutoSlide();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLiveNews = false;
        });
      }
    }
  }

  // Timer Otomatis Slide 3 Berita
  void _startNewsAutoSlide() {
    _newsTimer?.cancel();
    final carouselNewsCount = _liveNewsItems.take(3).length;
    if (carouselNewsCount == 0) return;

    _newsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _newsPageController.hasClients) {
        if (_currentNewsPage < carouselNewsCount - 1) {
          _currentNewsPage++;
          _newsPageController.animateToPage(
            _currentNewsPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        } else {
          _currentNewsPage = 0;
          _newsPageController.jumpToPage(0);
        }
      }
    });
  }

  // 🌟 MEMBUKA MODAL DETAIL BERITA SAAT BERITA DIKLIK
  void _openNewsDetail(NewsItem news) {
    NewsDetailModal.show(context, news);
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final savedProfile = await ProfileStorage.loadSavedProfile(
        fallbackName: widget.userName,
        fallbackEmail: widget.userEmail,
      );

      if (!mounted) return;
      setState(() {
        _userProfile = UserProfile(
          name: widget.userName.isNotEmpty ? widget.userName : savedProfile.name,
          email: widget.userEmail.isNotEmpty ? widget.userEmail : savedProfile.email,
          avatarUrl: savedProfile.avatarUrl,
        );
      });
    });

    _userProfile = UserProfile(
      name: widget.userName,
      email: widget.userEmail,
      avatarUrl: '',
    );

    // Inisialisasi Waktu Real-time
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _newsPageController = PageController(initialPage: 0);

    // Fetch Berita Live saat Pertama Dimuat
    _fetchLiveNews();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName ||
        oldWidget.userEmail != widget.userEmail) {
      setState(() {
        _userProfile = UserProfile(
          name: widget.userName,
          email: widget.userEmail,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _newsTimer?.cancel();
    _newsPageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedCalcView = null;
    });
  }

  // Tab 0: Beranda
  Widget _buildHomeTab() {
    String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_currentTime);
    String formattedTime = DateFormat('HH:mm:ss', 'id_ID').format(_currentTime);

    final carouselNews = _liveNewsItems.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Tanggal Jam
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(fontSize: 13, color: Color(0xFF515F74)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userProfile.name.isNotEmpty ? _userProfile.name : 'Pengguna',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryPink,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$formattedTime WIB',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: primaryPink,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // HEADER BERITA TERKINI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Berita Terkini Live',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = 1; // Navigasi ke Tab Berita
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 26,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // CAROUSEL BERITA LIVE (3 SLIDE)
          if (_isLoadingLiveNews)
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (carouselNews.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('Gagal memuat berita live'),
              ),
            )
          else ...[
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _newsPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentNewsPage = index;
                  });
                },
                itemCount: carouselNews.length,
                itemBuilder: (context, index) {
                  final news = carouselNews[index];
                  return InkWell(
                    onTap: () => _openNewsDetail(news),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    news.imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFFF1F5F9),
                                        child: const Center(
                                          child: Icon(
                                            Icons.newspaper,
                                            size: 40,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.85),
                                        ],
                                        stops: const [0.3, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  right: 14,
                                  bottom: 12,
                                  child: Text(
                                    news.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    news.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${news.source} • ${news.timeAgo}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            news.readTime,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // DOTS INDIKATOR SLIDER
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                carouselNews.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentNewsPage == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentNewsPage == index
                        ? primaryPink
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Card: Grafik Pasar (ringkasan XAUUSD, Hang Seng, USDJPY)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primaryPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Grafik Pasar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pantau pergerakan XAUUSD, Hang Seng, dan USDJPY secara real-time melalui TradingView.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF515F74),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.trending_up_rounded,
                      color: primaryPink.withValues(alpha: 0.35),
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarketOverviewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded,
                        size: 20, color: Colors.white),
                    label: const Text('Buka Grafik TradingView'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink,
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
              ],
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
                  color: Color(0xFF64748B),
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
                  primaryColor: primaryPink,
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
                  primaryColor: primaryPink,
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
                child: const Text(
                  'Lihat Semua Riwayat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
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
                        Icon(Icons.access_time, size: 20, color: Color(0xFF475569)),
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
                        color: Color(0xFF94A3B8),
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
                        Text('Support 1 (S1)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        SizedBox(height: 4),
                        Text('2.317,50', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    Column(
                      children: const [
                        Text('Pivot (PP)', style: TextStyle(fontSize: 11, color: Color(0xFFE11D48))),
                        SizedBox(height: 4),
                        Text('2.331,50', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                      ],
                    ),
                    Column(
                      children: const [
                        Text('Resistance 1 (R1)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                    children: const [
                      Text(
                        'Buka rincian kalkulasi',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF0F172A)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFE93A56),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.5),
                    children: [
                      TextSpan(
                        text: 'KIMPUL ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: 'merupakan singkatan dari '),
                      TextSpan(
                        text: 'K',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextSpan(text: 'alkulator '),
                      TextSpan(
                        text: 'I',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextSpan(text: 'nformasi '),
                      TextSpan(
                        text: 'M',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextSpan(text: 'arket untuk '),
                      TextSpan(
                        text: 'P',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextSpan(text: 'erhitungan '),
                      TextSpan(
                        text: 'U',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextSpan(text: 'ntung & '),
                      TextSpan(
                        text: 'L',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      TextSpan(
                        text: 'oss, yaitu aplikasi yang dirancang untuk membantu pengguna melakukan berbagai perhitungan dalam aktivitas jual beli emas.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    required Color primaryColor,
  }) {
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
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
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
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  btnText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF0F172A)),
              ],
            ),
          ],
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
    final List<Widget> screens = [
      _buildHomeTab(),
      NewsScreen(
        newsItems: _liveNewsItems,
        onOpenNewsDetail: _openNewsDetail,
      ),
      _buildCalculatorTab(),
      HistoryScreen(
        historyItems: [
          ..._historyItems.whereType<HistoryItem>(),
          ..._buildLiveHistoryClosingItems(),
        ],
        onDeleteHistory: (id) {
          setState(() {
            _historyItems.removeWhere((item) => item.id == id);
          });
        },
        onRecalculate: (item) {},
        onOpenDetailModal: (item) => CalculationDetailModal.show(context, item),
      ),
      ProfileScreen(
        user: _userProfile,
        onRequestLogout: _handleLogout,
        onShowToast: (msg) => ToastNotification.show(context, msg),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: HeaderWidget(
        onOpenNotifications: () {
          NotificationModal.show(context);
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
        selectedItemColor: primaryPink,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
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
}