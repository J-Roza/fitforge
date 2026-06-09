import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../providers/exercise_provider.dart';
import '../../widgets/muscle_body_diagram.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    final exercise = exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => exercises.first,
    );
    final isFav = ref.watch(favoritesProvider).contains(exercise.id);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image / App bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFav ? AppColors.error : Colors.white,
                  ),
                ),
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggle(exercise.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: exercise.imageUrl != null
                  ? Image.network(
                      exercise.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _heroPlaceholder(exercise),
                    )
                  : _heroPlaceholder(exercise),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + badges ────────────────────────────────────
                  Text(exercise.name, style: theme.textTheme.displayMedium)
                      .animate()
                      .fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        label: exercise.primaryMuscle.label,
                        color: exercise.primaryMuscle.color,
                      ),
                      _Badge(
                        label: exercise.difficulty.label,
                        color: exercise.difficulty.color,
                      ),
                      _Badge(
                        label: exercise.category == ExerciseCategory.compound
                            ? 'Polyarticulaire'
                            : 'Isolation',
                        color: AppColors.secondary,
                      ),
                      ...exercise.equipment.map((e) => _Badge(
                            label: e.label,
                            color: AppColors.textMuted,
                          )),
                    ],
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 24),

                  // ── Video button ──────────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(exercise.youtubeSearchUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFF0000).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0000), size: 22),
                          SizedBox(width: 8),
                          Text('Voir tutoriel YouTube',
                              style: TextStyle(
                                  color: Color(0xFFFF0000),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: 20),

                  // ── Description ───────────────────────────────────────
                  Text('Description', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(exercise.description, style: theme.textTheme.bodyLarge)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),

                  // ── Muscles travaillés ────────────────────────────────
                  Text('Muscles travaillés', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  MuscleBodyDiagram(
                    primaryMuscle: exercise.primaryMuscle,
                    secondaryMuscles: exercise.secondaryMuscles,
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 12),
                  _MusclesList(exercise: exercise)
                      .animate()
                      .fadeIn(delay: 280.ms),
                  const SizedBox(height: 24),

                  // ── Instructions ──────────────────────────────────────
                  if (exercise.instructions.isNotEmpty) ...[
                    Text('Technique', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    ...exercise.instructions.asMap().entries.map(
                          (e) => _InstructionStep(step: e.key + 1, text: e.value)
                              .animate(delay: Duration(milliseconds: 50 * e.key))
                              .fadeIn()
                              .slideX(begin: -0.05, end: 0),
                        ),
                    const SizedBox(height: 24),
                  ],

                  // ── Common mistakes ───────────────────────────────────
                  if (exercise.commonMistakes.isNotEmpty) ...[
                    Text('Erreurs fréquentes', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    ...exercise.commonMistakes.map(
                      (m) => _MistakeItem(text: m).animate().fadeIn(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Suggested sets ────────────────────────────────────
                  if (exercise.defaultSets != null) ...[
                    Text('Recommandations', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    _RecommendationCard(exercise: exercise),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder(Exercise exercise) => Container(
        color: AppColors.bgCardElevated,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                exercise.iconAsset,
                width: 100, height: 100,
                colorFilter: ColorFilter.mode(exercise.primaryMuscle.color, BlendMode.srcIn),
              ),
              const SizedBox(height: 14),
              Text(
                exercise.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.primaryMuscle.label,
                style: TextStyle(
                  color: exercise.primaryMuscle.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _MusclesList extends StatelessWidget {
  final Exercise exercise;
  const _MusclesList({required this.exercise});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _MuscleRow(
              muscle: exercise.primaryMuscle,
              label: 'Primaire',
              percentage: 1.0,
            ),
            ...exercise.secondaryMuscles.map(
              (m) => _MuscleRow(muscle: m, label: 'Secondaire', percentage: 0.4),
            ),
          ],
        ),
      );
}

class _MuscleRow extends StatelessWidget {
  final MuscleGroup muscle;
  final String label;
  final double percentage;
  const _MuscleRow({required this.muscle, required this.label, required this.percentage});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (label == 'Primaire'
                        ? const Color(0xFFE53935)
                        : const Color(0xFFFF6D00))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: (label == 'Primaire'
                            ? const Color(0xFFE53935)
                            : const Color(0xFFFF6D00))
                        .withOpacity(0.4)),
              ),
              child: Center(
                child: Icon(Icons.circle,
                    size: 10,
                    color: label == 'Primaire'
                        ? const Color(0xFFE53935)
                        : const Color(0xFFFF6D00)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(muscle.label,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                      const Spacer(),
                      Text(label,
                          style: TextStyle(
                              color: label == 'Primaire'
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFFFF6D00),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: const Color(0xFF1E1B2E),
                      valueColor: AlwaysStoppedAnimation(
                          label == 'Primaire'
                              ? const Color(0xFFE53935)
                              : const Color(0xFFFF6D00)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _InstructionStep extends StatelessWidget {
  final int step;
  final String text;
  const _InstructionStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  text,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      );
}

class _MistakeItem extends StatelessWidget {
  final String text;
  const _MistakeItem({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      );
}

class _RecommendationCard extends StatelessWidget {
  final Exercise exercise;
  const _RecommendationCard({required this.exercise});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentGlow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            _RecItem(icon: Icons.layers_rounded, label: 'Séries', value: '${exercise.defaultSets}'),
            const SizedBox(width: 24),
            _RecItem(icon: Icons.repeat_rounded, label: 'Reps', value: exercise.defaultReps ?? '10-12'),
            const SizedBox(width: 24),
            const _RecItem(icon: Icons.timer_outlined, label: 'Repos', value: '90s'),
          ],
        ),
      );
}

class _RecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _RecItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      );
}
