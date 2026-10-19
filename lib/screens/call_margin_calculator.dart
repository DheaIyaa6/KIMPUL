import 'package:flutter/material.dart';

class _MarginProduct {
  final String label;
  final String subtitle;
  final double contractSize; // $
  final double mrOvernight; // per lot
  final double mrDay; // per lot

  const _MarginProduct({
    required this.label,
    required this.subtitle,
    required this.contractSize,
    required this.mrOvernight,
    required this.mrDay,
  });
}

class _MarginCategory {
  final String label;
  final double percent; // 0.7 = 70%
  const _MarginCategory(this.label, this.percent);
}

class _MarginResult {
  final double marginUsed; // persen x MR x lot
  final double callMargin; // dalam poin
  final double buyLevel;
  final double sellLevel;
  final bool equityEnough;

  const _MarginResult({
    required this.marginUsed,
    required this.callMargin,
    required this.buyLevel,
    required this.sellLevel,
    required this.equityEnough,
  });
}

class CallMarginCalculator extends StatefulWidget {
  final VoidCallback onBack;

  const CallMarginCalculator({super.key, required this.onBack});

  @override
  State<CallMarginCalculator> createState() => _CallMarginCalculatorState();
}

class _CallMarginCalculatorState extends State<CallMarginCalculator> {
  static const Color _buyColor = Color(0xFF059669);
  static const Color _sellColor = Color(0xFFE11D48);

  static const List<_MarginProduct> _products = [
    _MarginProduct(
        label: 'XUL',
        subtitle: 'Gold / USD',
        contractSize: 100,
        mrOvernight: 3000,
        mrDay: 1000),
    _MarginProduct(
        label: 'HKK',
        subtitle: 'Hang Seng',
        contractSize: 5,
        mrOvernight: 2000,
        mrDay: 1000),
    _MarginProduct(
        label: 'JPK',
        subtitle: 'Nikkei 225',
        contractSize: 5,
        mrOvernight: 2000,
        mrDay: 1000),
  ];

  static const List<_MarginCategory> _categories = [
    _MarginCategory('CMON', 0.7),
    _MarginCategory('CMD', 0.7),
    _MarginCategory('CMAL', 0.3),
  ];

  final _equityC = TextEditingController();
  final _lotC = TextEditingController();
  final _entryC = TextEditingController();

  int _productIndex = 0;
  int _categoryIndex = 0;
  bool _overnight = true; // true = ON, false = Day
  bool _isBuy = true;
  _MarginResult? _result;

  _MarginProduct get _product => _products[_productIndex];
  _MarginCategory get _category => _categories[_categoryIndex];
  double get _mr => _overnight ? _product.mrOvernight : _product.mrDay;

  @override
  void dispose() {
    _equityC.dispose();
    _lotC.dispose();
    _entryC.dispose();
    super.dispose();
  }

  String _f(double v) => v.toStringAsFixed(2);
  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _calculate() {
    FocusScope.of(context).unfocus();
    final equity = _parse(_equityC.text);
    final lot = _parse(_lotC.text);
    final entry = _parse(_entryC.text);

    if (equity == null || lot == null || entry == null) {
      _snack('Isi Equity, Lot, dan Harga Masuk dengan angka yang valid.');
      return;
    }
    if (lot <= 0) {
      _snack('Lot harus lebih besar dari 0.');
      return;
    }

    // Call Margin (poin) = (Equity - persen x MR x lot) / (contract size x lot)
    final marginUsed = _category.percent * _mr * lot;
    final callMargin = (equity - marginUsed) / (_product.contractSize * lot);

    setState(() {
      _result = _MarginResult(
        marginUsed: marginUsed,
        callMargin: callMargin,
        buyLevel: entry - callMargin,
        sellLevel: entry + callMargin,
        equityEnough: equity > marginUsed,
      );
    });
  }

  void _reset() {
    setState(() {
      _equityC.clear();
      _lotC.clear();
      _entryC.clear();
      _result = null;
    });
  }

  void _invalidate() {
    if (_result != null) setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 18, color: primary),
                  const SizedBox(width: 4),
                  Text('Kembali',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Call Margin Calculator',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hitung batas call margin (poin) dan level harganya untuk posisi Buy / Sell.',
            style: TextStyle(fontSize: 13, color: Color(0xFF515F74)),
          ),
          const SizedBox(height: 16),

