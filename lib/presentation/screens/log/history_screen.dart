import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/log_models.dart';
import '../../../providers/log_provider.dart';
import '../../../providers/exercise_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history =
        ref.watch(logHistoryProvider).value?.reversed.toList() ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Historique',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [Tab(text: 'Séances'), Tab(text: 'Records')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _SessionsTab(history: history),
          const _RecordsTab(),
        ],
      ),
    );
  }
}

class _SessionsTab extends ConsumerWidget {
  final List<LogSession> history;
  const _SessionsTab({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(sessionsConfigProvider);
    if (history.isEmpty) {
      return const Center(
          child: Text('Aucune séance enregistrée.\nLance-toi ! 💪',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final s = history[i];
        final config = configs.firstWhere((c) => c.type == s.sessionType,
            orElse: () => configs.first);
        return _SessionEntry(session: s, config: config);
      },
    );
  }
}

class _SessionEntry extends ConsumerStatefulWidget {
  final LogSession session;
  final SessionConfig config;
  const _SessionEntry({required this.session, required this.config});

  @override
  ConsumerState<_SessionEntry> createState() => _SessionEntryState();
}

class _SessionEntryState extends ConsumerState<_SessionEntry> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);
    final s = widget.session;
    final c = widget.config;
    final dateStr = DateFormat('EEE d MMM', 'fr_FR').format(s.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text('S${s.sessionType} · ${c.name}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: c.color.withOpacity(.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            '${s.exercises.length} exo · ${s.totalSets} séries',
                            style: TextStyle(
                                fontSize: 11,
                                color: c.color,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                          '📦 ${s.totalVolume.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: s.exercises.map((ex) {
                  final exercise = exercises.firstWhere(
                      (e) => e.id == ex.exerciseId,
                      orElse: () => exercises.first);
                  final best = ex.bestSet;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: ex.sets.map((set) {
                            final isBest = best != null &&
                                set == best &&
                                ex.sets.length > 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isBest
                                    ? const Color(0xFFFF9F0A)
                                        .withOpacity(.1)
                                    : AppColors.bgCardElevated,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                    color: isBest
                                        ? const Color(0xFFFF9F0A)
                                        : AppColors.border),
                              ),
                              child: Text(set.display,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isBest
                                          ? const Color(0xFFFF9F0A)
                                          : AppColors.textPrimary)),
                            );
                          }).toList(),
                        ),
                        Text(
                            'Volume : ${ex.totalVolume.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                        if (ex.notes != null && ex.notes!.isNotEmpty)
                          Text('💬 ${ex.notes}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      title: const Text('Supprimer ?'),
                      content: const Text(
                          'Cette séance sera définitivement supprimée.'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Annuler')),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Supprimer',
                                style: TextStyle(
                                    color: AppColors.error))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    ref
                        .read(logHistoryProvider.notifier)
                        .removeSession(s.id);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withOpacity(.2)),
                  ),
                  child: const Center(
                      child: Text('🗑 Supprimer cette séance',
                          style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordsTab extends ConsumerWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prs = ref.watch(personalRecordsProvider);
    final exercises = ref.watch(exercisesProvider);

    if (prs.isEmpty) {
      return const Center(
          child: Text(
              'Aucun record encore.\nComplète ta première séance !',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: prs.entries.map((entry) {
        final ex = exercises.firstWhere((e) => e.id == entry.key,
            orElse: () => exercises.first);
        final pr = entry.value;
        final hist = ref.watch(exerciseHistoryProvider(entry.key));
        final estRM = pr.isBodyweight
            ? null
            : (pr.weight! * (1 + pr.reps / 30));

        // LineChart : 10 dernières séances
        final recentHistory = hist.take(10).toList().reversed.toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('🏆 ${pr.display}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF9F0A))),
                          if (estRM != null)
                            Text('≈ 1RM : ${estRM.round()} kg',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          Text('${hist.length} séance(s)',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (recentHistory.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: recentHistory.asMap().entries.map((e) {
                              final best = e.value.sets.isEmpty
                                  ? null
                                  : e.value.sets.reduce((a, b) =>
                                      a.score >= b.score ? a : b);
                              final y = best == null
                                  ? 0.0
                                  : (best.isBodyweight
                                      ? best.reps.toDouble()
                                      : (best.weight ?? 0));
                              return FlSpot(e.key.toDouble(), y);
                            }).toList(),
                            isCurved: true,
                            color: ex.primaryMuscle.color,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: ex.primaryMuscle.color.withOpacity(.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
