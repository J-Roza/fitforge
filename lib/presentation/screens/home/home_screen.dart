import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/exercise_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/log_provider.dart';
import '../log/active_log_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
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
                  const SizedBox(height: 24),

                  // ── Séance du jour ────────────────────────────────────────
                  const _TodaySession()
                      .animate()
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: 28),

                  // ── Exercices récents ─────────────────────────────────────
                  Row(
                    children: [
                      Text('Exercices', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/exercises'),
                        child: const Text('Voir tout',
                            style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Exercise tiles ────────────────────────────────────────────
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                              color:
                                  ex.primaryMuscle.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(ex.primaryMuscle.emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(ex.primaryMuscle.label,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted),
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

// ── Séance du jour ────────────────────────────────────────────
class _TodaySession extends ConsumerWidget {
  const _TodaySession();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planningProvider).value ?? {};
    final sessions = ref.watch(sessionsConfigProvider);
    final history = ref.watch(logHistoryProvider).value ?? [];

    final todayWeekday = DateTime.now().weekday % 7;
    final todayType = plan[todayWeekday];
    final todayConfig = todayType != null
        ? sessions.firstWhere((s) => s.type == todayType,
            orElse: () => sessions.first)
        : null;

    // Dernière séance (toute séance confondue)
    final last = history.isNotEmpty ? history.last : null;
    final daysSinceLast = last != null
        ? DateTime.now().difference(last.date).inDays
        : null;

    if (todayConfig != null) {
      // Séance planifiée aujourd'hui
      return GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) =>
                  ActiveLogScreen(sessionType: todayConfig.type)),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: todayConfig.color.withOpacity(.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: todayConfig.color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text('S${todayConfig.type}',
                      style: TextStyle(
                          color: todayConfig.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AUJOURD'HUI",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: todayConfig.color,
                            letterSpacing: 1)),
                    Text(todayConfig.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(todayConfig.subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: todayConfig.color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Démarrer',
                    style: TextStyle(
                        color: todayConfig.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    // Pas de séance planifiée — affiche info repos + dernière séance
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgCardElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
                child: Text('😴', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AUJOURD'HUI",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1)),
                const Text('Jour de repos',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                Text(
                  daysSinceLast == null
                      ? 'Planifie ta semaine dans le Carnet'
                      : daysSinceLast == 0
                          ? 'Dernière séance : aujourd\'hui 💪'
                          : 'Dernière séance : il y a $daysSinceLast j',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Stats ──────────────────────────────────────────────
class _WeeklyStats extends ConsumerWidget {
  const _WeeklyStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(logHistoryProvider).value ?? [];
    final now = DateTime.now();
    final weekSessions =
        history.where((s) => now.difference(s.date).inDays < 7).length;
    final totalVol =
        history.fold<double>(0, (v, s) => v + s.totalVolume);
    final volStr = totalVol >= 1000
        ? '${(totalVol / 1000).toStringAsFixed(1)}t'
        : '${totalVol.toStringAsFixed(0)}kg';
    int streak = 0;
    final weeks =
        history.map((s) => now.difference(s.date).inDays ~/ 7).toSet();
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
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
