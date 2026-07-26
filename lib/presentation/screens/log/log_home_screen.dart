import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/log_models.dart';
import '../../../data/models/exercise.dart';
import '../../../providers/log_provider.dart';
import '../../../data/datasources/exercises_data.dart';
import 'active_log_screen.dart';
import 'history_screen.dart';
import 'planning_screen.dart';

class LogHomeScreen extends ConsumerWidget {
  final bool showBack;
  const LogHomeScreen({super.key, this.showBack = true});

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

    // Calcul du streak : nombre de semaines consécutives avec au moins 1 séance
    int weekStreak = 0;
    {
      final now = DateTime.now();
      // Numéro de semaine ISO pour chaque séance
      Set<int> weeksWithSession(int startOffset) {
        return history
            .map((s) {
              final diff = now.difference(s.date).inDays + startOffset;
              return diff ~/ 7;
            })
            .toSet();
      }
      final weeks = weeksWithSession(0);
      int w = 0;
      while (weeks.contains(w)) {
        weekStreak++;
        w++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('FitForge Log',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
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
              const SizedBox(width: 10),
              _StatBox(value: '${weekStreak}sem', label: 'STREAK'),
            ],
          ).animate().fadeIn(delay: 50.ms),
          const SizedBox(height: 16),
          _WeeklyGoal(weekCount: weekCount)
              .animate()
              .fadeIn(delay: 70.ms),
          const SizedBox(height: 12),

          // Today banner
          if (todayConfig != null) ...[
            _TodayBanner(config: todayConfig).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 16),
          ],

          // Session grid 2x2 + tuile "Ajouter"
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.0,
            children: [
              ...List.generate(sessions.length, (i) {
                final s = sessions[i];
                final exIds = getSessionExerciseIds(s.type, custom, sessions);
                final last = _lastSessionOfType(history, s.type);
                return _SessionCard(
                  config: s,
                  exCount: exIds.length,
                  lastDate: last?.date,
                  lastSession: last,
                ).animate().fadeIn(delay: Duration(milliseconds: 120 + i * 50));
              }),
              const _AddSessionCard()
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 120 + sessions.length * 50)),
            ],
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
                backgroundColor: config.color.withValues(alpha: .15),
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
  final LogSession? lastSession;
  const _SessionCard({required this.config, required this.exCount, this.lastDate, this.lastSession});

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
                if (lastSession != null)
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) => ActiveLogScreen(
                                sessionType: config.type,
                                previousSession: lastSession))),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: config.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: config.color.withValues(alpha: .25)),
                      ),
                      child:
                          Icon(Icons.replay_rounded, size: 13, color: config.color),
                    ),
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

// ── Add session card ─────────────────────────────────────────
class _AddSessionCard extends StatelessWidget {
  const _AddSessionCard();

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.bgCard,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: const _CreateSessionSheet(),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.border, style: BorderStyle.solid),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 28, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('Nouvelle séance',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      );
}

// ── Create session sheet ─────────────────────────────────────
class _CreateSessionSheet extends ConsumerStatefulWidget {
  const _CreateSessionSheet();

  @override
  ConsumerState<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends ConsumerState<_CreateSessionSheet> {
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  Color _color = _sessionColorPalette[4];

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donne un nom à la séance.')));
      return;
    }
    final type = ref.read(sessionsConfigProvider.notifier).addSession(
          name: name.toUpperCase(),
          subtitle: _subtitle.text.trim().isEmpty
              ? 'Séance personnalisée'
              : _subtitle.text.trim(),
          color: _color,
        );
    Navigator.of(context).pop();

