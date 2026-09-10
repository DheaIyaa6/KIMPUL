import 'package:flutter/material.dart';

// Model Berita untuk Flutter
class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String timeAgo;
  final String readTime;
  final String category;
  final String tagType;
  final String imageUrl;
  final String fullContent;
  final bool featured;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.timeAgo,
    required this.readTime,
    required this.category,
    required this.tagType,
    required this.imageUrl,
    required this.fullContent,
    this.featured = false,
  });
}

class NewsScreen extends StatefulWidget {
  final List<NewsItem> newsItems;
  final Function(NewsItem news) onOpenNewsDetail;

  const NewsScreen({
    super.key,
    required this.newsItems,
    required this.onOpenNewsDetail,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeCategory = 'all';
  int _loadedCount = 4;
  bool _isLoadingMore = false;
  String? _userSentiment; // 'bullish', 'neutral', 'bearish'

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': 'Semua'},
    {'id': 'xau', 'label': 'XAU/USD'},
    {'id': 'fed', 'label': 'Kebijakan The Fed'},
    {'id': 'bullish', 'label': 'Sentimen Bullish'},
    {'id': 'technical', 'label': 'Analisis Teknikal'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NewsItem> get _filteredNews {
    return widget.newsItems.where((item) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      if (_activeCategory == 'all') return true;
      if (_activeCategory == 'xau') {
        return item.title.contains('XAU') || item.title.contains('Emas');
      }
      if (_activeCategory == 'fed') {
        return item.tagType == 'FED POLICY' ||
            item.title.contains('Fed') ||
            item.title.contains('Powell');
      }
      if (_activeCategory == 'bullish') return item.tagType == 'BULLISH';
      if (_activeCategory == 'technical') {
        return item.tagType == 'ANALISIS' || item.title.contains('Teknikal');
      }

      return true;
    }).toList();
  }

  void _handleLoadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _loadedCount += 3;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final filtered = _filteredNews;

    // Penanganan featured article
    NewsItem? featuredArticle;
    for (final n in widget.newsItems) {
      if (n.featured) {
        featuredArticle = n;
        break;
      }
    }
    featuredArticle ??= widget.newsItems.isNotEmpty ? widget.newsItems.first : null;

    final regularArticles = filtered.where((n) => n.id != featuredArticle?.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Intro Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PASAR XAU/USD AKTIF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.update_rounded, size: 15, color: Color(0xFF515F74)),
                  SizedBox(width: 4),
                  Text(
                    'Real-time Feed',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF515F74),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Berita & Analisa Pasar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Sentimen pasar terkini dan katalis fundamental komoditas emas XAU/USD.',
            style: TextStyle(fontSize: 13, color: Color(0xFF515F74)),
          ),
          const SizedBox(height: 16),

          // Search Field (Focused Border -> Primary Color)
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Cari berita komoditas, pasar, atau The Fed...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips Scroller (Aktif -> Primary Color)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final bool isActive = _activeCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeCategory = cat['id']!;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? primaryColor : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : const Color(0xFF515F74),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Mini Market Ticker Strip
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('SPOT GOLD (XAU)',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF515F74),
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('\$2,348.60',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text('+1.42%',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857))),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('USD/IDR KURS',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF515F74),
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('Rp 16.240',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text('-0.18%',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // HERO FEATURED ARTICLE
          if (featuredArticle != null &&
              featuredArticle.title.isNotEmpty &&
              _activeCategory == 'all' &&
              _searchQuery.isEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('SOROTAN UTAMA',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF515F74),
                        letterSpacing: 0.5)),
                Text('Pilihan Editor',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => widget.onOpenNewsDetail(featuredArticle!),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: Image.network(
                              featuredArticle.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: const Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Utama',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Bullish',
                                style: TextStyle(
                                    color: Color(0xFF047857),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Text(
                            featuredArticle.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            featuredArticle.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF515F74),
                                height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${featuredArticle.source} • ${featuredArticle.timeAgo}',
                                style: const TextStyle(
                                    fontSize: 11.5, color: Color(0xFF515F74)),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 14, color: Color(0xFF515F74)),
                                  const SizedBox(width: 4),
                                  Text(
                                    featuredArticle.readTime,
                                    style: const TextStyle(
                                        fontSize: 11.5, color: Color(0xFF515F74)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // LATEST NEWS LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('KABAR PASAR TERKINI',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF515F74),
                      letterSpacing: 0.5)),
              Text('Terbaru',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: regularArticles.take(_loadedCount).length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final article = regularArticles[index];
              return InkWell(
                onTap: () => widget.onOpenNewsDetail(article),
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
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: const Color(0xFFF8FAFC)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    article.category,
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor),
                                  ),
                                ),
                                Text(
                                  article.timeAgo,
                                  style: const TextStyle(
                                      fontSize: 10.5, color: Color(0xFF515F74)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    article.source,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF515F74)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    article.tagType,
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Load More Button
          if (_loadedCount < regularArticles.length) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoadingMore ? null : _handleLoadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoadingMore
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text('Memuat berita...',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.expand_more_rounded,
                              size: 18, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Muat Lebih Banyak Berita',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // COMMUNITY SENTIMENT POLL SECTION
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
                        Icon(Icons.poll_rounded,
                            size: 18, color: Color(0xFF0F172A)),
                        SizedBox(width: 6),
                        Text('Sentimen Komunitas',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text('78% Bullish',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bar Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                            flex: 78,
                            child: Container(color: const Color(0xFF10B981))),
                        Expanded(
                            flex: 14,
                            child: Container(color: const Color(0xFF94A3B8))),
                        Expanded(
                            flex: 8,
                            child: Container(color: primaryColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSentimentChip(
                      id: 'bullish',
                      label: 'Bullish (78%)',
                      color: const Color(0xFF10B981),
                    ),
                    _buildSentimentChip(
                      id: 'neutral',
                      label: 'Netral (14%)',
                      color: const Color(0xFF94A3B8),
                    ),
                    _buildSentimentChip(
                      id: 'bearish',
                      label: 'Bearish (8%)',
                      color: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentChip({
    required String id,
    required String label,
    required Color color,
  }) {
    final bool isSelected = _userSentiment == id;
    return InkWell(
      onTap: () {
        setState(() {
          _userSentiment = id;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : const Color(0xFF515F74),
              ),
            ),
          ],
        ),
      ),
    );
  }
}