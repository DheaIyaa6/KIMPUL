import 'package:flutter/material.dart';
import 'package:kimpul/screens/tradingview_screen.dart';
import 'package:kimpul/screens/pivot_calculator.dart';
import 'package:kimpul/screens/gold_calculator.dart';
import 'package:kimpul/screens/calculatorhub_screen.dart';
import 'package:kimpul/screens/news_screen.dart';
import 'package:kimpul/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _timeframe = '1D';

  // State untuk navigasi di Pusat Kalkulator
  CalcView? _selectedCalcView;

  // Dummy News Data
  final List<NewsItem> _newsItems = [
    NewsItem(
      id: '1',
      title: 'Ekspektasi Pemangkasan Suku Bunga The Fed Dorong Harga Emas Ke Titik Tertinggi',
      summary: 'Harga emas dunia (XAU/USD) terus menguat di tengah ekspektasi pasar terhadap kebijakan moneter Bank Sentral AS.',
      source: 'Bloomberg Financial',
      timeAgo: '10 mnt lalu',
      readTime: '3 mnt baca',
      category: 'XAU/USD',
      tagType: 'BULLISH',
      imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&w=600&q=80',
      fullContent: 'Isi lengkap berita...',
      featured: true,
    ),
    NewsItem(
      id: '2',
      title: 'Analisis Teknikal Emas: Level Support S1 Berada di Area \$2,330',
      summary: 'Level Pivot harian menunjukkan indikasi konsolidasi sebelum melanjutkan tren naik.',
      source: 'Reuters Forex',
      timeAgo: '1 jam lalu',
      readTime: '2 mnt baca',
      category: 'Analisis',
      tagType: 'ANALISIS',
      imageUrl: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=600&q=80',
      fullContent: 'Isi lengkap berita...',
    ),
  ];

  // Dummy User Profile
  final UserProfile _userProfile = UserProfile(
    name: 'Sobat Kimpul',
    email: 'sobat@kimpul.com',
    phone: '+62 812-3456-7890',
    avatarUrl: 'https://i.pravatar.cc/300',
    clientCode: 'KMP-8892',
    accountNumber: '9928102831',
    branch: 'Surabaya, Indonesia',
  );

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedCalcView = null; // Reset pilihan kalkulator ketika ganti tab
    });
  }

  // Widget Beranda (Tab 0)
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Live Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Selamat Datang,',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Text(
                    'Sobat Kimpul',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Pasar Aktif • XAU',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE4E6)),
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFE11D48),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'XAU / USD',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Loco London',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Spot Gold Kontrak Fisik',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Timeframe Selector
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: ['1D', '1W', '1M'].map((tf) {
                          final isSelected = _timeframe == tf;
                          return GestureDetector(
                            onTap: () => setState(() => _timeframe = tf),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tf,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Section
                const Text(
                  '\$2,345.50',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(Icons.trending_up_rounded,
                        color: Color(0xFF059669), size: 18),
                    SizedBox(width: 4),
                    Text(
                      '+1.24% (+\$28.80)',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'hari ini',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mini Chart
                Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.show_chart_rounded,
                            color: Color(0xFF059669), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Grafik Intraday Tren Emas (Positif)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Strip
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

          // Tombol TradingView Full Chart
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
              icon: const Icon(Icons.candlestick_chart_rounded, size: 20),
              label: const Text('Buka Grafik Interaktif TradingView'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
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

          // Akses Cepat Kalkulator
          const Text(
            'FITUR KALKULATOR UTAMA',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Pivot Point',
                  subtitle: 'Support & Resistance',
                  icon: Icons.calculate_rounded,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                      _selectedCalcView = CalcView.pivot;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Emas Fisik',
                  subtitle: 'Simulasi Gram & Pajak',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                      _selectedCalcView = CalcView.gold;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Tampilan Tab Kalkulator
  Widget _buildCalculatorTab() {
    if (_selectedCalcView == CalcView.pivot) {
      return PivotCalculator(
        onBack: () {
          setState(() {
            _selectedCalcView = null;
          });
        },
        onSaveHistory: (calc) {
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
      _buildCalculatorTab(),
      NewsScreen(
        newsItems: _newsItems,
        onOpenNewsDetail: (news) {},
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE93A56).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: Color(0xFFE93A56),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Beranda Kimpul',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada notifikasi baru')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
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
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate_rounded),
            label: 'Kalkulator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper_rounded),
            label: 'Berita',
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
            color: Color(0xFF64748B),
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

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
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
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}