import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/log_models.dart';
import '../../../providers/log_provider.dart';
import '../../../providers/exercise_provider.dart';
import '../log/history_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(logHistoryProvider).value?.reversed.toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Progression')),
      body: history.isEmpty
          ? _EmptyHistory()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryCards(history: history)
                            .animate()
                            .fadeIn(delay: 100.ms),
                        const SizedBox(height: 26),

                        const _SectionTitle(
                          title: 'Cette semaine',
                          subtitle: 'Comparé aux 7 jours précédents',
                        ),
                        const SizedBox(height: 12),
                        _WeekComparison(history: history)
                            .animate()
                            .fadeIn(delay: 150.ms),
                        const SizedBox(height: 26),

                        const _SectionTitle(
                          title: 'Volume par semaine',
                          subtitle: 'Poids total soulevé sur chaque semaine',
                        ),
                        const SizedBox(height: 12),
                        _VolumeChart(history: history)
                            .animate()
                            .fadeIn(delay: 200.ms),
                        const SizedBox(height: 26),

                        const _SectionTitle(
                          title: 'Muscles travaillés',
                          subtitle: 'Nombre de séries par muscle, sur 30 jours',
                        ),
                        const SizedBox(height: 12),
                        _MuscleBreakdown(history: history)
                            .animate()
                            .fadeIn(delay: 250.ms),
                        const SizedBox(height: 26),

                        const _SectionTitle(
                          title: 'Régularité',
                          subtitle:
                              'Un carré = un jour. Plus c\'est vif, plus tu as soulevé.',
                        ),
                        const SizedBox(height: 12),
                        _FrequencyHeatmap(history: history)
                            .animate()
                            .fadeIn(delay: 300.ms),
                        const SizedBox(height: 26),

                        Row(
                          children: [
                            const Expanded(
                              child: _SectionTitle(
                                  title: 'Dernières séances'),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context,
                                      rootNavigator: true)
                                  .push(MaterialPageRoute(
                                      builder: (_) =>
                                          const HistoryScreen())),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Voir tout',
                                      style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                  Icon(Icons.chevron_right_rounded,
                                      color: AppColors.accent, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _SessionHistoryItem(session: history[i])
                          .animate(delay: Duration(milliseconds: 50 * i))
                          .fadeIn(),
                      childCount: history.length > 5 ? 5 : history.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}

// ── Titre de section avec sous-titre explicatif ──────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12, height: 1.3)),
          ],
        ],
      );
}

