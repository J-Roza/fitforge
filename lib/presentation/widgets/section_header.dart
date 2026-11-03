import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// En-tête de section partagé : titre en capitales 11 px `textMuted`,
/// sous-titre optionnel, action optionnelle alignée à droite.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .6,
        color: AppColors.textMuted,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trailing == null)
          titleText
        else
          Row(
            children: [
              Expanded(child: titleText),
              trailing!,
            ],
          ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            subtitle!,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.3),
          ),
        ],
      ],
    );
  }
}
