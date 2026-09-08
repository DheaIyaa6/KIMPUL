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
        color: Color.fromRGBO(255, 255, 255, 0.95),
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(223, 227, 231, 0.8),
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
                  // Logo Container / Placeholder
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(234, 67, 89, 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      size: 20,
                      color: Color(0xFFEA4359),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text Title & Subtitle
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'KIM',
                              style: TextStyle(color: Color(0xFF253545)),
                            ),
                            TextSpan(
                              text: 'PUL',
                              style: TextStyle(color: Color(0xFFEA4359)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'KALKULATOR TRADING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Controls (Notification Button dengan Red Dot)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenNotifications,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: Color(0xFF515F74),
                        ),
                        // Red Badge Dot
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA4359),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
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