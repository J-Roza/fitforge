import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Ressenti de fin de séance ('great' | 'ok' | 'hard') → icône, couleur, libellé.
/// Remplace les emojis (rendu variable selon le téléphone) par des icônes
/// vectorielles cohérentes avec le reste de l'app.
({IconData icon, Color color, String label}) feelingInfo(String? feeling) =>
    switch (feeling) {
      'great' => (
          icon: Icons.sentiment_very_satisfied_rounded,
          color: AppColors.success,
          label: 'Super séance !'
        ),
      'ok' => (
          icon: Icons.sentiment_neutral_rounded,
          color: AppColors.warning,
          label: 'Séance correcte'
        ),
      'hard' => (
          icon: Icons.sentiment_dissatisfied_rounded,
          color: AppColors.error,
          label: 'Séance difficile'
        ),
      _ => (
          icon: Icons.check_circle_rounded,
          color: AppColors.accent,
          label: 'Séance terminée'
        ),
    };

/// Icône de ressenti dans une pastille colorée.
class FeelingIcon extends StatelessWidget {
  final String? feeling;
  final double size;
  const FeelingIcon(this.feeling, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final f = feelingInfo(feeling);
    return Container(
      width: size * 1.6,
      height: size * 1.6,
      decoration: BoxDecoration(
        color: f.color.withValues(alpha: .14),
        shape: BoxShape.circle,
      ),
      child: Icon(f.icon, color: f.color, size: size),
    );
  }
}
