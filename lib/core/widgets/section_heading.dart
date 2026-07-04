import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class SectionHeading extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeading({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}
