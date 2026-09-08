import 'package:flutter/material.dart';

// Model Data Kalkulasi Emas Fisik
class GoldCalculation {
  final String id;
  final String timestamp;
  final String formattedDate;
  final String formattedTime;
  final String transactionType; // 'buy' | 'sell'
  final double weight;
  final double purityValue;
  final String purityLabel;
  final double basePrice;
  final bool hasNpwp;
  final double mintCost;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final double buybackEstimate;
  final String type; // 'gold'

  GoldCalculation({
    required this.id,
    required this.timestamp,
    required this.formattedDate,
    required this.formattedTime,
    required this.transactionType,
    required this.weight,
    required this.purityValue,
    required this.purityLabel,
    required this.basePrice,
    required this.hasNpwp,
    required this.mintCost,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    required this.buybackEstimate,
    this.type = 'gold',
  });
}

class GoldCalculator extends StatefulWidget {
  final VoidCallback onBack;
  final Function(GoldCalculation calc) onSaveHistory;
  final Function(GoldCalculation calc) onOpenDetailModal;
  final GoldCalculation? initialValues;

  const GoldCalculator({
    super.key,
    required this.onBack,
    required this.onSaveHistory,
    required this.onOpenDetailModal,
    this.initialValues,
  });

  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator> {
  late String _transactionType;
  late TextEditingController _weightController;
  late double _purityValue;
  late TextEditingController _basePriceController;
  late bool _hasNpwp;

  bool _showFormula = true;
  bool _savedSuccess = false;

  // Hapus kata kunci 'const' agar Map dengan key double diperbolehkan
  final Map<double, String> _purityLabelMap = {
    1.0: '99.99% (24 Karat - Fine Gold LBMA)',
    0.995: '99.50% (24 Karat Standar Lokal)',
    0.916: '91.60% (22 Karat Batangan Koleksi)',
  };

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialValues?.transactionType ?? 'buy';
    _weightController = TextEditingController(
        text: (widget.initialValues?.weight ?? 50.0).toStringAsFixed(0));
    _purityValue = widget.initialValues?.purityValue ?? 1.0;
    _basePriceController = TextEditingController(
        text: (widget.initialValues?.basePrice ?? 1150000.0).toStringAsFixed(0));
    _hasNpwp = widget.initialValues?.hasNpwp ?? true;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  double _getMintCost(double grams) {
    if (grams <= 5) return 50000;
    if (grams <= 10) return 75000;
    if (grams <= 25) return 100000;
    if (grams <= 50) return 150000;
    return 250000;
  }

  String _formatRupiah(double num) {
    int val = num.round();
    String str = val.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  void _handleReset() {
    setState(() {
      _weightController.text = '50';
      _basePriceController.text = '1150000';
      _purityValue = 1.0;
      _hasNpwp = true;
      _transactionType = 'buy';
    });
  }

  GoldCalculation _calculate() {
    final double weight = double.tryParse(_weightController.text) ?? 1.0;
    final double basePrice = double.tryParse(_basePriceController.text) ?? 0.0;

    final double mintCost =
        _transactionType == 'buy' ? _getMintCost(weight) : 0.0;
    final double rawBaseTotal = weight * _purityValue * basePrice;
    final double subtotal = rawBaseTotal + mintCost;
    final double taxRate = _hasNpwp ? 0.0025 : 0.005;
    final double taxAmount = (subtotal * taxRate).roundToDouble();
    final double grandTotal =
        subtotal + (_transactionType == 'buy' ? taxAmount : -taxAmount);
    final double buybackEstimate = (rawBaseTotal * 0.916).roundToDouble();

    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final String formattedDate =
        '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
    final String formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return GoldCalculation(
      id: 'gold-${now.millisecondsSinceEpoch}',
      timestamp: now.toIso8601String(),
      formattedDate: formattedDate,
      formattedTime: formattedTime,
      transactionType: _transactionType,
      weight: weight,
      purityValue: _purityValue,
      purityLabel: _purityLabelMap[_purityValue] ?? '99.99% (24K)',
      basePrice: basePrice,
      hasNpwp: _hasNpwp,
      mintCost: mintCost,
      subtotal: subtotal,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      buybackEstimate: buybackEstimate,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Emas Batangan 24K',
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
            'Kalkulator Emas Fisik',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Simulasi nilai gramatur, biaya cetak kemasan CertiCard, dan pajak PPh 22.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // SECTION 1: INPUT PARAMETER
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Parameter Transaksi',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Antam / UBS',
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

                // Transaction Type Toggle
                const Text('Jenis Transaksi',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _transactionType = 'buy';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _transactionType == 'buy'
                                  ? const Color(0xFF0F172A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: _transactionType == 'buy'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Beli Batangan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _transactionType == 'buy'
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _transactionType = 'sell';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _transactionType == 'sell'
                                  ? const Color(0xFF0F172A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.currency_exchange_rounded,
                                  size: 16,
                                  color: _transactionType == 'sell'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Jual / Buyback',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _transactionType == 'sell'
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Weight in Grams & Quick Pick
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Berat Batangan (Gram)',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155))),
                    Text('Presisi Akurat',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    suffixText: 'GRAM',
                    suffixStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                const SizedBox(height: 8),

                // Quick Pick Pills
                Row(
                  children: [5, 10, 25, 50, 100].map((val) {
                    final bool isSelected =
                        double.tryParse(_weightController.text) == val;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _weightController.text = val.toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${val}g',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Purity / Kadar Dropdown
                const Text('Kadar Kemurnian',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: _purityValue,
                      isExpanded: true,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A)),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _purityValue = val;
                          });
                        }
                      },
                      items: _purityLabelMap.entries.map((entry) {
                        return DropdownMenuItem<double>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Base Price Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Harga Dasar per Gram',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155))),
                    Row(
                      children: [
                        CircleAvatar(
                            radius: 3, backgroundColor: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Spot Acuan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _basePriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                const SizedBox(height: 12),

                // NPWP Status Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kepemilikan NPWP',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A))),
                          Text(
                            'Tarif PPh 22: ${_hasNpwp ? "0.25% (dengan NPWP)" : "0.50% (tanpa NPWP)"}',
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Switch(
                        value: _hasNpwp,
                        activeThumbColor: const Color(0xFF0F172A), // Menggantikan activeColor
                        onChanged: (val) {
                          setState(() {
                            _hasNpwp = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
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
                            'Reset Form',
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
                          const Icon(Icons.menu_book_rounded,
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
                          Icon(Icons.functions_rounded,
                              size: 18, color: Color(0xFF0F172A)),
                          SizedBox(width: 6),
                          Text(
                            'Langkah Simulasi Perhitungan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Regulasi Pajak PMK',
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
                      children: const [
                        Text(
                          'Rumus Total Nilai:',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Total = (Berat × Kadar × Harga Dasar) + Biaya Cetak ± Pajak PPh 22',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          'Langkah Aktif:',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${calc.weight}g × Rp ${_formatRupiah(calc.basePrice)} = Rp ${_formatRupiah(calc.weight * calc.purityValue * calc.basePrice)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Divider(height: 12, color: Color(0xFFF1F5F9)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ongkos Cetak CertiCard:',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                            Text(
                              _transactionType == 'buy'
                                  ? 'Rp ${_formatRupiah(calc.mintCost)}'
                                  : 'Rp 0 (Buyback)',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // SECTION 3: HASIL PERHITUNGAN
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HASIL SIMULASI FISIK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        _transactionType == 'buy'
                            ? 'Estimasi Pembelian'
                            : 'Estimasi Penjualan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main High-Impact Total
                const Text(
                  'ESTIMASI TOTAL AKHIR',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Rp ',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B)),
                    ),
                    Text(
                      _formatRupiah(calc.grandTotal),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Breakdown Rows
                _buildBreakdownRow(
                    'Harga Dasar Logam (${calc.weight}g)',
                    'Rp ${_formatRupiah(calc.weight * calc.purityValue * calc.basePrice)}'),
                const SizedBox(height: 6),
                _buildBreakdownRow('Biaya Cetak Kemasan CertiCard',
                    'Rp ${_formatRupiah(calc.mintCost)}'),
                const SizedBox(height: 6),
                _buildBreakdownRow(
                    'Pajak PPh 22 (${calc.hasNpwp ? "0.25% NPWP" : "0.50%"})',
                    'Rp ${_formatRupiah(calc.taxAmount)}'),
                const SizedBox(height: 12),

                // Buyback Guarantee Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_user_rounded,
                                  size: 16, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text(
                                'Estimasi Nilai Buyback',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Text(
                              'Spread Pasar ~8.4%',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nilai Pembelian Kembali:',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                          Text(
                            'Rp ${_formatRupiah(calc.buybackEstimate)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
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
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
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
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Row(
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
    );
  }
}