import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/log_models.dart';
import '../../../providers/log_provider.dart';
import '../../../providers/exercise_provider.dart';
import '../../../services/health_service.dart';
import '../../../services/tcx_service.dart';
import '../../widgets/rest_duration_picker.dart';

// Weight options: null = PDC, then 1..200 by 0.5
final _weights = <double?>[null, ...List.generate(399, (i) => 1 + i * 0.5)];
final _repsOptions = List.generate(50, (i) => i + 1);
const _bwExercises = ['dips_chest', 'push_up', 'pull_up'];

class ActiveLogScreen extends ConsumerStatefulWidget {
  final int sessionType;
  final LogSession? previousSession;
  /// Si renseigné, l'écran modifie cette séance déjà enregistrée au lieu
  /// d'en démarrer une nouvelle (accessible depuis l'Historique).
  final LogSession? editSession;
  const ActiveLogScreen({
    super.key,
    required this.sessionType,
    this.previousSession,
    this.editSession,
  });

  bool get isEditing => editSession != null;

  @override
  ConsumerState<ActiveLogScreen> createState() => _ActiveLogScreenState();
}

class _ActiveLogScreenState extends ConsumerState<ActiveLogScreen> {
  final Map<String, List<LogSet>> _sets = {};
  final Map<String, String> _notes = {};
  final Map<String, double?> _selectedWeight = {};
  final Map<String, int> _selectedReps = {};
  final List<String> _exIds = [];

