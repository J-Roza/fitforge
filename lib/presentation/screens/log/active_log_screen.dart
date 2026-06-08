import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/log_models.dart';
import '../../../providers/log_provider.dart';
import '../../../providers/exercise_provider.dart';

// Weight options: null = PDC, then 5..100
final _weights = <double?>[null, ...List.generate(96, (i) => (i + 5).toDouble())];
final _repsOptions = List.generate(25, (i) => i + 1);
const _bwExercises = ['dips_chest', 'push_up', 'pull_up'];

class ActiveLogScreen extends ConsumerStatefulWidget {
  final int sessionType;
  const ActiveLogScreen({super.key, required this.sessionType});

  @override
  ConsumerState<ActiveLogScreen> createState() => _ActiveLogScreenState();
}

class _ActiveLogScreenState extends ConsumerState<ActiveLogScreen> {
  final Map<String, List<LogSet>> _sets = {};
  final Map<String, String> _notes = {};
  final Map<String, double?> _selectedWeight = {};
  final Map<String, int> _selectedReps = {};

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 90;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDefaults());
  }

  void _initDefaults() {
    final exIds = _getExerciseIds();
    final lw = ref.read(lastWeightsProvider).value ?? {};
    for (final id in exIds) {
      _sets[id] = [];
      _selectedWeight[id] = lw.containsKey(id)
          ? lw[id]
          : (_bwExercises.contains(id) ? null : 20.0);
      _selectedReps[id] = 10;
    }
    final timerDur = ref.read(timerDurationProvider).value ?? 90;
    setState(() {
      _restTotal = timerDur;
    });
  }

  List<String> _getExerciseIds() {
    final configs = ref.read(sessionsConfigProvider);
    final custom = ref.read(customSessionsProvider).value ?? {};
    return getSessionExerciseIds(widget.sessionType, custom, configs);
  }

  double get _totalVolume => _sets.values.fold(
      0.0,
      (v, sets) => v +
          sets.fold(
              0.0,
              (sv, s) =>
                  sv + (s.isBodyweight ? 0 : (s.weight ?? 0) * s.reps)));

  void _addSet(String exId) {
    final w = _selectedWeight[exId];
    final r = _selectedReps[exId] ?? 10;
    final set = LogSet(isBodyweight: w == null, weight: w, reps: r);
    setState(() {
      _sets[exId] = [...(_sets[exId] ?? []), set];
    });
    ref.read(lastWeightsProvider.notifier).setWeight(exId, w);
    _startRestTimer();
  }

  void _removeSet(String exId, int idx) {
    setState(() {
      final list = List<LogSet>.from(_sets[exId] ?? []);
      list.removeAt(idx);
      _sets[exId] = list;
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restRemaining = _restTotal;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _restRemaining--;
        if (_restRemaining <= 0) {
          t.cancel();
          _restRemaining = 0;
        }
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restRemaining = 0;
    });
  }

  Future<void> _finish() async {
    final hasSets = _sets.values.any((s) => s.isNotEmpty);
    if (!hasSets) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoute au moins 1 série !')));
      return;
    }
    _stopRestTimer();

    final exercises = _sets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => LogExercise(
            exerciseId: e.key, sets: e.value, notes: _notes[e.key]))
        .toList();

    final session = LogSession(
        date: DateTime.now(),
        sessionType: widget.sessionType,
        exercises: exercises);
    await ref.read(logHistoryProvider.notifier).addSession(session);

    // Check PRs
    final oldPrs = ref.read(personalRecordsProvider);
    final newPrs = <String>[];
    for (final ex in exercises) {
      final best = ex.bestSet;
      if (best != null) {
        final old = oldPrs[ex.exerciseId];
        if (old == null || best.score > old.score) newPrs.add(ex.exerciseId);
      }
    }

    if (mounted) {
      if (newPrs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFFF9F0A),
          content: Text(
              '🏆 ${newPrs.length} nouveau(x) record(s) !',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w700)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF30D158),
          content: Text('Séance sauvegardée ✓',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w700)),
        ));
      }
      context.pop();
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configs = ref.watch(sessionsConfigProvider);
    final config = configs.firstWhere((c) => c.type == widget.sessionType);
    final exIds = _getExerciseIds();
    final exercises = ref.watch(exercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bg,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('S${config.type} · ${config.name}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('${_totalVolume.toStringAsFixed(0)} kg total',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.bgCard,
                        title: const Text('Quitter ?'),
                        content: const Text(
                            'Les données non sauvegardées seront perdues.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler')),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.pop();
                              },
                              child: const Text('Quitter',
                                  style: TextStyle(
                                      color: AppColors.error))),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final exId = exIds[i];
                      final ex = exercises.firstWhere(
                          (e) => e.id == exId,
                          orElse: () => exercises.first);
                      return _ExerciseCard(
                        exercise: ex,
                        sets: _sets[exId] ?? [],
                        selectedWeight: _selectedWeight[exId],
                        selectedReps: _selectedReps[exId] ?? 10,
                        note: _notes[exId] ?? '',
                        onWeightChanged: (w) =>
                            setState(() => _selectedWeight[exId] = w),
                        onRepsChanged: (r) =>
                            setState(() => _selectedReps[exId] = r),
                        onAddSet: () => _addSet(exId),
                        onRemoveSet: (idx) => _removeSet(exId, idx),
                        onNoteChanged: (n) =>
                            setState(() => _notes[exId] = n),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: 60 * i));
                    },
                    childCount: exIds.length,
                  ),
                ),
              ),
            ],
          ),

          // Rest timer + finish bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_restRemaining > 0)
                  _RestTimerBar(
                    remaining: _restRemaining,
                    total: _restTotal,
                    onStop: _stopRestTimer,
                    onCycle: () async {
                      await ref
                          .read(timerDurationProvider.notifier)
                          .cycle();
                      setState(() {
                        _restTotal =
                            ref.read(timerDurationProvider).value ?? 90;
                      });
                    },
                    timerLabel: '${_restTotal}s',
                  ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      16 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bg.withOpacity(0),
                        AppColors.bg
                      ],
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Terminer & Sauvegarder',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
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

