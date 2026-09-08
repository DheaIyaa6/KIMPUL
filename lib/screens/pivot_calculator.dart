import 'package:flutter/material.dart';

// Model Data Kalkulasi Pivot
class PivotCalculation {
  final String id;
  final String timestamp;
  final String formattedDate;
  final String formattedTime;
  final String pair;
  final double high;
  final double low;
  final double close;
  final double pp;
  final double r1;
  final double r2;
  final double r3;
  final double s1;
  final double s2;
  final double s3;
  final String bias; // 'bullish', 'bearish', 'sideway'
  final double diff;
  final String type; // 'pivot'

  PivotCalculation({
    required this.id,
    required this.timestamp,
    required this.formattedDate,
    required this.formattedTime,
    required this.pair,
    required this.high,
    required this.low,
    required this.close,
    required this.pp,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.bias,
    required this.diff,
    this.type = 'pivot',
  });
}

class PivotCalculator extends StatefulWidget {
  final VoidCallback onBack;
  final Function(PivotCalculation calc) onSaveHistory;
  final Function(PivotCalculation calc) onOpenDetailModal;
  final PivotCalculation? initialValues;

  const PivotCalculator({
    super.key,
    required this.onBack,
    required this.onSaveHistory,
    required this.onOpenDetailModal,
    this.initialValues,
  });

  @override
  State<PivotCalculator> createState() => _PivotCalculatorState();
}

class _PivotCalculatorState extends State<PivotCalculator> {
  late TextEditingController _highController;
  late TextEditingController _lowController;
  late TextEditingController _closeController;

  bool _showFormula = true;
  bool _savedSuccess = false;

  @override
  void initState() {
    super.initState();
    _highController = TextEditingController(
        text: (widget.initialValues?.high ?? 2345.50).toStringAsFixed(2));
    _lowController = TextEditingController(
        text: (widget.initialValues?.low ?? 2310.20).toStringAsFixed(2));
    _closeController = TextEditingController(
        text: (widget.initialValues?.close ?? 2338.80).toStringAsFixed(2));
  }