  late DateTime _startTime;
  final AudioPlayer _beepPlayer = AudioPlayer();

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 90;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDefaults());
  }

  Future<void> _initDefaults() async {
    // En mode édition : on repart exactement des exercices/séries déjà
    // enregistrés, pas de la composition actuelle de la séance-type.
    if (widget.isEditing) {
      final session = widget.editSession!;
      _exIds
        ..clear()
        ..addAll(session.exercises.map((e) => e.exerciseId));
      for (final ex in session.exercises) {
        _sets[ex.exerciseId] = List.from(ex.sets);
        _notes[ex.exerciseId] = ex.notes ?? '';
        final last = ex.sets.isNotEmpty ? ex.sets.last : null;
        _selectedWeight[ex.exerciseId] = last?.weight;
        _selectedReps[ex.exerciseId] = last?.reps ?? 10;
      }
      if (mounted) setState(() {});
      return;
    }

    // Reprise d'une séance déjà commencée : si on est sorti sans terminer,
    // on retrouve les séries/poids/notes déjà saisis.
    final draft =
        await ref.read(logServiceProvider).loadDraft(widget.sessionType);
    if (draft != null && _restoreFromDraft(draft)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Séance reprise là où tu t\'étais arrêté ✓'),
          duration: Duration(seconds: 2),
        ));
      }
      return;
    }

    final exIds = _getExerciseIds();
    // .future attend le chargement complet (évite de lire {} si l'appel
    // arrive avant la fin du chargement depuis SharedPreferences).
    final lw = await ref.read(lastWeightsProvider.future);
    final lr = await ref.read(lastRepsProvider.future);
    _exIds
      ..clear()
      ..addAll(exIds);
    for (final id in exIds) {
      _sets[id] = [];
      _selectedWeight[id] = lw.containsKey(id)
          ? lw[id]
          : (_bwExercises.contains(id) ? null : 20.0);
      _selectedReps[id] = lr[id] ?? 10;
    }
    final timerDur = await ref.read(timerDurationProvider.future);
    // Pré-remplissage depuis la séance précédente (bouton "Répéter")
    if (widget.previousSession != null) {
      for (final ex in widget.previousSession!.exercises) {
        if (_selectedWeight.containsKey(ex.exerciseId) && ex.sets.isNotEmpty) {
          _selectedWeight[ex.exerciseId] = ex.sets.last.weight;
          _selectedReps[ex.exerciseId] = ex.sets.last.reps;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _restTotal = timerDur;
    });
  }

  List<String> _getExerciseIds() {
    final configs = ref.read(sessionsConfigProvider);
    final custom = ref.read(customSessionsProvider).value ?? {};
    return getSessionExerciseIds(widget.sessionType, custom, configs);
  }

  /// Restaure l'état depuis un brouillon. Retourne `true` seulement si le
  /// brouillon contient au moins une série (sinon on repart proprement).
  bool _restoreFromDraft(Map<String, dynamic> d) {
    try {
      final exIds = List<String>.from(d['exIds'] as List? ?? const []);
      final setsRaw = Map<String, dynamic>.from(d['sets'] as Map? ?? const {});
      final hasSets =
          setsRaw.values.any((v) => (v as List).isNotEmpty);
      if (exIds.isEmpty || !hasSets) return false;

      _exIds
        ..clear()
        ..addAll(exIds);
      _sets.clear();
      setsRaw.forEach((k, v) => _sets[k] = (v as List)
          .map((s) => LogSet.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList());
      _notes.clear();
      (d['notes'] as Map?)?.forEach((k, v) => _notes[k as String] = '$v');
      _selectedWeight.clear();
      (d['selectedWeight'] as Map?)?.forEach((k, v) =>
          _selectedWeight[k as String] = v == null ? null : (v as num).toDouble());
      _selectedReps.clear();
      (d['selectedReps'] as Map?)
          ?.forEach((k, v) => _selectedReps[k as String] = v as int);

      // Garantit une entrée pour chaque exercice affiché.
      for (final id in _exIds) {
        _sets.putIfAbsent(id, () => []);
        _selectedReps.putIfAbsent(id, () => 10);
        _selectedWeight.putIfAbsent(
            id, () => _bwExercises.contains(id) ? null : 20.0);
      }

      final st = d['startTime'];
      if (st is String) _startTime = DateTime.tryParse(st) ?? _startTime;
      final rt = d['restTotal'];
      if (!mounted) return true;
      setState(() {
        if (rt is int) _restTotal = rt;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Persiste l'état courant de la séance (reprise possible après un retour
  /// arrière). Sans effet en mode édition d'une séance déjà enregistrée.
  void _saveDraft() {
    if (widget.isEditing) return;
    final draft = <String, dynamic>{
      'type': widget.sessionType,
      'startTime': _startTime.toIso8601String(),
      'restTotal': _restTotal,
      'exIds': _exIds,
      'sets': _sets.map(
          (k, v) => MapEntry(k, v.map((s) => s.toJson()).toList())),
      'notes': _notes,
      'selectedWeight': _selectedWeight,
      'selectedReps': _selectedReps,
    };
    ref.read(logServiceProvider).saveDraft(widget.sessionType, draft);
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
    ref.read(lastRepsProvider.notifier).setReps(exId, r);

    // Haptic feedback
    final oldPrs = ref.read(personalRecordsProvider);
    final newSets = _sets[exId] ?? [];
    final best = newSets.isEmpty
        ? null
        : newSets.reduce((a, b) => a.score >= b.score ? a : b);
    final old = oldPrs[exId];
    if (best != null && (old == null || best.score > old.score)) {
      HapticFeedback.heavyImpact();
    }
    HapticFeedback.lightImpact();

    // En mode édition, on corrige des données passées : pas de repos à décompter.
    if (!widget.isEditing) _startRestTimer();
    _saveDraft();
  }

  void _removeSet(String exId, int idx) {
    setState(() {
      final list = List<LogSet>.from(_sets[exId] ?? []);
      list.removeAt(idx);
      _sets[exId] = list;
    });
    _saveDraft();
  }

  Future<void> _addExerciseToSession(String id) async {
    if (_exIds.contains(id)) return;
    final lw = await ref.read(lastWeightsProvider.future);
    final lr = await ref.read(lastRepsProvider.future);
    if (!mounted) return;
    setState(() {
      _exIds.add(id);
      _sets[id] = [];
      _selectedWeight[id] = lw.containsKey(id)
          ? lw[id]
          : (_bwExercises.contains(id) ? null : 20.0);
      _selectedReps[id] = lr[id] ?? 10;
    });
    // En mode édition, on ne modifie pas le modèle de séance utilisé pour
    // les futures séances — seulement cette séance-ci.
    if (!widget.isEditing) _persistComposition();
    _saveDraft();
    HapticFeedback.lightImpact();
  }

  void _removeExerciseFromSession(String id) {
    setState(() {
      _exIds.remove(id);
      _sets.remove(id);
      _selectedWeight.remove(id);
      _selectedReps.remove(id);
      _notes.remove(id);
    });
    if (!widget.isEditing) _persistComposition();
    _saveDraft();
  }

  /// Enregistre durablement la composition de la séance (les exercices
  /// ajoutés/retirés sont retrouvés au prochain démarrage de cette séance).
  void _persistComposition() {
    ref
        .read(customSessionsProvider.notifier)
        .setSession(widget.sessionType, List<String>.from(_exIds));
  }

  void _confirmRemoveExercise(Exercise ex) {
    final hasSets = (_sets[ex.id] ?? []).isNotEmpty;
    if (!hasSets) {
      _removeExerciseFromSession(ex.id);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Retirer l\'exercice ?'),
        content: Text(
            '${ex.name} contient des séries enregistrées. Elles seront perdues.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeExerciseFromSession(ex.id);
              },
              child: const Text('Retirer',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  void _showAddExerciseSheet() {
    final all = ref.read(exercisesProvider);
    // Regroupe par muscle, exclut poulie et exercices déjà présents
    final Map<MuscleGroup, List<Exercise>> byMuscle = {};
    for (final e in all) {
      if (e.equipment.contains(Equipment.cable)) continue;
      if (_exIds.contains(e.id)) continue;
      byMuscle.putIfAbsent(e.primaryMuscle, () => []).add(e);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ajouter un exercice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            const Divider(height: 12),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: byMuscle.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            Text(entry.key.emoji,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(entry.key.label.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: entry.key.color,
                                    letterSpacing: .5)),
                          ],
                        ),
                      ),
                      ...entry.value.map((ex) => GestureDetector(
                            onTap: () async {
                              await _addExerciseToSession(ex.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.bgCardElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(ex.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Icon(Icons.add_circle_outline_rounded,
                                      size: 20, color: entry.key.color),
                                ],
                              ),
                            ),
                          )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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
          _playTimerEndAlert();
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

  Future<void> _playTimerEndAlert() async {
    HapticFeedback.heavyImpact();
    try {
      final soundId = ref.read(timerSoundProvider).value ?? 'alarme';
      final asset = kTimerSounds[soundId]?.$2 ?? 'sounds/timer_end_loud.wav';
      await _beepPlayer.setVolume(1.0);
      await _beepPlayer.play(AssetSource(asset));
    } catch (_) {
      // Pas de son dispo (ex: mode silencieux non géré) — la vibration suffit.
    }
  }

  /// Enregistre les modifications d'une séance déjà existante (mode édition).
  Future<void> _saveEdits() async {
    final hasSets = _sets.values.any((s) => s.isNotEmpty);
    if (!hasSets) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoute au moins 1 série !')));
      return;
    }
    final original = widget.editSession!;
    final exercises = _sets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => LogExercise(
            exerciseId: e.key, sets: e.value, notes: _notes[e.key]))
        .toList();
    final updated = LogSession(
        id: original.id,
        date: original.date,
        sessionType: widget.sessionType,
        exercises: exercises,
        feeling: original.feeling);
    await ref.read(logHistoryProvider.notifier).updateSession(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Color(0xFF30D158),
      content: Text('Modifications enregistrées ✓',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
    ));
    Navigator.pop(context);
  }

  Future<void> _finish() async {
    if (widget.isEditing) return _saveEdits();

    final hasSets = _sets.values.any((s) => s.isNotEmpty);
    if (!hasSets) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoute au moins 1 série !')));
      return;
    }
    _stopRestTimer();

    // Ressenti de fin de séance
    final feeling = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Comment s\'est passée la séance ?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FeelingButton(emoji: '💪', label: 'Super', value: 'great'),
            _FeelingButton(emoji: '😐', label: 'Moyen', value: 'ok'),
            _FeelingButton(emoji: '😴', label: 'Difficile', value: 'hard'),
          ],
        ),
      ),
    );

    final exercises = _sets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => LogExercise(
            exerciseId: e.key, sets: e.value, notes: _notes[e.key]))
        .toList();

    final session = LogSession(
        date: DateTime.now(),
        sessionType: widget.sessionType,
        exercises: exercises,
        feeling: feeling);
    await ref.read(logHistoryProvider.notifier).addSession(session);
    // Séance terminée : plus de brouillon à reprendre.
    await ref.read(logServiceProvider).clearDraft(widget.sessionType);

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

    // Sync Health Connect (Zepp)
    HealthService.writeWorkout(session).then((ok) {
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Synchro Health Connect ✓'),
              backgroundColor: Color(0xFF30D158)));
      }
    });

    if (!mounted) return;

    final configs = ref.read(sessionsConfigProvider);
    final config = configs.firstWhere(
        (c) => c.type == widget.sessionType, orElse: () => configs.first);
    final duration = DateTime.now().difference(_startTime);
    final allExercises = ref.read(exercisesProvider);
    final exerciseObjects = exercises.map((e) {
      try {
        return allExercises.firstWhere((ex) => ex.id == e.exerciseId);
      } catch (_) {
        return allExercises.first;
      }
    }).toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionSummarySheet(
        session: session,
        config: config,
        duration: duration,
        newPrs: newPrs,
        exercises: exerciseObjects,
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _beepPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configs = ref.watch(sessionsConfigProvider);
    final config = configs.firstWhere((c) => c.type == widget.sessionType,
        orElse: () => configs.first);
    final exIds = _exIds;
    final exercises = ref.watch(exercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: config.color.withValues(alpha: .12),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        widget.isEditing
                            ? '✏️ Modifier · S${config.type} · ${config.name}'
                            : 'S${config.type} · ${config.name}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: config.color)),
                    Text('${_totalVolume.toStringAsFixed(0)} kg total',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: config.color),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
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
                        onWeightChanged: (w) {
                          setState(() => _selectedWeight[exId] = w);
                          _saveDraft();
                        },
                        onRepsChanged: (r) {
                          setState(() => _selectedReps[exId] = r);
                          _saveDraft();
                        },
                        onAddSet: () => _addSet(exId),
                        onRemoveSet: (idx) => _removeSet(exId, idx),
                        onNoteChanged: (n) {
                          setState(() => _notes[exId] = n);
                          _saveDraft();
                        },
                        onRemoveExercise: exIds.length > 1
                            ? () => _confirmRemoveExercise(ex)
                            : null,
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: 60 * i));
                    },
                    childCount: exIds.length,
                  ),
                ),
              ),

              // Bouton ajouter un exercice
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: _showAddExerciseSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: config.color.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: config.color.withValues(alpha: .3),
                            width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              color: config.color, size: 20),
                          const SizedBox(width: 8),
                          Text('Ajouter un exercice',
                              style: TextStyle(
                                  color: config.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
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
                      final picked =
                          await showRestDurationPicker(context, ref);
                      if (picked == null || !mounted) return;
                      setState(() {
                        // Conserve le temps déjà écoulé de ce repos
                        final elapsed = _restTotal - _restRemaining;
                        _restTotal = picked;
                        if (_restRemaining > 0) {
                          _restRemaining =
                              (picked - elapsed).clamp(1, picked);
                        }
                      });
                      _saveDraft();
                    },
                    timerLabel: formatRestDuration(_restTotal),
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
                        AppColors.bg.withValues(alpha: 0),
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
                      child: Text(
                          widget.isEditing
                              ? 'Enregistrer les modifications'
                              : 'Terminer & Sauvegarder',
                          style: const TextStyle(
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

// ── Feeling button (fin de séance) ────────────────────────────
class _FeelingButton extends StatelessWidget {
  final String emoji, label, value;
  const _FeelingButton(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pop(context, value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ── Note field (affiche la note restaurée d'une séance reprise) ──
class _NoteField extends StatefulWidget {
  final String note;
  final ValueChanged<String> onChanged;
  const _NoteField({required this.note, required this.onChanged});

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.note);

  @override
  void didUpdateWidget(_NoteField old) {
    super.didUpdateWidget(old);
    // Met à jour le texte affiché quand la note change côté données
    // (ex : reprise d'une séance), sans perturber la saisie en cours.
    if (widget.note != old.note && widget.note != _ctrl.text) {
      _ctrl.text = widget.note;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          hintText: 'Note...',
          hintStyle:
              const TextStyle(color: AppColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: AppColors.bgCardElevated,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        style:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        onChanged: widget.onChanged,
      );
}

// ── Session Summary Sheet ─────────────────────────────────────
class _SessionSummarySheet extends StatelessWidget {
  final LogSession session;
  final SessionConfig config;
  final Duration duration;
  final List<String> newPrs;
  final List<Exercise> exercises;

  const _SessionSummarySheet({
    required this.session,
    required this.config,
    required this.duration,
    required this.newPrs,
    required this.exercises,
  });

  String _durationStr() {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    if (m == 0) return '${s}s';
    return s > 0 ? '${m}min ${s}s' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final feelingEmoji = switch (session.feeling) {
      'great' => '💪',
      'ok'    => '😐',
      'hard'  => '😴',
      _       => '✅',
    };
    final feelingLabel = switch (session.feeling) {
      'great' => 'Super séance !',
      'ok'    => 'Séance correcte',
      'hard'  => 'Séance difficile',
      _       => 'Séance terminée',
    };

    final muscles = exercises.map((e) => e.primaryMuscle).toSet().toList();

    final volStr = session.totalVolume >= 1000
        ? '${(session.totalVolume / 1000).toStringAsFixed(1)}t'
        : '${session.totalVolume.toStringAsFixed(0)}kg';

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  Text(feelingEmoji, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 8),
                  Text(feelingLabel,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('S${config.type} · ${config.name}',
                      style: TextStyle(
                          color: config.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),

                  // Stats
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _SumStat(
                            value: _durationStr(),
                            label: 'Durée',
                            icon: Icons.timer_outlined),
                        _SumDivider(),
                        _SumStat(
                            value: volStr,
                            label: 'Volume',
                            icon: Icons.fitness_center_rounded),
                        _SumDivider(),
                        _SumStat(
                            value: '${session.totalSets}',
                            label: 'Séries',
                            icon: Icons.repeat_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PRs
                  if (newPrs.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F0A).withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFF9F0A).withValues(alpha: .3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(
                            '${newPrs.length} nouveau${newPrs.length > 1 ? "x" : ""} record${newPrs.length > 1 ? "s" : ""} !',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF9F0A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Muscles travaillés
                  if (muscles.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('MUSCLES TRAVAILLÉS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: .5)),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: muscles
                            .map((m) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: m.color.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: m.color.withValues(alpha: .3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(m.emoji,
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(m.label,
                                          style: TextStyle(
                                              color: m.color,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Export TCX'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(
                                color: AppColors.accent.withValues(alpha: .4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            await TcxService.exportSession(
                                session,
                                'S${config.type} - ${config.name}');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Terminé',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
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

class _SumStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _SumStat(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _SumDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 40,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ── Exercise Card ─────────────────────────────────────────────
Widget _exerciseIconBox(Exercise exercise, Color color) => Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(14)),
      child: Center(
        child: SvgPicture.asset(
          exercise.iconAsset,
          width: 46,
          height: 46,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );

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
  final VoidCallback? onRemoveExercise;

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
    this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = exercise.primaryMuscle.color;
    final hist = ref.watch(exerciseHistoryProvider(exercise.id));
    final prs = ref.watch(personalRecordsProvider);
    final pr = prs[exercise.id];
    final lastEntry = hist.isNotEmpty ? hist.first : null;

    // Poids suggéré : dernier poids utilisé + progression si toutes séries >10 reps
    final isBodyweightExercise =
        exercise.equipment.contains(Equipment.bodyweight) ||
            _bwExercises.contains(exercise.id);
    double? suggestedWeight;
    if (hist.isNotEmpty && !isBodyweightExercise) {
      final lastSets = hist.first.sets.where((s) => !s.isBodyweight).toList();
      if (lastSets.isNotEmpty) {
        final lastWeight = lastSets
            .map((s) => s.weight ?? 0)
            .reduce((a, b) => a >= b ? a : b);
        final allOver10 =
            lastSets.isNotEmpty && lastSets.every((s) => s.reps > 10);
        suggestedWeight = allOver10 ? lastWeight + 2.5 : lastWeight;
      }
    }

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: exercise.photoAsset != null
                      ? Image.asset(
                          exercise.photoAsset!,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _exerciseIconBox(exercise, color),
                        )
                      : _exerciseIconBox(exercise, color),
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
                            color: color.withValues(alpha: .15),
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
                      if (suggestedWeight != null) ...[
                        const SizedBox(height: 2),
                        Text(
                            '💡 Suggéré : ${suggestedWeight % 1 == 0 ? suggestedWeight.toInt() : suggestedWeight}kg',
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ],
                      if (sets.isNotEmpty &&
                          lastEntry != null &&
                          lastEntry.sets.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Builder(builder: (context) {
                          final curBest = sets
                              .map((s) => s.score)
                              .reduce((a, b) => a > b ? a : b);
                          final prevBest = lastEntry.sets
                              .map((s) => s.score)
                              .reduce((a, b) => a > b ? a : b);
                          final up = curBest > prevBest * 1.005;
                          final down = curBest < prevBest * 0.995;
                          final arrowColor = up
                              ? const Color(0xFF30D158)
                              : down
                                  ? AppColors.error
                                  : AppColors.textMuted;
                          return Row(
                            children: [
                              Icon(
                                up
                                    ? Icons.trending_up_rounded
                                    : down
                                        ? Icons.trending_down_rounded
                                        : Icons.trending_flat_rounded,
                                size: 13,
                                color: arrowColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                up
                                    ? 'Progression'
                                    : down
                                        ? 'Régression'
                                        : 'Stable',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: arrowColor),
                              ),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                if (onRemoveExercise != null)
                  GestureDetector(
                    onTap: onRemoveExercise,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textMuted),
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
                            ? const Color(0xFFFF9F0A).withValues(alpha: .12)
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
            child: _NoteField(note: note, onChanged: onNoteChanged),
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
                Border.all(color: widget.color.withValues(alpha: .3)),
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
                            color: widget.color.withValues(alpha: .4),
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
