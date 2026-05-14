import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../providers/exercise_provider.dart';

class ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final bool compact;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(exercise.id);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: compact ? _buildCompact(context, isFav, ref, theme) : _buildFull(context, isFav, ref, theme),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildFull(BuildContext context, bool isFav, WidgetRef ref, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image / placeholder
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: exercise.imageUrl != null
              ? Image.network(
                  exercise.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(favoritesProvider.notifier).toggle(exercise.id),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.error : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MuscleChip(muscle: exercise.primaryMuscle),
                  const SizedBox(width: 8),
                  _RoleBadge(role: exercise.role),
                  const Spacer(),
                  _EquipmentIcon(equipment: exercise.equipment.first),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context, bool isFav, WidgetRef ref, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: exercise.primaryMuscle.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: SvgPicture.asset(
                exercise.iconAsset,
                width: 28, height: 28,
                colorFilter: ColorFilter.mode(exercise.primaryMuscle.color, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MuscleChip(muscle: exercise.primaryMuscle, small: true),
                    const SizedBox(width: 6),
                    _RoleBadge(role: exercise.role, small: true),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(favoritesProvider.notifier).toggle(exercise.id),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppColors.error : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 160,
        color: AppColors.bgCardElevated,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                exercise.iconAsset,
                width: 64, height: 64,
                colorFilter: ColorFilter.mode(exercise.primaryMuscle.color, BlendMode.srcIn),
              ),
              const SizedBox(height: 10),
              Text(
                exercise.primaryMuscle.label,
                style: TextStyle(color: exercise.primaryMuscle.color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
}

class _MuscleChip extends StatelessWidget {
  final MuscleGroup muscle;
  final bool small;
  const _MuscleChip({required this.muscle, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: muscle.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        muscle.label,
        style: TextStyle(
          color: muscle.color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DifficultyDot extends StatelessWidget {
  final Difficulty difficulty;
  const _DifficultyDot({required this.difficulty});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: difficulty.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            difficulty.label,
            style: TextStyle(
              color: difficulty.color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

class _RoleBadge extends StatelessWidget {
  final ExerciseRole role;
  final bool small;
  const _RoleBadge({required this.role, this.small = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8,
          vertical: small ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: role.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${role.stars} ${role.label}',
          style: TextStyle(
            color: role.color,
            fontSize: small ? 9 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
}

class _EquipmentIcon extends StatelessWidget {
  final Equipment equipment;
  const _EquipmentIcon({required this.equipment});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.bgCardElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          equipment.label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
