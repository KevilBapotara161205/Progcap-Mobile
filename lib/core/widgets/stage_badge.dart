import 'package:flutter/material.dart';
import '../theme/colors.dart';

class StageBadge extends StatelessWidget {
  final String stage;
  const StageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(stage.replaceAll('_', ' '), style: const TextStyle(color: AppColors.brandBlue, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