          // Pilihan produk
          Row(
            children: List.generate(_products.length, (i) {
              final p = _products[i];
              final selected = i == _productIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i == _products.length - 1 ? 0 : 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _productIndex = i);
                      _invalidate();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected
                                ? primary
                                : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Text(p.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF0F172A))),
                          Text(p.subtitle,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parameter',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                _label('Kategori Margin'),
                _chipRow(
                  List.generate(_categories.length, (i) {
                    final c = _categories[i];
                    return _choice(
                      '${c.label} (${(c.percent * 100).toInt()}%)',
                      i == _categoryIndex,
                      primary,
                      () {
                        setState(() => _categoryIndex = i);
                        _invalidate();
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                _label('Margin Requirement per Lot'),
                _chipRow([
                  _choice('Overnight (${_product.mrOvernight.toInt()})',
                      _overnight, primary, () {
                    setState(() => _overnight = true);
                    _invalidate();
                  }),
                  _choice('Day (${_product.mrDay.toInt()})', !_overnight,
                      primary, () {
                    setState(() => _overnight = false);
                    _invalidate();
                  }),
                ]),
                const SizedBox(height: 12),
                _label('Posisi'),
                _chipRow([
                  _choice('Buy', _isBuy, _buyColor, () {
                    setState(() => _isBuy = true);
                  }),
                  _choice('Sell', !_isBuy, _sellColor, () {
                    setState(() => _isBuy = false);
                  }),
                ]),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _field('Equity', _equityC, '\$', primary),
                const SizedBox(height: 12),
                _field('Jumlah Lot', _lotC, 'lot', primary),
                const SizedBox(height: 12),
                _field('Harga Masuk', _entryC, 'poin', primary),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate_rounded, size: 18),
                    label: const Text('Hitung'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _reset,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt_rounded,
                          size: 16, color: Color(0xFF515F74)),
                      SizedBox(width: 4),
                      Text('Reset Nilai',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF515F74))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_result != null) _buildResult(_result!, primary),
          if (_result != null) const SizedBox(height: 12),

          _buildFormulaCard(),
        ],
      ),
    );
  }

  // ---------- Hasil ----------

  Widget _buildResult(_MarginResult r, Color primary) {
    final posColor = _isBuy ? _buyColor : _sellColor;
    final level = _isBuy ? r.buyLevel : r.sellLevel;
    final equity = _parse(_equityC.text) ?? 0;
    final lot = _parse(_lotC.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HASIL CALL MARGIN',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF515F74),
                      letterSpacing: 0.5)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: posColor, borderRadius: BorderRadius.circular(20)),
                child: Text(_isBuy ? 'BUY' : 'SELL',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!r.equityEnough)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Text(
                'Equity lebih kecil dari margin yang dipakai, jadi call margin bernilai negatif. Cek lagi Equity atau jumlah lot.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
              ),
            ),
          const Text('CALL MARGIN',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF515F74))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_f(r.callMargin),
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: primary,
                      letterSpacing: -0.5)),
              const SizedBox(width: 6),
              const Text('poin',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF515F74))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: posColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: posColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Level Call Margin ${_isBuy ? "Buy" : "Sell"}',
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF515F74))),
                const SizedBox(height: 2),
                Text(_f(level),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: posColor)),
                const SizedBox(height: 2),
                Text(
                    _isBuy
                        ? 'Harga Masuk - Call Margin'
                        : 'Harga Masuk + Call Margin',
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _metric('Level Buy', _f(r.buyLevel), _buyColor)),
              Expanded(
                  child: _metric('Level Sell', _f(r.sellLevel), _sellColor)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('LANGKAH HITUNG',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Margin dipakai = ${(_category.percent * 100).toInt()}% × ${_f(_mr)} × ${_f(lot)} = ${_f(r.marginUsed)}\n'
              'Call Margin = (${_f(equity)} - ${_f(r.marginUsed)}) / (${_product.contractSize.toInt()} × ${_f(lot)})\n'
              '= ${_f(equity - r.marginUsed)} / ${_f(_product.contractSize * lot)}\n'
              '= ${_f(r.callMargin)} poin',
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFF334155), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rumus Call Margin',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          SizedBox(height: 8),
          Text(
            'Call Margin = (Equity - persen × MR × lot) / (contract size × lot)',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                height: 1.4),
          ),
          SizedBox(height: 8),
          Text(
            'Persen margin: 70% untuk CMON dan CMD, 30% untuk CMAL.\n'
            'Buy: Harga Masuk - Call Margin\n'
            'Sell: Harga Masuk + Call Margin',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF64748B), height: 1.6),
          ),
        ],
      ),
    );
  }

  // ---------- Widget bantu ----------

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155))),
      );

  Widget _chipRow(List<Widget> children) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );

  Widget _choice(String text, bool selected, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF334155))),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _field(String label, TextEditingController c, String suffix,
      Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _invalidate(),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCBD5E1)),
            suffixText: suffix,
            suffixStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF515F74)),
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
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}