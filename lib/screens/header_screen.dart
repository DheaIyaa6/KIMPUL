import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenNotifications;

  const HeaderWidget({
    super.key,
    required this.onOpenNotifications,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo & Name
              Row(
                children: [
                  // Circular Asset Image Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/trademark.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback jika aset gambar belum dimuat
                          return const Icon(
                            Icons.broken_image_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title Text: KIMPUL
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'KIM',
                          style: TextStyle(color: Color(0xFF1E293B)),
                        ),
                        TextSpan(
                          text: 'PUL',
                          style: TextStyle(color: Color(0xFFE93A56)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notification Button Icon dengan Red Dot
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenNotifications,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 26,
                          color: Color(0xFF334155),
                        ),
                        // Red Badge Dot
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE93A56),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
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
      ),
    );
  }
}