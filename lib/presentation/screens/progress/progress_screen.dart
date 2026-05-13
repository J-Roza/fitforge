import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/workout_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sessionHistoryProvider);
    final theme = Theme.of(context);

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
                        // ── Summary cards ─────────────────────────────────
                        _SummaryCards(history: history)
                            .animate()
                            .fadeIn(delay: 100.ms),
                        const SizedBox(height: 28),

                        // ── Volume chart ──────────────────────────────────
                        Text('Volume hebdomadaire (kg)', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        _VolumeChart(history: history)
                            .animate()
                            .fadeIn(delay: 200.ms),
                        const SizedBox(height: 28),

                        // ── Session frequency ─────────────────────────────
                        Text('Fréquence d\'entraînement', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        _FrequencyHeatmap(history: history)
                            .animate()
                            .fadeIn(delay: 300.ms),
                        const SizedBox(height: 28),

                        // ── Recent sessions ───────────────────────────────
                        Text('Historique des séances', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 14),
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
                      childCount: history.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final List history;
  const _SummaryCards({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekSessions = history.where((s) => s.startTime.isAfter(now.subtract(const Duration(days: 7)))).length;
    final totalSessions = history.length;
    final totalVolume = history.fold(0, (sum, s) => sum + s.totalVolume);

    return Row(
      children: [
        _StatCard(value: '$totalSessions', label: 'Total séances', icon: Icons.fitness_center_rounded, color: AppColors.accent),
        const SizedBox(width: 12),
        _StatCard(value: '$weekSessions', label: 'Cette semaine', icon: Icons.calendar_today_rounded, color: AppColors.secondary),
        const SizedBox(width: 12),
        _StatCard(value: '${(totalVolume / 1000).toStringAsFixed(0)}t', label: 'Volume total', icon: Icons.show_chart_rounded, color: AppColors.chest),
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
                  style: TextStyle(
                      color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1),
            ],
          ),
        ),
      );
}

class _VolumeChart extends StatelessWidget {
  final List history;
  const _VolumeChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // Last 7 weeks of volume data
    final spots = List.generate(7, (i) {
      final weekStart = DateTime.now().subtract(Duration(days: (6 - i) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final weekVolume = history
          .where((s) => s.startTime.isAfter(weekStart) && s.startTime.isBefore(weekEnd))
          .fold(0, (sum, s) => sum + s.totalVolume);
      return FlSpot(i.toDouble(), (weekVolume / 1000).toDouble());
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}t',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final labels = ['S-6', 'S-5', 'S-4', 'S-3', 'S-2', 'S-1', 'Ce'];
                  return Text(
                    labels[v.toInt()],
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  colors: [AppColors.accent.withOpacity(0.3), AppColors.accent.withOpacity(0)],
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
  final List history;
  const _FrequencyHeatmap({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

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
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(28, (i) {
              final day = now.subtract(Duration(days: 27 - i));
              final hasSession = history.any((s) {
                final d = s.startTime as DateTime;
                return d.year == day.year && d.month == day.month && d.day == day.day;
              });
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: hasSession ? AppColors.accent : AppColors.bgCardElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.bgCardElevated, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 6),
              const Text('Repos', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 14),
              Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 6),
              const Text('Entraînement', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryItem extends StatelessWidget {
  final dynamic session;
  const _SessionHistoryItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final startTime = session.startTime as DateTime;
    final duration = session.duration as Duration;
    final totalVolume = session.totalVolume as int;
    final muscles = (session.workout as dynamic).muscleGroups as List;

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
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.fitness_center_rounded, color: AppColors.accent, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((session.workout as dynamic).name as String,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  '${startTime.day}/${startTime.month} · ${duration.inMinutes}min · ${totalVolume}kg',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Terminé',
                style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
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
            const Text('📊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Aucun historique', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Complète ta première séance\npour voir ta progression ici',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
}