// ── Exercise Card ─────────────────────────────────────────────
class _ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final List<LogSet> sets;
  final double? selectedWeight;
  final int selectedReps;
  final String note;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final ValueChanged<String> onNoteChanged;

  const _ExerciseCard({
    required this.exercise,
    required this.sets,
    required this.selectedWeight,
    required this.selectedReps,
    required this.note,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = exercise.primaryMuscle.color;
    final hist = ref.watch(exerciseHistoryProvider(exercise.id));
    final prs = ref.watch(personalRecordsProvider);
    final pr = prs[exercise.id];
    final lastEntry = hist.isNotEmpty ? hist.first : null;

    final bestIdx = sets.isEmpty
        ? -1
        : sets
            .asMap()
            .entries
            .reduce((a, b) => a.value.score >= b.value.score ? a : b)
            .key;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                      color: color.withOpacity(.15),
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: SvgPicture.asset(
                      exercise.iconAsset,
                      width: 46,
                      height: 46,
                      colorFilter:
                          ColorFilter.mode(color, BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                            color: color.withOpacity(.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(exercise.primaryMuscle.label,
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                      if (lastEntry != null) ...[
                        const SizedBox(height: 5),
                        Text(
                            '📋 Dernière fois : ${lastEntry.sets.isNotEmpty ? lastEntry.sets.reduce((a, b) => a.score >= b.score ? a : b).display : "—"}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                      if (pr != null) ...[
                        const SizedBox(height: 2),
                        Text('🏆 PR : ${pr.display}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFFF9F0A))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sets chips
          if (sets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sets.asMap().entries.map((e) {
                  final isBest = e.key == bestIdx && sets.length > 1;
                  return GestureDetector(
                    onTap: () => onRemoveSet(e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: isBest
                            ? const Color(0xFFFF9F0A).withOpacity(.12)
                            : AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isBest
                                ? const Color(0xFFFF9F0A)
                                : AppColors.border),
                      ),
                      child: Text(
                        (isBest ? '🏆 ' : '') + e.value.display,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isBest
                              ? const Color(0xFFFF9F0A)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Pickers row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Row(
              children: [
                // Weight picker
                Expanded(
                  child: Column(
                    children: [
                      const Text('POIDS',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .5)),
                      const SizedBox(height: 4),
                      _WheelPicker<double?>(
                        items: _weights,
                        selected: selectedWeight,
                        display: (w) => w == null
                            ? 'PDC'
                            : '${w % 1 == 0 ? w.toInt() : w}',
                        onChanged: onWeightChanged,
                        color: color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Reps picker
                Expanded(
                  child: Column(
                    children: [
                      const Text('REPS',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .5)),
                      const SizedBox(height: 4),
                      _WheelPicker<int>(
                        items: _repsOptions,
                        selected: selectedReps,
                        display: (r) => '$r',
                        onChanged: onRepsChanged,
                        color: color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Add button
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: GestureDetector(
                    onTap: onAddSet,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Note
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Note...',
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.bgCardElevated,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              onChanged: onNoteChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wheel picker ──────────────────────────────────────────────
class _WheelPicker<T> extends StatefulWidget {
  final List<T> items;
  final T selected;
  final String Function(T) display;
  final ValueChanged<T> onChanged;
  final Color color;

  const _WheelPicker(
      {required this.items,
      required this.selected,
      required this.display,
      required this.onChanged,
      required this.color});

  @override
  State<_WheelPicker<T>> createState() => _WheelPickerState<T>();
}

class _WheelPickerState<T> extends State<_WheelPicker<T>> {
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    final idx = widget.items.indexOf(widget.selected);
    _ctrl = FixedExtentScrollController(initialItem: idx < 0 ? 0 : idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _showPicker(context),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: widget.color.withOpacity(.3)),
          ),
          child: Center(
            child: Text(widget.display(widget.selected),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: widget.color)),
          ),
        ),
      );

  void _showPicker(BuildContext context) {
    final idx = widget.items.indexOf(widget.selected);
    final ctrl =
        FixedExtentScrollController(initialItem: idx < 0 ? 0 : idx);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SizedBox(
        height: 280,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Expanded(
              child: CupertinoPicker(
                scrollController: ctrl,
                itemExtent: 42,
                backgroundColor: Colors.transparent,
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                        horizontal: BorderSide(
                            color: widget.color.withOpacity(.4),
                            width: 1.5)),
                  ),
                ),
                onSelectedItemChanged: (i) =>
                    widget.onChanged(widget.items[i]),
                children: widget.items
                    .map((item) => Center(
                          child: Text(widget.display(item),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('OK',
                        style:
                            TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rest timer bar ────────────────────────────────────────────
class _RestTimerBar extends StatelessWidget {
  final int remaining, total;
  final VoidCallback onStop, onCycle;
  final String timerLabel;

  const _RestTimerBar(
      {required this.remaining,
      required this.total,
      required this.onStop,
      required this.onCycle,
      required this.timerLabel});

  @override
  Widget build(BuildContext context) {
    final progress = remaining / total;
    final m = remaining ~/ 60, s = remaining % 60;
    return Container(
      color: AppColors.bgCard,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('⏱', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.bgCardElevated,
                valueColor: const AlwaysStoppedAnimation(
                    AppColors.accent),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$m:${s.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCycle,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.bgCardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border)),
              child: Text(timerLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onStop,
            child: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }
}
