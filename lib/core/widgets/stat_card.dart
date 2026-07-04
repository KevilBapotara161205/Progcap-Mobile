import 'package:flutter/material.dart';
import '../theme/colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? subtitle;
  final bool darkMode;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.subtitle,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkMode ? AppColors.darkBlue : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: darkMode ? AppColors.accentGreen : AppColors.brandBlue, size: 24),
            const SizedBox(height: 12),
          ],
          Text(value, style: TextStyle(color: darkMode ? Colors.white : AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: darkMode ? Colors.white70 : AppColors.textSecondary, fontSize: 12)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: TextStyle(color: darkMode ? AppColors.accentGreen : AppColors.brandBlue, fontSize: 10, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }
}