    final config = ref.read(sessionsConfigProvider).firstWhere((s) => s.type == type);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _SessionEditorSheet(config: config, initialIds: const []),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 18),
          const Text('Nouvelle séance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Tu pourras ajouter les exercices juste après.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text('NOM', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: .5)),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Ex : FULL BODY',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgCardElevated,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('SOUS-TITRE (optionnel)', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: .5)),
          const SizedBox(height: 8),
          TextField(
            controller: _subtitle,
            decoration: InputDecoration(
              hintText: 'Ex : Corps entier',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.bgCardElevated,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('COULEUR', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: .5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _sessionColorPalette.map((c) {
              final selected = c.toARGB32() == _color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Créer la séance',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
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

// Palette de couleurs proposées pour les séances (perso ou par défaut)
const _sessionColorPalette = [
  Color(0xFFE8484F), Color(0xFF4F9EE8), Color(0xFF30D158), Color(0xFFFF9F0A),
  Color(0xFFAF52DE), Color(0xFF5AC8FA), Color(0xFFFFD60A), Color(0xFFFF375F),
  Color(0xFFBF5AF2), Color(0xFFA2845E),
];

class _SessionEditorSheetState extends ConsumerState<_SessionEditorSheet> {
  late List<String> _draft;
  late TextEditingController _name;
  late TextEditingController _subtitle;
  late Color _color;

  // All exercises grouped by muscle
  // Tous les exercices regroupés par muscle (poulie exclue : pas d'équipement).
  Map<String, List<String>> get _groups {
    const order = [
      MuscleGroup.chest,
      MuscleGroup.back,
      MuscleGroup.shoulders,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.legs,
      MuscleGroup.glutes,
      MuscleGroup.core,
      MuscleGroup.cardio,
      MuscleGroup.fullBody,
    ];
    final byMuscle = <MuscleGroup, List<String>>{};
    for (final e in allExercises) {
      if (e.equipment.contains(Equipment.cable)) continue; // pas de poulie
      byMuscle.putIfAbsent(e.primaryMuscle, () => []).add(e.id);
    }
    final result = <String, List<String>>{};
    for (final m in order) {
      final ids = byMuscle[m];
      if (ids != null && ids.isNotEmpty) result[m.label] = ids;
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _draft = List.from(widget.initialIds);
    _name = TextEditingController(text: widget.config.name);
    _subtitle = TextEditingController(text: widget.config.subtitle);
    _color = widget.config.color;
  }

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  String _exName(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id).name;
    } catch (_) { return id; }
  }

  void _save() {
    final sessions = ref.read(sessionsConfigProvider);
    final match = sessions.where((s) => s.type == widget.config.type);
    final defaults = match.isEmpty ? const <String>[] : match.first.defaultExerciseIds;
    final isSameAsDefault = _draft.length == defaults.length &&
        _draft.asMap().entries.every((e) => e.value == defaults[e.key]);
    if (isSameAsDefault) {
      ref.read(customSessionsProvider.notifier).resetSession(widget.config.type, defaults);
    } else {
      ref.read(customSessionsProvider.notifier).setSession(widget.config.type, _draft);
    }

    final nameChanged = _name.text.trim() != widget.config.name;
    final subtitleChanged = _subtitle.text.trim() != widget.config.subtitle;
    final colorChanged = _color != widget.config.color;
    if (nameChanged || subtitleChanged || colorChanged) {
      ref.read(sessionsConfigProvider.notifier).updateSession(
            widget.config.type,
            name: _name.text.trim().isEmpty ? null : _name.text.trim(),
            subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
            color: _color,
          );
    }

    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final sessions = ref.read(sessionsConfigProvider);
    if (sessions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tu dois garder au moins une séance.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Supprimer cette séance ?'),
        content: Text(
            '« ${widget.config.name} » sera supprimée. L\'historique des séances déjà réalisées est conservé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sessionsConfigProvider.notifier).removeSession(widget.config.type);
      if (mounted) Navigator.of(context).pop();
    }
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
                  child: Text('S${widget.config.type} · ${_name.text}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _color)),
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
                // Nom + sous-titre + couleur
                const Text('NOM DE LA SÉANCE', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: .5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.bgCardElevated,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('SOUS-TITRE', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: .5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _subtitle,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ex : Pecs · Épaules · Triceps',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.bgCardElevated,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('COULEUR', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: .5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _sessionColorPalette.map((c) {
                    final selected = c.toARGB32() == _color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Current exercises (réordonnables par glisser-déposer)
                const Text('EXERCICES ACTUELS · glisse pour réordonner', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: .5)),
                const SizedBox(height: 8),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _draft.removeAt(oldIndex);
                      _draft.insert(newIndex, item);
                    });
                  },
                  children: _draft.asMap().entries.map((entry) {
                    final i = entry.key;
                    final id = entry.value;
                    return Container(
                      key: ValueKey(id),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(Icons.drag_handle_rounded,
                                  size: 20, color: AppColors.textMuted),
                            ),
                          ),
                          Expanded(
                            child: Text(_exName(id),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          if (_draft.length > 1)
                            GestureDetector(
                              onTap: () => setState(() => _draft.remove(id)),
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.error),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

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
                    final match = ref.read(sessionsConfigProvider)
                        .where((s) => s.type == widget.config.type);
                    final defaults = match.isEmpty ? const <String>[] : match.first.defaultExerciseIds;
                    setState(() => _draft = List.from(defaults));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(child: Text('Remettre les exercices par defaut',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _confirmDelete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: .2)),
                    ),
                    child: const Center(child: Text('🗑 Supprimer cette séance',
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

// ── Add past session sheet ─────────────────────────────────
// ── Weekly goal ───────────────────────────────────────────────
class _WeeklyGoal extends StatelessWidget {
  final int weekCount;
  static const int _goal = 3;
  const _WeeklyGoal({required this.weekCount});

  @override
  Widget build(BuildContext context) {
    final done = weekCount >= _goal;
    final progress = (weekCount / _goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: done
                ? AppColors.accent.withValues(alpha: .4)
                : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(done ? '✅' : '🎯',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                '$weekCount/$_goal séances cette semaine',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (done)
                Text('OBJECTIF !',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgCardElevated,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}