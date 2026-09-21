import 'package:flutter/material.dart';
import 'package:kimpul/services/api_service.dart';

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
  int _loadedCount = 4;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isLoadingLive = true;

  // List internal untuk menampung berita Live
  List<NewsItem> _liveNewsItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Jika dari HomeScreen sudah membawa data berita, langsung pakai
    if (widget.newsItems.isNotEmpty) {
      _liveNewsItems = widget.newsItems;
      _isLoadingLive = false;
    } else {
      // Ambil Berita Live via Backend Laragon saat Pertama kali Layar Dimuat
      _fetchLiveNews();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FUNGSI FETCH LIVE NEWS VIA BACKEND LARAGON (PHP PROXY)
  Future<void> _fetchLiveNews() async {
    try {
      final fetchedItems = await ApiService.getTradingViewNews();

      if (mounted) {
        setState(() {
          if (fetchedItems.isNotEmpty) {
            _liveNewsItems = fetchedItems;
          } else {
            _liveNewsItems = widget.newsItems;
          }
          _isLoadingLive = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liveNewsItems = widget.newsItems;
          _isLoadingLive = false;
        });
      }
    }
  }

  List<NewsItem> get _activeNewsList {
    return _liveNewsItems.isNotEmpty ? _liveNewsItems : widget.newsItems;
  }

  List<NewsItem> get _filteredNews {
    return _activeNewsList.where((item) {
      final query = _searchQuery.toLowerCase().trim();

      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      return matchesSearch;
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

  // REFRESH BERITA LIVE
  void _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _fetchLiveNews();

    if (mounted) {
      setState(() {
        _loadedCount = 4;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final filtered = _filteredNews;

    // Penanganan featured article
    NewsItem? featuredArticle;

    for (final n in _activeNewsList) {
      if (n.featured) {
        featuredArticle = n;
        break;
      }
    }

    featuredArticle ??=
        _activeNewsList.isNotEmpty ? _activeNewsList.first : null;

    final regularArticles =
        filtered.where((n) => n.id != featuredArticle?.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        bottom: 24,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Intro Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
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

              // REAL-TIME FEED + REFRESH
              Row(
                children: [
                  IconButton(
                    onPressed: _isRefreshing ? null : _handleRefresh,
                    icon: _isRefreshing || _isLoadingLive
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF515F74),
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Color(0xFF515F74),
                          ),
                    tooltip: 'Refresh berita',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
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
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF515F74),
            ),
          ),

          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Cari berita komoditas, pasar, atau The Fed...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
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
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_isLoadingLive) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ] else ...[
            // HERO FEATURED ARTICLE (LANGSUNG DIBAWAH SEARCH BAR)
            if (featuredArticle != null &&
                featuredArticle.title.isNotEmpty &&
                _searchQuery.isEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'SOROTAN UTAMA',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF515F74),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Pilihan Editor',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
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
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: Image.network(
                                featuredArticle.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
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
                                    Colors.black.withValues(
                                      alpha: 0.85,
                                    ),
                                  ],
                                  stops: const [0.3, 1.0],
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 12,
                            left: 14,
                            right: 14,
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
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${featuredArticle.source} • ${featuredArticle.timeAgo}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF515F74),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: Color(0xFF515F74),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      featuredArticle.readTime,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF515F74),
                                      ),
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

              const SizedBox(height: 20),
            ],

            // LATEST NEWS LIST
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'KABAR PASAR TERKINI',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF515F74),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Terbaru',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: regularArticles.take(_loadedCount).length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
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
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
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
                                  Container(
                                color: const Color(0xFFF8FAFC),
                                child: const Icon(
                                  Icons.newspaper,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      article.category,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    article.timeAgo,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF515F74),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

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

                              Text(
                                article.source,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
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
              },
            ),

            // Load More Button
            if (_loadedCount < regularArticles.length) ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingMore ? null : _handleLoadMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Muat Lebih Banyak',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}