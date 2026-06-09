import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/exercise_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/log_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final templates = ref.watch(workoutTemplatesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: AppColors.bg,
            expandedHeight: 0,
            title: Row(
              children: [
                Text(
                  'FitForge',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppColors.accent, AppColors.secondary],
                      ).createShader(const Rect.fromLTWH(0, 0, 120, 30)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ─────────────────────────────────────────────
                  Text(
                    _greeting(user?.name),
                    style: theme.textTheme.displayMedium,
                  ).animate().fadeIn(delay: 100.ms),
                  if (user?.goal != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Objectif: ${user!.goal.label}',
                      style: theme.textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                  const SizedBox(height: 24),

                  // ── Weekly stats ──────────────────────────────────────────
                  const _WeeklyStats()
                      .animate()
                      .fadeIn(delay: 250.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 28),

                  // ── Quick start ───────────────────────────────────────────
                  Text('Démarrer une séance', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Workout cards horizontal scroll ───────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) => _WorkoutCard(
                  workout: templates[i],
                  onTap: () => _startWorkout(context, ref, templates[i]),
                ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideX(begin: 0.1, end: 0),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Exercices récents', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/exercises'),
                        child: const Text('Voir tout', style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Quick exercise tiles ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final exercises = ref.read(exercisesProvider);
                  if (i >= exercises.length || i >= 5) return null;
                  final ex = exercises[i];
                  return GestureDetector(
                    onTap: () => context.go('/exercises/${ex.id}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: ex.primaryMuscle.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(ex.primaryMuscle.emoji, style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(ex.primaryMuscle.label,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(),
                  );
                },
                childCount: 5,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _startWorkout(BuildContext context, WidgetRef ref, Workout workout) {
    context.go('/workout');
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final salut = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';
    return name != null ? '$salut,\n$name 👋' : '$salut 👋';
  }
}

class _WeeklyStats extends ConsumerWidget {
  const _WeeklyStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(logHistoryProvider).value ?? [];
    final now = DateTime.now();
    final weekSessions = history.where((s) =>
        now.difference(s.date).inDays < 7).length;
    final totalVol = history.fold<double>(0, (v, s) => v + s.totalVolume);
    final volStr = totalVol >= 1000
        ? '${(totalVol / 1000).toStringAsFixed(1)}t'
        : '${totalVol.toStringAsFixed(0)}kg';
    int streak = 0;
    final weeks = history.map((s) => now.difference(s.date).inDays ~/ 7).toSet();
    while (weeks.contains(streak)) streak++;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Séances\ncette semaine', value: '$weekSessions'),
          _Divider(),
          _StatItem(label: 'Volume\ntotal', value: volStr),
          _Divider(),
          _StatItem(label: 'Streak\nsemaines', value: '${streak}sem'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        width: 1,
        color: Colors.white24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  const _WorkoutCard({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscles = workout.muscleGroups;
    final color = muscles.isNotEmpty ? muscles.first.color : AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            // Background gradient
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      muscles.isNotEmpty ? muscles.first.emoji : '🏋️',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    workout.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${workout.estimatedDuration?.inMinutes ?? 45}min',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.fitness_center, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${workout.exercises.length} ex',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
