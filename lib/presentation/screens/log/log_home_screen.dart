import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/log_models.dart';
import '../../../providers/log_provider.dart';
import '../../../providers/exercise_provider.dart';
import '../../../data/datasources/exercises_data.dart';
import 'active_log_screen.dart';
import 'history_screen.dart';
import 'planning_screen.dart';

class LogHomeScreen extends ConsumerWidget {
  const LogHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions  = ref.watch(sessionsConfigProvider);
    final history   = ref.watch(logHistoryProvider).value ?? [];
    final plan      = ref.watch(planningProvider).value ?? {};
    final custom    = ref.watch(customSessionsProvider).value ?? {};

    final todayWeekday = DateTime.now().weekday % 7;
    final todayType    = plan[todayWeekday];
    final todayConfig  = todayType != null
        ? sessions.firstWhere((s) => s.type == todayType, orElse: () => sessions.first)
        : null;

    final weekCount = history.where((s) =>
        DateTime.now().difference(s.date).inDays < 7).length;
    final totalVol = history.fold<double>(0, (v, s) => v + s.totalVolume);
    final volStr = totalVol >= 1000
        ? '${(totalVol / 1000).toStringAsFixed(1)}t'
        : '${totalVol.toStringAsFixed(0)}kg';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('FitForge Log',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Stats
          Row(
            children: [
              _StatBox(value: '${history.length}', label: 'SEANCES'),
              const SizedBox(width: 10),
              _StatBox(value: '$weekCount', label: 'CETTE SEMAINE'),
              const SizedBox(width: 10),
              _StatBox(value: volStr, label: 'VOLUME TOTAL'),
            ],
          ).animate().fadeIn(delay: 50.ms),
          const SizedBox(height: 16),

          // Today banner
          if (todayConfig != null) ...[
            _TodayBanner(config: todayConfig).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 16),
          ],

          // Session grid 2x2
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.0,
            children: List.generate(sessions.length, (i) {
              final s = sessions[i];
              final exIds = getSessionExerciseIds(s.type, custom, sessions);
              final last = _lastSessionOfType(history, s.type);
              return _SessionCard(
                config: s,
                exCount: exIds.length,
                lastDate: last?.date,
              ).animate().fadeIn(delay: Duration(milliseconds: 120 + i * 50));
            }),
          ),
          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: _NavBtn(
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  onTap: () => Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NavBtn(
                  icon: Icons.calendar_today_rounded,
                  label: 'Planning',
                  onTap: () => Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(builder: (_) => const PlanningScreen())),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  LogSession? _lastSessionOfType(List<LogSession> history, int type) {
    for (var i = history.length - 1; i >= 0; i--) {
      if (history[i].sessionType == type) return history[i];
    }
    return null;
  }
}

// ── Stat box ──────────────────────────────────────────────────
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
              Text(value, style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accent)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted,
                  fontWeight: FontWeight.w600, letterSpacing: .4)),
            ],
          ),
        ),
      );
}

// ── Today banner ──────────────────────────────────────────────
class _TodayBanner extends ConsumerWidget {
  final SessionConfig config;
  const _TodayBanner({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
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
                  Text("AUJOURD'HUI", style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: config.color, letterSpacing: 1)),
                  const SizedBox(height: 3),
                  Text('S${config.type} · ${config.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(config.subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) =>
                      ActiveLogScreen(sessionType: config.type))),
              style: TextButton.styleFrom(
                backgroundColor: config.color.withOpacity(.15),
                foregroundColor: config.color,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Demarrer',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      );
}

// ── Session card ──────────────────────────────────────────────
class _SessionCard extends ConsumerWidget {
  final SessionConfig config;
  final int exCount;
  final DateTime? lastDate;
  const _SessionCard({required this.config, required this.exCount, this.lastDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastStr = lastDate != null
        ? '${lastDate!.day}/${lastDate!.month}'
        : 'Jamais';
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) =>
              ActiveLogScreen(sessionType: config.type))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('S${config.type} · $exCount exo',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: config.color)),
                ),
                GestureDetector(
                  onTap: () => _openEditor(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.bgCardElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 13, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(config.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(config.subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                maxLines: 2),
            const SizedBox(height: 8),
            Text('Derniere : $lastStr',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref) {
    final sessions = ref.read(sessionsConfigProvider);
    final custom   = ref.read(customSessionsProvider).value ?? {};
    final current  = List<String>.from(getSessionExerciseIds(config.type, custom, sessions));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _SessionEditorSheet(config: config, initialIds: current),
      ),
    );
  }
}