  @override
  void dispose() {
    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  void _handleReset() {
    setState(() {
      _highController.text = '2345.50';
      _lowController.text = '2310.20';
      _closeController.text = '2338.80';
    });
  }

  PivotCalculation _calculate() {
    final double high = double.tryParse(_highController.text) ?? 0.0;
    final double low = double.tryParse(_lowController.text) ?? 0.0;
    final double close = double.tryParse(_closeController.text) ?? 0.0;

    final double pp = double.parse(((high + low + close) / 3).toStringAsFixed(2));
    final double r1 = double.parse(((2 * pp) - low).toStringAsFixed(2));
    final double s1 = double.parse(((2 * pp) - high).toStringAsFixed(2));
    final double r2 = double.parse((pp + (high - low)).toStringAsFixed(2));
    final double s2 = double.parse((pp - (high - low)).toStringAsFixed(2));
    final double r3 = double.parse((high + 2 * (pp - low)).toStringAsFixed(2));
    final double s3 = double.parse((low - 2 * (high - pp)).toStringAsFixed(2));

    final double diff = double.parse((close - pp).toStringAsFixed(2));
    final String bias =
        diff > 0.5 ? 'bullish' : (diff < -0.5 ? 'bearish' : 'sideway');

    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final String formattedDate =
        '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
    final String formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return PivotCalculation(
      id: 'pivot-${now.millisecondsSinceEpoch}',
      timestamp: now.toIso8601String(),
      formattedDate: formattedDate,
      formattedTime: formattedTime,
      pair: 'XAU/USD',
      high: high,
      low: low,
      close: close,
      pp: pp,
      r1: r1,
      r2: r2,
      r3: r3,
      s1: s1,
      s2: s2,
      s3: s3,
      bias: bias,
      diff: diff,
    );
  }

  void _handleSave() async {
    final calc = _calculate();
    widget.onSaveHistory(calc);
    setState(() {
      _savedSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      setState(() {
        _savedSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = _calculate();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back_rounded,
                          size: 18, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Formula Standard Floor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Header
          const Text(
            'Pivot Point Calculator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hitung level pivot harian, support (S1–S3), dan resistance (R1–R3) untuk emas & forex.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // SECTION 1: INPUT DATA HARGA
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
                    const Text(
                      'Input Harga Intraday',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'XAU / USD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),

                _buildInputField('High Price (Tertinggi)', 'H', _highController,
                    Icons.arrow_upward_rounded),
                const SizedBox(height: 12),
                _buildInputField('Low Price (Terendah)', 'L', _lowController,
                    Icons.arrow_downward_rounded),
                const SizedBox(height: 12),
                _buildInputField('Close Price (Penutupan)', 'C', _closeController,
                    Icons.flag_rounded),
                const SizedBox(height: 12),

                // Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _handleReset,
                      child: Row(
                        children: const [
                          Icon(Icons.restart_alt_rounded,
                              size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text(
                            'Reset Nilai',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showFormula = !_showFormula;
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.functions_rounded,
                              size: 16, color: Color(0xFF0F172A)),
                          const SizedBox(width: 4),
                          Text(
                            _showFormula ? 'Tutup Rumus' : 'Lihat Rumus',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SECTION 2: PROSES & RUMUS PERHITUNGAN
          if (_showFormula) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 18, color: Color(0xFF0F172A)),
                          SizedBox(width: 6),
                          Text(
                            'Formula Baku Classical Floor',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Langkah Matematis',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Titik Pivot Inti (PP):',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'PP = (High + Low + Close) / 3',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '= (${calc.high.toStringAsFixed(2)} + ${calc.low.toStringAsFixed(2)} + ${calc.close.toStringAsFixed(2)}) / 3 = ${calc.pp.toStringAsFixed(2)} USD',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'R1 = (2 × PP) - Low\nS1 = (2 × PP) - High',
                            style: TextStyle(fontSize: 11.5, height: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'R2 = PP + (High - Low)\nS2 = PP - (High - Low)',
                            style: TextStyle(fontSize: 11.5, height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // SECTION 3: HASIL PERHITUNGAN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'HASIL PIVOT POINT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          _buildBiasBadge(calc.bias),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'STANDARD PIVOT POINT (PP)',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B)),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            calc.pp.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'USD',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Harga penutupan ${calc.close.toStringAsFixed(2)} berada ${calc.diff >= 0 ? "di atas" : "di bawah"} Pivot Point (${calc.diff >= 0 ? "+${calc.diff.toStringAsFixed(2)}" : calc.diff.toStringAsFixed(2)}).',
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

                // Level Grid (Support & Resistance)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Resistance Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.north_east_rounded,
                                    size: 15, color: Color(0xFFBE123C)),
                                SizedBox(width: 4),
                                Text(
                                  'Resistance (Jual)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFBE123C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildLevelCard('R3 Kuat', calc.r3),
                            const SizedBox(height: 6),
                            _buildLevelCard('R2 Moderat', calc.r2),
                            const SizedBox(height: 6),
                            _buildLevelCard('R1 Minor', calc.r1),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Support Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.south_east_rounded,
                                    size: 15, color: Color(0xFF047857)),
                                SizedBox(width: 4),
                                Text(
                                  'Support (Beli)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildLevelCard('S1 Minor', calc.s1),
                            const SizedBox(height: 6),
                            _buildLevelCard('S2 Moderat', calc.s2),
                            const SizedBox(height: 6),
                            _buildLevelCard('S3 Kuat', calc.s3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Actions
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleSave,
                          icon: Icon(
                            _savedSuccess
                                ? Icons.check_circle_rounded
                                : Icons.bookmark_add_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _savedSuccess
                                ? 'Tersimpan di Riwayat!'
                                : 'Simpan ke Riwayat',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _savedSuccess
                                ? const Color(0xFF059669)
                                : const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => widget.onOpenDetailModal(calc),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Lihat Rincian Lengkap'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8FAFC),
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
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

  Widget _buildInputField(String label, String badge,
      TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155))),
            Text(badge,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            setState(() {});
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            suffixText: 'USD',
            suffixStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(String label, double val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          Text(
            val.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiasBadge(String bias) {
    bool isBullish = bias == 'bullish';
    bool isBearish = bias == 'bearish';

    Color bg = isBullish
        ? const Color(0xFFECFDF5)
        : (isBearish ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC));
    Color border = isBullish
        ? const Color(0xFFA7F3D0)
        : (isBearish ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0));
    Color text = isBullish
        ? const Color(0xFF047857)
        : (isBearish ? const Color(0xFFBE123C) : const Color(0xFF334155));
    IconData icon = isBullish
        ? Icons.trending_up_rounded
        : (isBearish ? Icons.trending_down_rounded : Icons.swap_horiz_rounded);

    String label = isBullish
        ? 'Bullish Bias'
        : (isBearish ? 'Bearish Bias' : 'Neutral Bias');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}