import 'package:flutter/material.dart';

// Model untuk Data Riwayat Perhitungan
class HistoryItem {
  final String id;
  final String type; // 'pivot' atau 'gold'
  final String formattedDate;
  final String formattedTime;
  final String? pair;
  final String? bias; // 'bullish', 'bearish', 'neutral'
  final double? pp;
  final double? r1;
  final double? s1;
  final double? weight;
  final String? purityLabel;
  final double? grandTotal;

  HistoryItem({
    required this.id,
    required this.type,
    required this.formattedDate,
    required this.formattedTime,
    this.pair,
    this.bias,
    this.pp,
    this.r1,
    this.s1,
    this.weight,
    this.purityLabel,
    this.grandTotal,
  });
}

class HistoryScreen extends StatefulWidget {
  final List<HistoryItem> historyItems;
  final Function(String id) onDeleteHistory;
  final Function(HistoryItem item) onRecalculate;
  final Function(HistoryItem item) onOpenDetailModal;

  const HistoryScreen({
    super.key,
    required this.historyItems,
    required this.onDeleteHistory,
    required this.onRecalculate,
    required this.onOpenDetailModal,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = 'all'; // 'all', 'pivot', 'gold', 'month'
  bool _isRefreshing = false;

  void _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 450));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menyegarkan riwayat terkini...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<HistoryItem> get _filteredItems {
    return widget.historyItems.where((item) {
      if (_activeFilter == 'all') return true;
      if (_activeFilter == 'pivot') return item.type == 'pivot';
      if (_activeFilter == 'gold') return item.type == 'gold';
      if (_activeFilter == 'month') return item.formattedDate.contains('Sep');
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Riwayat Perhitungan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daftar kalkulasi pivot point dan emas fisik yang tersimpan secara lokal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _handleRefresh,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: AnimatedRotation(
                    turns: _isRefreshing ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(
                      Icons.cached_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Tabs (Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  id: 'all',
                  label: 'Semua',
                  count: widget.historyItems.length,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  id: 'pivot',
                  label: 'Pivot Point',
                  icon: Icons.show_chart_rounded,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  id: 'gold',
                  label: 'Emas Fisik',
                  icon: Icons.view_in_ar_rounded,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  id: 'month',
                  label: 'Bulan Ini',
                  icon: Icons.calendar_today_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List Cards / Empty State
          if (filtered.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filtered[index];
                if (item.type == 'pivot') {
                  return _buildPivotCard(item);
                } else {
                  return _buildGoldCard(item);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    IconData? icon,
    int? count,
  }) {
    final bool isActive = _activeFilter == id;
    final Color activeBg = const Color(0xFF0F172A);
    final Color activeText = Colors.white;
    final Color inactiveBg = Colors.white;
    final Color inactiveText = const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeBg : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive ? activeText : inactiveText,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isActive ? activeText : inactiveText,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPivotCard(HistoryItem item) {
    final bool isBullish = item.bias == 'bullish';
    final bool isBearish = item.bias == 'bearish';

    Color biasBg = const Color(0xFFF8FAFC);
    Color biasText = const Color(0xFF334155);
    Color biasBorder = const Color(0xFFE2E8F0);
    IconData biasIcon = Icons.swap_horiz_rounded;

    if (isBullish) {
      biasBg = const Color(0xFFECFDF5);
      biasText = const Color(0xFF047857);
      biasBorder = const Color(0xFFA7F3D0);
      biasIcon = Icons.trending_up_rounded;
    } else if (isBearish) {
      biasBg = const Color(0xFFFFF1F2);
      biasText = const Color(0xFFBE123C);
      biasBorder = const Color(0xFFFECDD3);
      biasIcon = Icons.trending_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFF0F172A)),
                        SizedBox(width: 4),
                        Text(
                          'Pivot Point',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.formattedDate} • ${item.formattedTime}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  widget.onDeleteHistory(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item perhitungan telah dihapus.')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Market & Bias Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PASAR KOMODITAS',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    item.pair ?? '-',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: biasBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: biasBorder),
                ),
                child: Row(
                  children: [
                    Icon(biasIcon, size: 15, color: biasText),
                    const SizedBox(width: 4),
                    Text(
                      (item.bias ?? 'NETRAL').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: biasText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Calculation Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'PIVOT (PP)',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.pp?.toStringAsFixed(2) ?? '0.00',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'RESIST 1 (R1)',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFFBE123C), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.r1?.toStringAsFixed(2) ?? '0.00',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'SUPPORT 1 (S1)',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.s1?.toStringAsFixed(2) ?? '0.00',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onOpenDetailModal(item),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Rincian'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onRecalculate(item),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Hitung Ulang'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoldCard(HistoryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.view_in_ar_rounded, size: 14, color: Color(0xFF0F172A)),
                        SizedBox(width: 4),
                        Text(
                          'Emas Fisik',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.formattedDate} • ${item.formattedTime}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  widget.onDeleteHistory(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item perhitungan telah dihapus.')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Specs Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SPESIFIKASI FISIK',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${item.weight ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'gram',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      item.purityLabel ?? '24K',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Summary Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi Total Akhir',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${(item.grandTotal ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onOpenDetailModal(item),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Rincian'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onRecalculate(item),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Hitung Ulang'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 24,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Riwayat',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hasil kalkulasi pivot point atau emas fisik yang Anda simpan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}