// ── Comparaison cette semaine vs semaine précédente ──────────
class _WeekComparison extends StatelessWidget {
  final List<LogSession> history;
  const _WeekComparison({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisStart = now.subtract(const Duration(days: 7));
    final lastStart = now.subtract(const Duration(days: 14));

    Iterable<LogSession> inRange(DateTime start, DateTime end) => history
        .where((s) => s.date.isAfter(start) && !s.date.isAfter(end));

    final thisVol =
        inRange(thisStart, now).fold<double>(0, (v, s) => v + s.totalVolume);
    final lastVol = inRange(lastStart, thisStart)
        .fold<double>(0, (v, s) => v + s.totalVolume);
    final thisCount = inRange(thisStart, now).length;
    final lastCount = inRange(lastStart, thisStart).length;

    final diff = thisVol - lastVol;
    final flat = diff.abs() < 1;
    final up = diff > 0;
    final pct = lastVol > 0
        ? (diff / lastVol * 100).abs()
        : (thisVol > 0 ? 100.0 : 0.0);
    final color = flat
        ? AppColors.textMuted
        : (up ? const Color(0xFF30D158) : AppColors.error);

    String fmt(double kg) => kg >= 1000
        ? '${(kg / 1000).toStringAsFixed(1)} t'
        : '${kg.toStringAsFixed(0)} kg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Volume soulevé',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(fmt(thisVol),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                        flat
                            ? Icons.trending_flat_rounded
                            : (up
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded),
                        size: 15,
                        color: color),
                    const SizedBox(width: 3),
                    Text(
                      flat
                          ? 'identique'
                          : '${up ? '+' : '−'}${pct.toStringAsFixed(0)} %',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
              height: 56,
              width: 1,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Séances',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('$thisCount',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$lastCount la semaine d\'avant',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Répartition des séries par muscle ─────────────────────────
class _MuscleBreakdown extends ConsumerWidget {
  final List<LogSession> history;
  const _MuscleBreakdown({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final Map<MuscleGroup, int> setsPerMuscle = {};
    for (final s in history.where((s) => s.date.isAfter(cutoff))) {
      for (final e in s.exercises) {
        Exercise? ex;
        try {
          ex = exercises.firstWhere((x) => x.id == e.exerciseId);
        } catch (_) {
          ex = null;
        }
        if (ex == null) continue;
        setsPerMuscle.update(ex.primaryMuscle, (v) => v + e.sets.length,
            ifAbsent: () => e.sets.length);
      }
    }

    Widget card(Widget child) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        );

    if (setsPerMuscle.isEmpty) {
      return card(const Text(
        'Aucune série enregistrée ces 30 derniers jours.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      ));
    }

    final entries = setsPerMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSets = entries.first.value;
    final totalSets = entries.fold<int>(0, (v, e) => v + e.value);

    return card(Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Text(e.key.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(e.key.label,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / maxSets,
                      backgroundColor: AppColors.bgCardElevated,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(e.key.color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${e.value} sér.',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text('$totalSets séries au total sur 30 jours',
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    ));
  }
}

class _SummaryCards extends ConsumerWidget {
  final List<LogSession> history;
  const _SummaryCards({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final weekSessions = history.where((s) =>
        now.difference(s.date).inDays < 7).length;
    final totalSessions = history.length;
    final totalVolume = history.fold<double>(0, (sum, s) => sum + s.totalVolume);

    return Row(
      children: [
        _StatCard(value: '$totalSessions', label: 'Total séances',
            icon: Icons.fitness_center_rounded, color: AppColors.accent),
        const SizedBox(width: 12),
        _StatCard(value: '$weekSessions', label: 'Cette semaine',
            icon: Icons.calendar_today_rounded, color: AppColors.secondary),
        const SizedBox(width: 12),
        _StatCard(
            value: totalVolume >= 1000
                ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
                : '${totalVolume.toStringAsFixed(0)}kg',
            label: 'Volume total',
            icon: Icons.show_chart_rounded,
            color: AppColors.chest),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1),
            ],
          ),
        ),
      );
}

class _VolumeChart extends StatelessWidget {
  final List<LogSession> history;
  const _VolumeChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Début de chaque semaine (la dernière = semaine en cours)
    final weekStarts =
        List.generate(7, (i) => now.subtract(Duration(days: (6 - i) * 7)));
    // Volume en kg pour chaque semaine
    final volumes = List.generate(7, (i) {
      final start = weekStarts[i];
      final end = start.add(const Duration(days: 7));
      return history
          .where((s) => s.date.isAfter(start) && s.date.isBefore(end))
          .fold<double>(0, (sum, s) => sum + s.totalVolume);
    });

    final maxVol = volumes.fold<double>(0, (m, v) => v > m ? v : m);
    final spots = volumes
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    // Échelle : 4 lignes de grille, headroom de 15 %
    final maxY = maxVol <= 0 ? 100.0 : maxVol * 1.15;
    final interval = maxY / 4;

    String fmtKg(double kg) {
      if (kg >= 1000) {
        final t = kg / 1000;
        return '${t.toStringAsFixed(t % 1 == 0 ? 0 : 1)}t';
      }
      return kg.toStringAsFixed(0);
    }

    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: interval,
                getTitlesWidget: (v, _) => Text(fmtKg(v),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i > 6) return const SizedBox.shrink();
                  final label = i == 6
                      ? 'Cette\nsem.'
                      : DateFormat('d/M').format(weekStarts[i]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 9)),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.accent,
                  strokeColor: AppColors.bg,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.3),
                    AppColors.accent.withValues(alpha: 0)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyHeatmap extends StatelessWidget {
  final List<LogSession> history;
  const _FrequencyHeatmap({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weeks = 18;

    // Date → volume total ce jour
    final Map<String, double> dayVolume = {};
    for (final s in history) {
      final key =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      dayVolume[key] = (dayVolume[key] ?? 0) + s.totalVolume;
    }
    final maxVol = dayVolume.values.isEmpty
        ? 1.0
        : dayVolume.values.reduce((a, b) => a > b ? a : b);

    // Début aligné sur un lundi, couvrant 18 semaines
    final todayWeekday = now.weekday; // 1=Lun..7=Dim
    final alignedEnd = now.add(Duration(days: 7 - todayWeekday));
    final alignedStart = alignedEnd.subtract(Duration(days: weeks * 7 - 1));

    Color cellColor(double vol) {
      if (vol == 0) return const Color(0xFF1E1B2E);
      final t = (vol / maxVol).clamp(0.15, 1.0);
      return AppColors.accent.withValues(alpha: t);
    }

    // Labels de mois : première colonne de chaque nouveau mois
    final monthLabels = <int, String>{};
    for (var w = 0; w < weeks; w++) {
      final monday = alignedStart.add(Duration(days: w * 7));
      final label = DateFormat('MMM', 'fr_FR').format(monday);
      if (w == 0) {
        monthLabels[w] = label;
      } else {
        final prev = DateFormat('MMM', 'fr_FR')
            .format(alignedStart.add(Duration(days: (w - 1) * 7)));
        if (label != prev) monthLabels[w] = label;
      }
    }

    const cellSize = 12.0;
    const gap = 3.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne des mois
          Row(
            children: [
              const SizedBox(width: 22),
              ...List.generate(weeks, (w) {
                final label = monthLabels[w];
                return SizedBox(
                  width: cellSize + gap,
                  child: label != null
                      ? Text(label,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 8,
                              fontWeight: FontWeight.w600))
                      : null,
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          // Grille jour × semaine
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Labels jours
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (d) {
                  const labels = ['L', '', 'M', '', 'V', '', 'D'];
                  return SizedBox(
                    height: cellSize + gap,
                    width: 16,
                    child: Text(labels[d],
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 8)),
                  );
                }),
              ),
              const SizedBox(width: 4),
              // Colonnes de semaines
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weeks, (w) {
                  return Padding(
                    padding: const EdgeInsets.only(right: gap),
                    child: Column(
                      children: List.generate(7, (d) {
                        final date =
                            alignedStart.add(Duration(days: w * 7 + d));
                        if (date.isAfter(now)) {
                          return SizedBox(height: cellSize + gap);
                        }
                        final key =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final vol = dayVolume[key] ?? 0;
                        final isToday = date.day == now.day &&
                            date.month == now.month &&
                            date.year == now.year;
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.only(bottom: gap),
                          decoration: BoxDecoration(
                            color: cellColor(vol),
                            borderRadius: BorderRadius.circular(2),
                            border: isToday
                                ? Border.all(
                                    color: AppColors.accent, width: 1.5)
                                : null,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Légende
          Row(
            children: [
              const Text('Repos',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 10)),
              const SizedBox(width: 6),
              for (final op in [0.0, 0.25, 0.5, 0.75, 1.0])
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: op == 0
                        ? const Color(0xFF1E1B2E)
                        : AppColors.accent.withValues(alpha: op),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 6),
              const Text('Max',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryItem extends ConsumerWidget {
  final LogSession session;
  const _SessionHistoryItem({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(sessionsConfigProvider);
    final config = configs.firstWhere((c) => c.type == session.sessionType,
        orElse: () => configs.first);
    final dateStr = DateFormat('EEE d MMM', 'fr_FR').format(session.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
              color: config.color.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('S${session.sessionType}',
                  style: TextStyle(color: config.color, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  '$dateStr · ${session.totalSets} séries · ${session.totalVolume.toStringAsFixed(0)} kg',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (session.feeling != null)
            Text(
              switch (session.feeling) {
                'great' => '💪',
                'ok' => '😐',
                'hard' => '😴',
                _ => '',
              },
              style: const TextStyle(fontSize: 22),
            ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F4CA}', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Aucun historique', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Complete ta première séance\npour voir ta progression ici',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
}