// ── Session editor bottom sheet ───────────────────────────────
class _SessionEditorSheet extends ConsumerStatefulWidget {
  final SessionConfig config;
  final List<String> initialIds;
  const _SessionEditorSheet({required this.config, required this.initialIds});

  @override
  ConsumerState<_SessionEditorSheet> createState() => _SessionEditorSheetState();
}

class _SessionEditorSheetState extends ConsumerState<_SessionEditorSheet> {
  late List<String> _draft;

  // All exercises grouped by muscle
  static const _groups = {
    'Pectoraux': ['bench_press', 'incline_bench_press', 'dumbbell_bench_press', 'machine_chest_press_flat', 'dips_chest', 'push_up', 'dumbbell_flyes', 'cable_crossover'],
    'Dos':       ['pull_up', 'barbell_row', 'dumbbell_row', 'lat_pulldown', 'seated_row', 'face_pull'],
    'Epaules':   ['ohp', 'arnold_press', 'lateral_raise', 'front_raise'],
    'Biceps':    ['barbell_curl', 'preacher_curl', 'concentration_curl', 'hammer_curl'],
    'Triceps':   ['skull_crusher', 'tricep_pushdown', 'overhead_tricep_extension', 'close_grip_bench', 'dips_chest'],
    'Jambes':    ['squat', 'deadlift', 'romanian_deadlift', 'leg_press', 'lunges', 'leg_extension', 'leg_curl', 'calf_raise', 'hip_thrust'],
    'Abdos':     ['plank', 'crunch', 'leg_raise', 'ab_wheel', 'russian_twist'],
  };

  @override
  void initState() {
    super.initState();
    _draft = List.from(widget.initialIds);
  }

  String _exName(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id).name;
    } catch (_) { return id; }
  }

  void _save() {
    final sessions = ref.read(sessionsConfigProvider);
    final defaults = sessions.firstWhere((s) => s.type == widget.config.type).defaultExerciseIds;
    final isSameAsDefault = _draft.length == defaults.length &&
        _draft.asMap().entries.every((e) => e.value == defaults[e.key]);
    if (isSameAsDefault) {
      ref.read(customSessionsProvider.notifier).resetSession(widget.config.type, defaults);
    } else {
      ref.read(customSessionsProvider.notifier).setSession(widget.config.type, _draft);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text('S${widget.config.type} · ${widget.config.name}',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: widget.config.color)),
                ),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                // Current exercises
                const Text('EXERCICES ACTUELS', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: .5)),
                const SizedBox(height: 8),
                ..._draft.map((id) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(_exName(id),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      if (_draft.length > 1)
                        GestureDetector(
                          onTap: () => setState(() => _draft.remove(id)),
                          child: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                        ),
                    ],
                  ),
                )),

                const SizedBox(height: 20),
                const Text('AJOUTER UN EXERCICE', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: .5)),
                const SizedBox(height: 10),

                // Available exercises by group
                ..._groups.entries.map((entry) {
                  final avail = entry.value.where((id) => !_draft.contains(id)).toList();
                  if (avail.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(entry.key.toUpperCase(), style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted,
                            fontWeight: FontWeight.w700, letterSpacing: .5)),
                      ),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: avail.map((id) => GestureDetector(
                          onTap: () => setState(() => _draft.add(id)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.bgCardElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(_exName(id), style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    final defaults = ref.read(sessionsConfigProvider)
                        .firstWhere((s) => s.type == widget.config.type).defaultExerciseIds;
                    setState(() => _draft = List.from(defaults));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(.2)),
                    ),
                    child: const Center(child: Text('Remettre les exercices par defaut',
                        style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.onTap});

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
              Text(label, style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}