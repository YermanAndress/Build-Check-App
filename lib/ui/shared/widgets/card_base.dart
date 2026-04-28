import 'package:flutter/material.dart';

class CardBase extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget leftContent;
  final Widget rightContent;
  final Widget? bottomContent;
  final bool showChevron;

  const CardBase({
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
    required this.leftContent,
    required this.rightContent,
    this.bottomContent,
    this.showChevron = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Ícono izquierdo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    // Contenido izquierdo (expansible)
                    Expanded(child: leftContent),
                    const SizedBox(width: 8),
                    // Contenido derecho
                    rightContent,
                    if (showChevron) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFB0BEC5),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
              if (bottomContent != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: bottomContent!,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
