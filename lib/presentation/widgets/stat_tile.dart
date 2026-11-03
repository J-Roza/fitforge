import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Tuile de statistique partagée (accueil, profil, progression).
///
/// Valeur en `textPrimary`, chiffres tabulaires, libellé en capitales 11 px.
/// `progress` (0..1) ajoute une fine barre en bas de la tuile, par exemple pour
/// un objectif hebdomadaire ; `icon` est optionnelle et reste neutre.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final double? progress;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.textMuted),
                const SizedBox(height: AppSpace.sm),
              ],
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .4,
                  color: AppColors.textMuted,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpace.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: AppColors.bgCardElevated,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
