import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/user_profile.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(workoutTemplatesProvider);
    final user = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Séances')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AI Program banner ─────────────────────────────────
                  if (user != null)
                    _AIProgramBanner(user: user, ref: ref).animate().fadeIn(),
                  const SizedBox(height: 24),

                  // ── Create workout button ─────────────────────────────
                  Row(
                    children: [
                      Text('Mes séances', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showCreateWorkout(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accentGlow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: AppColors.accent, size: 16),
                              SizedBox(width: 4),
                              Text('Créer', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _WorkoutTemplateCard(
                  workout: templates[i],
                  onStart: () {
                    ref.read(activeSessionProvider.notifier).startSession(templates[i]);
                    context.go('/workout/active');
                  },
                  onFavorite: () =>
                      ref.read(workoutTemplatesProvider.notifier).toggleFavorite(templates[i].id),
                  onDelete: () => _confirmDelete(context, ref, templates[i].id, templates[i].name),
                  onEdit: () => context.push('/workout/edit/${templates[i].id}'),
                ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn().slideY(begin: 0.05, end: 0),
                childCount: templates.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la séance ?'),
        content: Text('« $name » sera supprimée définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.pop();
              ref.read(workoutTemplatesProvider.notifier).removeWorkout(id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showCreateWorkout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateWorkoutSheet(),
    );
  }
}

class _AIProgramBanner extends StatelessWidget {
  final UserProfile user;
  final WidgetRef ref;
  const _AIProgramBanner({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1030), Color(0xFF0D0D1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('IA',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Programme personnalisé',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Basé sur ton profil ${user.somatotype?.label ?? ""}',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.workoutsPerWeek} séances/semaine · ${user.goal.label}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      );
}

class _WorkoutTemplateCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onStart;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _WorkoutTemplateCard({
    required this.workout,
    required this.onStart,
    required this.onFavorite,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscles = workout.muscleGroups;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout.name, style: theme.textTheme.titleLarge),
                      if (workout.description != null)
                        Text(
                          workout.description!,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (muscles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: muscles.take(4).map((m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: m.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: m.color.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m.emoji, style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(m.label, style: TextStyle(color: m.color, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    workout.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: workout.isFavorite ? AppColors.warning : AppColors.textMuted,
                  ),
                  onPressed: onFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bgCardElevated,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _WorkoutStat(
                        icon: Icons.fitness_center_rounded,
                        value: '${workout.exercises.length}',
                        label: 'ex.',
                      ),
                      const SizedBox(width: 14),
                      _WorkoutStat(
                        icon: Icons.layers_rounded,
                        value: '${workout.totalSets}',
                        label: 'séries',
                      ),
                      const SizedBox(width: 14),
                      _WorkoutStat(
                        icon: Icons.timer_outlined,
                        value: '${workout.estimatedDuration?.inMinutes ?? 45}',
                        label: 'min',
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Démarrer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _WorkoutStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text('$value ',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      );
}

class _CreateWorkoutSheet extends ConsumerStatefulWidget {
  const _CreateWorkoutSheet();

  @override
  ConsumerState<_CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

class _CreateWorkoutSheetState extends ConsumerState<_CreateWorkoutSheet> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle séance', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nom de la séance'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.trim().isNotEmpty) {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    ref.read(workoutTemplatesProvider.notifier).addWorkout(
                          Workout(
                            id: id,
                            name: _nameCtrl.text.trim(),
                            exercises: [],
                          ),
                        );
                    Navigator.pop(context);
                    context.push('/workout/edit/$id');
                  }
                },
                child: const Text('Créer et ajouter des exercices'),
              ),
            ),
          ],
        ),
      );
}
