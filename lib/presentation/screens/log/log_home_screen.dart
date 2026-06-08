import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/log_models.dart';
import '../../../providers/log_provider.dart';

class LogHomeScreen extends ConsumerWidget {
  const LogHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions    = ref.watch(sessionsConfigProvider);
    final histAsync   = ref.watch(logHistoryProvider);
    final planAsync   = ref.watch(planningProvider);
    final customAsync = ref.watch(customSessionsProvider);
    final history     = histAsync.value ?? [];
    final plan        = planAsync.value ?? {};
    final custom      = customAsync.value ?? {};

    final todayType = plan[DateTime.now().weekday % 7];
    final todaySession = todayType != null
        ? sessions.firstWhere((s) => s.type == todayType, orElse: () => sessions.first)
        : null;

    // Stats
    final weekCount = history.where((s) {
      final diff = DateTime.now().difference(s.date).inDays;
      return diff < 7;
    }).length;
    final totalVol = history.fold<double>(0, (v, s) => v + s.totalVolume);
    final volStr = totalVol >= 1000
        ? '${(totalVol / 1000).toStringAsFixed(1)}t'
        : '${totalVol.toStringAsFixed(0)}kg';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            title: const Text('FitForge Log',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: () => context.push('/log/planning'),
              ),
            ],
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _StatBox(value: '${history.length}', label: 'SÉANCES'),
                  const SizedBox(width: 10),
                  _StatBox(value: '$weekCount', label: 'CETTE SEMAINE'),
                  const SizedBox(width: 10),
                  _StatBox(value: volStr, label: 'VOLUME TOTAL'),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 50.ms),

          // Today banner
          if (todaySession != null)
            SliverToBoxAdapter(
              child: _TodayBanner(session: todaySession)
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.05),
            ),

          // Session grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
              children: sessions.map((s) {
                final last = history.lastWhereOrNull((h) => h.sessionType == s.type);
                final exIds = getSessionExerciseIds(s.type, custom, sessions);
                return _SessionCard(
                  config: s,
                  lastSession: last,
                  exCount: exIds.length,
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 150 + sessions.indexOf(s) * 40))
                    .slideY(begin: 0.05);
              }).toList(),
            ),
          ),

          // Bottom buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Row(
                children: [
                  Expanded(
                    child: _NavButton(
                      icon: Icons.history_rounded,
                      label: 'Historique',
                      onTap: () => context.push('/log/history'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NavButton(
                      icon: Icons.calendar_today_rounded,
                      label: 'Planning',
                      onTap: () => context.push('/log/planning'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .4)),
            ],
          ),
        ),
      );
}

class _TodayBanner extends ConsumerWidget {
  final SessionConfig session;
  const _TodayBanner({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AUJOURD'HUI",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: session.color,
                            letterSpacing: 1)),
                    const SizedBox(height: 3),
                    Text('S${session.type} · ${session.name}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(session.subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () =>
                    context.push('/log/session/${session.type}'),
                style: TextButton.styleFrom(
                  backgroundColor: session.color.withOpacity(.15),
                  foregroundColor: session.color,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Démarrer →',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
}

class _SessionCard extends StatelessWidget {
  final SessionConfig config;
  final LogSession? lastSession;
  final int exCount;

  const _SessionCard(
      {required this.config, this.lastSession, required this.exCount});

  @override
  Widget build(BuildContext context) {
    final lastStr = lastSession != null
        ? DateFormat('dd MMM', 'fr_FR').format(lastSession!.date)
        : 'Jamais';

    return GestureDetector(
      onTap: () => context.push('/log/session/${config.type}'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('S${config.type} · $exCount exo',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: config.color)),
            const Spacer(),
            Text(config.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(config.subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                maxLines: 2),
            const SizedBox(height: 10),
            Text('⏱ $lastStr',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

extension _ListExt<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
