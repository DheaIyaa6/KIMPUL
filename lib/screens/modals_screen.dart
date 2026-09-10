import 'package:flutter/material.dart';

// --- MODELS ---
class NewsItem {
  final String title;
  final String source;
  final String timeAgo;
  final String readTime;
  final String category;
  final String imageUrl;
  final String fullContent;

  NewsItem({
    required this.title,
    required this.source,
    required this.timeAgo,
    required this.readTime,
    required this.category,
    required this.imageUrl,
    required this.fullContent,
  });
}

class UserProfile {
  final String name;
  final String email;
  final String phone;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
  });
}

// --- REUSABLE BASE MODAL DIALOG ---
class ModalWrapper extends StatelessWidget {
  final Widget child;

  const ModalWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }
}

// --- 1. NEWS DETAIL MODAL ---
class NewsDetailModal extends StatelessWidget {
  final NewsItem news;

  const NewsDetailModal({super.key, required this.news});

  static void show(BuildContext context, NewsItem news) {
    showDialog(
      context: context,
      builder: (context) => NewsDetailModal(news: news),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ModalWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image Banner
          Stack(
            children: [
              Container(
                height: 190,
                width: double.infinity,
                color: const Color(0xFFF8FAFC),
                child: Image.network(
                  news.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.image, color: Color(0xFF94A3B8), size: 40),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    news.category,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      news.source,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      '${news.timeAgo} • ${news.readTime}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  news.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                ),
                const SizedBox(height: 10),
                Text(
                  news.fullContent,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TradingView Feed',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Selesai Baca', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
}

// --- 2. CALCULATION DETAIL MODAL ---
class CalculationDetailModal extends StatelessWidget {
  final dynamic item; // HistoryItem / PivotCalculation

  const CalculationDetailModal({super.key, required this.item});

  static void show(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => CalculationDetailModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bool isPivot = item.type == 'pivot';

    return ModalWrapper(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPivot ? Icons.candlestick_chart_rounded : Icons.workspace_premium_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPivot ? 'Rincian Level Pivot XAU' : 'Rincian Emas Fisik',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),

            if (isPivot) ...[
              // Pivot Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Input Acuan (${item.pair ?? "XAU/USD"}):',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPivotBadge('H', item.high ?? 0.0),
                        const SizedBox(width: 6),
                        _buildPivotBadge('L', item.low ?? 0.0),
                        const SizedBox(width: 6),
                        _buildPivotBadge('C', item.close ?? 0.0),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('LEVEL STANDAR FLOOR:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Column(
                children: [
                  if (item.r4 != null || item.s4 != null) ...[
                    Row(
                      children: [
                        _buildLevelBox('R4', item.r4 ?? 0.0, true, primaryColor),
                        const SizedBox(width: 6),
                        _buildLevelBox('S4', item.s4 ?? 0.0, false, primaryColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      _buildLevelBox('R3', item.r3 ?? 0.0, true, primaryColor),
                      const SizedBox(width: 6),
                      _buildLevelBox('S3', item.s3 ?? 0.0, false, primaryColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildLevelBox('R2', item.r2 ?? 0.0, true, primaryColor),
                      const SizedBox(width: 6),
                      _buildLevelBox('S2', item.s2 ?? 0.0, false, primaryColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildLevelBox('R1', item.r1 ?? 0.0, true, primaryColor),
                      const SizedBox(width: 6),
                      _buildLevelBox('S1', item.s1 ?? 0.0, false, primaryColor),
                    ],
                  ),
                ],
              ),
            ] else ...[
              // Gold Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRowInfo('Tipe Transaksi:', (item.transactionType == 'buy') ? 'BELI FISIK' : 'JUAL / BUYBACK'),
                    const SizedBox(height: 6),
                    _buildRowInfo('Gramatur / Karat:', '${item.weight ?? 0} gram • ${item.purityLabel ?? "24K"}'),
                    const SizedBox(height: 6),
                    _buildRowInfo('Harga Spot Dasar:', 'Rp ${item.basePrice ?? 0} / gr'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  _buildRowInfo('Subtotal Bahan:', 'Rp ${item.grandTotal ?? 0}'),
                  const SizedBox(height: 6),
                  _buildRowInfo('Cetak CertiCard:', 'Rp ${item.mintCost ?? 0}'),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Akhir:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Rp ${item.grandTotal ?? 0}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup Rincian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPivotBadge(String label, double val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text('$label: ${val.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ),
      ),
    );
  }

  static Widget _buildLevelBox(String title, double val, bool isResist, Color primaryColor) {
    final Color bg = isResist ? primaryColor.withValues(alpha: 0.08) : const Color(0xFFECFDF5);
    final Color border = isResist ? primaryColor.withValues(alpha: 0.2) : const Color(0xFFA7F3D0);
    final Color text = isResist ? primaryColor : const Color(0xFF047857);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 11.5, color: text, fontWeight: FontWeight.w600)),
            Text(val.toStringAsFixed(2), style: TextStyle(fontSize: 11.5, color: text, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static Widget _buildRowInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      ],
    );
  }
}

// --- 3. EDIT PROFILE MODAL ---
class EditProfileModal extends StatefulWidget {
  final UserProfile user;
  final Function(Map<String, String> updated) onSave;

  const EditProfileModal({super.key, required this.user, required this.onSave});

  static void show(BuildContext context, UserProfile user, Function(Map<String, String>) onSave) {
    showDialog(
      context: context,
      builder: (context) => EditProfileModal(user: user, onSave: onSave),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ModalWrapper(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Data Profil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFE2E8F0)),
            _buildInput('NAMA LENGKAP', _nameController, TextInputType.name, primaryColor),
            const SizedBox(height: 12),
            _buildInput('EMAIL', _emailController, TextInputType.emailAddress, primaryColor),
            const SizedBox(height: 12),
            _buildInput('NOMOR TELEPON', _phoneController, TextInputType.phone, primaryColor),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave({
                    'name': _nameController.text,
                    'email': _emailController.text,
                    'phone': _phoneController.text,
                  });
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, TextInputType type, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      ],
    );
  }
}

// --- 4. NOTIFICATION MODAL ---
class NotificationModal extends StatelessWidget {
  const NotificationModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final notifications = [
      {
        'title': 'Alert Pivot XAU/USD',
        'desc': 'Harga spot menembus level R1 (\$2.352,80) dengan konfirmasi volume tinggi.',
        'time': '15m lalu',
        'unread': true,
      },
      {
        'title': 'Koreksi Kurs Spot Emas Fisik Antam',
        'desc': 'Harga dasar diperbarui menjadi Rp 1.150.000 / gram mengikuti sesi London.',
        'time': '1j lalu',
        'unread': true,
      },
      {
        'title': 'Pembukaan Sesi Pasar New York',
        'desc': 'Sesi perdagangan komoditas dibuka dengan likuiditas tinggi.',
        'time': '3j lalu',
        'unread': false,
      },
    ];

    return ModalWrapper(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_rounded, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text('Pusat Notifikasi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFE2E8F0)),
            Column(
              children: notifications.map((n) {
                final bool unread = n['unread'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: unread ? primaryColor.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: unread ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(n['title'] as String,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(n['time'] as String,
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n['desc'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Tutup', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. LOGOUT MODAL ---
class LogoutModal extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutModal({super.key, required this.onConfirm});

  static void show(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => LogoutModal(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ModalWrapper(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.logout_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              'Konfirmasi Keluar Sesi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apakah Anda yakin ingin keluar dari sesi akun Anda? Anda dapat masuk kembali kapan saja.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Keluar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 6. WHATSAPP CONSULTATION MODAL ---
class ConsultationModal extends StatelessWidget {
  const ConsultationModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ConsultationModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF047857), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text('Bantuan & Konsultasi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFE2E8F0)),
            const Text(
              'Konsultasikan strategi kalkulasi Pivot Point dan estimasi emas fisik Anda langsung melalui WhatsApp.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('💬 Layanan Pengguna:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Dukungan kalkulasi trading dan data komoditas', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  SizedBox(height: 6),
                  Text('🕒 Jam Operasional:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Senin - Jumat: 08:30 - 17:30 WIB', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Tautan WhatsApp dapat di-handle via url_launcher
                },
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Buka WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 7. TOAST NOTIFICATION HELPER ---
class ToastNotification {
  static void show(BuildContext context, String message) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}