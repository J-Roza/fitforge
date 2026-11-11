import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/feeling_icon.dart';

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

  // Mode « un exo par page » : page affichée + contrôleur du PageView.
  final PageController _pageCtrl = PageController();
  int _page = 0;

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
    // Atténue (duck) la musique en cours au lieu de la couper : le son du
    // minuteur passe par-dessus, puis la musique reprend son volume normal.
    _beepPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.duckOthers,
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    ));
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
          content: Text('Séance reprise là où tu t\'étais arrêté'),
          duration: Duration(seconds: 2),
        ));
      }
      return;
    }

    final exIds = _getExerciseIds();
    // Lecture défensive : si un provider est en erreur (ex. données de synchro
    // au mauvais format), on continue avec des valeurs par défaut au lieu
    // d'avorter (ce qui laissait la séance vide).
    Map<String, double?> lw = {};
    Map<String, int> lr = {};
    try {
      lw = await ref.read(lastWeightsProvider.future);
    } catch (_) {}
    try {
      lr = await ref.read(lastRepsProvider.future);
    } catch (_) {}
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
    ref.read(logServiceProvider).saveDraft(widget.sessionType, draft).then((_) {
      if (mounted) ref.invalidate(draftSessionsProvider);
    });
  }

  /// Efface la séance en cours (brouillon) pour repartir d'une séance vierge.
  Future<void> _restartSession() async {
    final hasContent = _sets.values.any((s) => s.isNotEmpty);
    if (hasContent) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('Repartir de zéro ?'),
          content: const Text(
              'Les séries et notes de cette séance en cours seront effacées.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Annuler')),
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Effacer',
                    style: TextStyle(color: AppColors.error))),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(logServiceProvider).clearDraft(widget.sessionType);
    ref.invalidate(draftSessionsProvider);
    if (!mounted) return;
    setState(() {
      for (final id in _exIds) {
        _sets[id] = [];
        _notes[id] = '';
      }
      _stopRestTimer();
    });
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
    final removed = (_sets[exId] ?? [])[idx];
    setState(() {
      final list = List<LogSet>.from(_sets[exId] ?? []);
      list.removeAt(idx);
      _sets[exId] = list;
    });
    _saveDraft();
    // Un tap raté sur une puce ne doit pas coûter une série : annulation 4 s.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Série ${idx + 1} supprimée (${removed.display})'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'ANNULER',
          textColor: AppColors.accent,
          onPressed: () {
            if (!mounted || !_sets.containsKey(exId)) return;
            setState(() {
              final list = List<LogSet>.from(_sets[exId] ?? []);
              list.insert(idx.clamp(0, list.length), removed);
              _sets[exId] = list;
            });
            _saveDraft();
          },
        ),
      ));
  }

  Future<void> _addExerciseToSession(String id) async {
    if (_exIds.contains(id)) return;
    Map<String, double?> lw = {};
    Map<String, int> lr = {};
    try {
      lw = await ref.read(lastWeightsProvider.future);
    } catch (_) {}
    try {
      lr = await ref.read(lastRepsProvider.future);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _exIds.add(id);
      _sets[id] = [];
      _selectedWeight[id] = lw.containsKey(id)
          ? lw[id]
          : (_bwExercises.contains(id) ? null : 20.0);
      _selectedReps[id] = lr[id] ?? 10;
    });
    // Affiche directement le nouvel exercice (dernière page).
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _goToPage(_exIds.length - 1));
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
      // Reste sur une page valide après suppression de la dernière.
      if (_page >= _exIds.length) {
        _page = _exIds.isEmpty ? 0 : _exIds.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients && _exIds.isNotEmpty) {
        _pageCtrl.jumpToPage(_page);
      }
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
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: entry.key.color,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
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
        // Petit signal à 10 s de la fin : le temps de se remettre en place.
        if (_restRemaining == 10) HapticFeedback.lightImpact();
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
    // Motif de 3 impulsions : une seule ne se sent pas, téléphone posé sur un banc.
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 220));
    }
    try {
      final soundId = ref.read(timerSoundProvider).value ?? 'carillon';
      final asset = kTimerSounds[soundId]?.$2 ?? 'sounds/timer_carillon.wav';
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
      backgroundColor: AppColors.success,
      content: Text('Modifications enregistrées',
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
    // Le bouton Terminer est juste sous la zone de saisie : on prévient si des
    // exercices n'ont aucune série, et on laisse toujours une porte de sortie.
    final skipped = _exIds.where((id) => (_sets[id] ?? []).isEmpty).length;

    // 1re confirmation : récapitulatif chiffré, « Terminer » bien séparé.
    final doneCount = _exIds.length - skipped;
    final totalSets = _sets.values.fold<int>(0, (v, s) => v + s.length);
    final mins = DateTime.now().difference(_startTime).inMinutes;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Terminer la séance ?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(
          '$doneCount exercice${doneCount > 1 ? 's' : ''} · '
          '$totalSets série${totalSets > 1 ? 's' : ''} · $mins min'
          '${skipped > 0 ? '\n\n$skipped exercice${skipped > 1 ? 's' : ''} sans série ne '
              '${skipped > 1 ? 'seront' : 'sera'} pas enregistré${skipped > 1 ? 's' : ''}.' : ''}',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Continuer la séance'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // 2e étape : ressenti (fermable, ne valide rien tant qu'on n'a pas choisi).
    final feeling = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Comment s\'est passée la séance ?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FeelingButton(label: 'Super', value: 'great'),
                _FeelingButton(label: 'Moyen', value: 'ok'),
                _FeelingButton(label: 'Difficile', value: 'hard'),
              ],
            ),
            if (skipped > 0) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        '$skipped exercice${skipped > 1 ? 's' : ''} sans série ne '
                        '${skipped > 1 ? 'seront' : 'sera'} pas enregistré'
                        '${skipped > 1 ? 's' : ''}.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Continuer la séance'),
          ),
        ],
      ),
    );
    // Fermé sans choisir : on reste sur la séance, rien n'est enregistré.
    if (feeling == null || !mounted) return;
    _stopRestTimer();

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
    // Records AVANT l'ajout : une fois la séance dans l'historique, le
    // provider la compte déjà et aucun nouveau PR ne serait détecté.
    final oldPrs = ref.read(personalRecordsProvider);
    await ref.read(logHistoryProvider.notifier).addSession(session);
    // Séance terminée : plus de brouillon à reprendre.
    await ref.read(logServiceProvider).clearDraft(widget.sessionType);
    ref.invalidate(draftSessionsProvider);

    // Check PRs
    final newPrs = <String>[];
    for (final ex in exercises) {
      final best = ex.bestSet;
      if (best != null) {
        final old = oldPrs[ex.exerciseId];
        if (old == null || best.score > old.score) newPrs.add(ex.exerciseId);
      }
    }

    // Envoi vers Health Connect (si l'utilisateur l'a activé dans le profil).
    HealthService.writeWorkout(session, start: _startTime, end: session.date)
        .then((ok) {
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Synchro Health Connect'),
              backgroundColor: AppColors.success));
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
    _pageCtrl.dispose();
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Exercise exOf(String id) => exercises.firstWhere((e) => e.id == id,
        orElse: () => exercises.first);

    // La barre timer + Terminer est SOUS la page (pas en surimpression) :
    // elle ne peut plus masquer les boutons de saisie.
    const bottomPad = 24.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: config.color.withValues(alpha: .12),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.isEditing
                    ? 'Modifier · S${config.type} · ${config.name}'
                    : 'S${config.type} · ${config.name}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: config.color)),
            Text('${_totalVolume.toStringAsFixed(0)} kg total',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: config.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.isEditing)
            IconButton(
              tooltip: 'Repartir de zéro',
              icon: Icon(Icons.restart_alt_rounded, color: config.color),
              onPressed: _restartSession,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: Column(
            children: [
              // Bandeau de navigation : un pavé par exercice, le courant en
              // surbrillance. Un tap fait défiler jusqu'à la page voulue.
              _ExerciseStrip(
                exercises: exIds.map(exOf).toList(),
                setsDone:
                    exIds.map((id) => (_sets[id] ?? []).length).toList(),
                current: _page,
                accent: config.color,
                onTap: _goToPage,
                onAdd: _showAddExerciseSheet,
              ),
              // Un exercice par page : impossible de se tromper d'exo.
              Expanded(
                child: exIds.isEmpty
                    ? Center(
                        child: Text('Ajoute un exercice pour commencer',
                            style: TextStyle(color: AppColors.textMuted)))
                    : PageView.builder(
                        controller: _pageCtrl,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemCount: exIds.length,
                        itemBuilder: (ctx, i) {
                          final exId = exIds[i];
                          final ex = exOf(exId);
                          return _ExercisePage(
                            key: ValueKey(exId),
                            index: i,
                            count: exIds.length,
                            exercise: ex,
                            sets: _sets[exId] ?? [],
                            selectedWeight: _selectedWeight[exId],
                            selectedReps: _selectedReps[exId] ?? 10,
                            note: _notes[exId] ?? '',
                            bottomPadding: bottomPad,
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
                          );
                        },
                      ),
              ),
            ],
          )),

          // Rest timer + finish bar, sous la page.
          Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_restRemaining > 0)
                  _RestTimerBar(
                    remaining: _restRemaining,
                    total: _restTotal,
                    onStop: _stopRestTimer,
                    onExtend: () => _extendRest(30),
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
                      16, 10, 16, 12 + bottomInset),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
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
        ],
      ),
    );
  }

  /// Fait défiler jusqu'à l'exercice [i] (bandeau du haut, ajout d'exo).
  void _goToPage(int i) {
    if (!_pageCtrl.hasClients) return;
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  /// Prolonge le repos en cours sans toucher à la durée par défaut.
  void _extendRest(int seconds) {
    if (_restRemaining <= 0) return;
    setState(() => _restRemaining += seconds);
  }
}

// ── Feeling button (fin de séance) ────────────────────────────
class _FeelingButton extends StatelessWidget {
  final String label, value;
  const _FeelingButton({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pop(context, value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeelingIcon(value, size: 30),
            const SizedBox(height: 6),
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
              TextStyle(color: AppColors.textMuted, fontSize: 12),
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
            TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  _SessionSummarySheet({
    required this.session,
    required this.config,
    required this.duration,
    required this.newPrs,
    required this.exercises,
  });

  final GlobalKey _shareKey = GlobalKey();

  /// Capture la carte récap en image PNG et la partage.
  Future<void> _shareImage() async {
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final volStr = session.totalVolume >= 1000
          ? '${(session.totalVolume / 1000).toStringAsFixed(1)}t'
          : '${session.totalVolume.toStringAsFixed(0)} kg';
      await Share.shareXFiles(
        [
          XFile.fromData(bytes.buffer.asUint8List(),
              mimeType: 'image/png', name: 'seance_fitforge.png')
        ],
        text: 'Ma séance FitForge — $volStr, ${session.totalSets} séries',
      );
    } catch (_) {}
  }

  String _durationStr() {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    if (m == 0) return '${s}s';
    return s > 0 ? '${m}min ${s}s' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final feeling = feelingInfo(session.feeling);

    final muscles = exercises.map((e) => e.primaryMuscle).toSet().toList();

    final volStr = session.totalVolume >= 1000
        ? '${(session.totalVolume / 1000).toStringAsFixed(1)}t'
        : '${session.totalVolume.toStringAsFixed(0)}kg';

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      decoration: BoxDecoration(
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
                  RepaintBoundary(
                    key: _shareKey,
                    child: Container(
                      color: AppColors.bgCard,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 10),
                      child: Column(
                        children: [
                  FeelingIcon(session.feeling, size: 46),
                  const SizedBox(height: 10),
                  Text(feeling.label,
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
                        color: AppColors.gold.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: .3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: AppColors.gold, size: 26),
                          const SizedBox(width: 12),
                          Text(
                            '${newPrs.length} nouveau${newPrs.length > 1 ? "x" : ""} record${newPrs.length > 1 ? "s" : ""} !',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Muscles travaillés
                  if (muscles.isNotEmpty) ...[
                    Align(
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
                                      Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              color: m.color,
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 7),
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
                        ],
                      ),
                    ),
                  ),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.ios_share_rounded, size: 16),
                          label: const Text('Partager'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(
                                color: AppColors.accent.withValues(alpha: .4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _shareImage,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.description_outlined, size: 16),
                          label: const Text('TCX'),
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
                            foregroundColor: AppColors.onAccent,
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
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(label,
                style: TextStyle(
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

// ── Exercise visuals ──────────────────────────────────────────
Widget _exerciseIconBox(Exercise exercise, Color color,
        {double size = 68, double iconSize = 46, double radius = 14}) =>
    Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(radius)),
      child: Center(
        child: SvgPicture.asset(
          exercise.iconAsset,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );

/// Vignette carrée (photo si disponible, sinon pictogramme).
Widget _exerciseThumb(Exercise exercise, Color color,
    {required double size, double radius = 14, double iconSize = 46}) {
  final icon = _exerciseIconBox(exercise, color,
      size: size, iconSize: iconSize, radius: radius);
  if (exercise.photoAsset == null) return icon;
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(exercise.photoAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => icon),
  );
}

/// Couleur de texte lisible sur [bg] (les couleurs de muscle vont du
/// jaune clair au rouge vif).
Color _onColor(Color bg) =>
    bg.computeLuminance() > .5 ? Colors.black : Colors.white;

// ── Bandeau de navigation entre exercices ─────────────────────
class _ExerciseStrip extends StatefulWidget {
  final List<Exercise> exercises;
  final List<int> setsDone;
  final int current;
  final Color accent;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  const _ExerciseStrip({
    required this.exercises,
    required this.setsDone,
    required this.current,
    required this.accent,
    required this.onTap,
    required this.onAdd,
  });

  @override
  State<_ExerciseStrip> createState() => _ExerciseStripState();
}

class _ExerciseStripState extends State<_ExerciseStrip> {
  final _scroll = ScrollController();
  // Largeur d'un pavé (55) + espacement (10).
  static const _itemW = 65.0;

  @override
  void didUpdateWidget(_ExerciseStrip old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _reveal();
  }

  /// Garde le pavé courant visible (centré quand c'est possible).
  void _reveal() {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final target = (widget.current * _itemW - viewport / 2 + _itemW / 2)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: widget.exercises.length + 1,
        itemBuilder: (ctx, i) {
          // Dernier pavé : ajouter un exercice.
          if (i == widget.exercises.length) {
            return GestureDetector(
              onTap: widget.onAdd,
              child: Container(
                width: 55,
                height: 55,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.accent.withValues(alpha: .08),
                  border: Border.all(
                      color: widget.accent.withValues(alpha: .4), width: 1.5),
                ),
                child: Icon(Icons.add_rounded, color: widget.accent),
              ),
            );
          }
          final ex = widget.exercises[i];
          final color = ex.primaryMuscle.color;
          final isCurrent = i == widget.current;
          final done = widget.setsDone[i];
          return GestureDetector(
            onTap: () => widget.onTap(i),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCurrent ? 1 : .5,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isCurrent ? color : Colors.transparent,
                            width: 2.5),
                      ),
                      child: _exerciseThumb(ex, color,
                          size: 46, radius: 11, iconSize: 30),
                    ),
                    if (done > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.bgCard, width: 2),
                          ),
                          child: Text('$done',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _onColor(color))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Page d'un exercice (mode « un exo par page ») ─────────────
class _ExercisePage extends ConsumerWidget {
  final int index, count;
  final Exercise exercise;
  final List<LogSet> sets;
  final double? selectedWeight;
  final int selectedReps;
  final String note;
  final double bottomPadding;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback? onRemoveExercise;

  const _ExercisePage({
    super.key,
    required this.index,
    required this.count,
    required this.exercise,
    required this.sets,
    required this.selectedWeight,
    required this.selectedReps,
    required this.note,
    required this.bottomPadding,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onNoteChanged,
    this.onRemoveExercise,
  });

  /// Boutons rapides ±1 kg. Sous 1 kg on repasse en poids du corps (PDC) ;
  /// depuis PDC, « + » démarre à 1 kg (lest).
  void _stepWeight(double delta) {
    final cur = selectedWeight;
    double? next;
    if (cur == null) {
      next = delta > 0 ? 1.0 : null;
    } else {
      final n = cur + delta;
      next = n < 1 ? null : n.clamp(1.0, 200.0);
    }
    // Reste sur la grille de 0,5 kg du sélecteur.
    if (next != null) next = (next * 2).round() / 2;
    onWeightChanged(next);
  }

  void _stepReps(int delta) =>
      onRepsChanged((selectedReps + delta).clamp(1, 50));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = exercise.primaryMuscle.color;
    final hist = ref.watch(exerciseHistoryProvider(exercise.id));
    final prs = ref.watch(personalRecordsProvider);
    final pr = prs[exercise.id];
    final lastEntry = hist.isNotEmpty ? hist.first : null;
    final lastBest = (lastEntry != null && lastEntry.sets.isNotEmpty)
        ? lastEntry.sets.reduce((a, b) => a.score >= b.score ? a : b)
        : null;

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
        final allOver10 = lastSets.every((s) => s.reps > 10);
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

    // Tendance vs dernière séance (visible dès la première série validée).
    Widget? trend;
    if (sets.isNotEmpty && lastBest != null) {
      final curBest =
          sets.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      final prevBest = lastBest.score;
      final up = curBest > prevBest * 1.005;
      final down = curBest < prevBest * 0.995;
      final c = up
          ? AppColors.success
          : down
              ? AppColors.error
              : AppColors.textMuted;
      trend = _InfoChip(
        icon: up
            ? Icons.trending_up_rounded
            : down
                ? Icons.trending_down_rounded
                : Icons.trending_flat_rounded,
        label: up
            ? 'Progression'
            : down
                ? 'Régression'
                : 'Stable',
        color: c,
        filled: true,
      );
    }

    String fmtW(double w) => w % 1 == 0 ? '${w.toInt()}' : '$w';
    String? prLabel;
    if (pr != null) {
      final showRm = !pr.isBodyweight && pr.weight != null && pr.reps > 1;
      final rm = showRm
          ? ' · 1RM ≈ ${(pr.weight! * (1 + pr.reps / 30)).round()} kg'
          : '';
      prLabel = 'PR ${pr.display}$rm';
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête : grande photo + nom, impossible de confondre l'exo.
          _ExerciseHero(
            exercise: exercise,
            color: color,
            index: index,
            count: count,
            onRemove: onRemoveExercise,
          ),
          const SizedBox(height: 12),

          // Repères compacts (dernière fois, record, suggestion, tendance).
          if (lastBest != null || prLabel != null || suggestedWeight != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (lastBest != null)
                  _InfoChip(
                      icon: Icons.history_rounded,
                      label: 'Dernière ${lastBest.display}',
                      color: AppColors.textSecondary),
                if (prLabel != null)
                  _InfoChip(
                      icon: Icons.emoji_events_rounded,
                      label: prLabel,
                      color: AppColors.gold),
                if (suggestedWeight != null)
                  _InfoChip(
                      icon: Icons.lightbulb_rounded,
                      label: 'Suggéré ${fmtW(suggestedWeight)} kg',
                      color: color),
                if (trend != null) trend,
              ],
            ),

          // Séries validées
          if (sets.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('SÉRIES · ${sets.length}',
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sets.asMap().entries.map((e) {
                final isBest = e.key == bestIdx && sets.length > 1;
                final chipColor = isBest ? AppColors.gold : color;
                return GestureDetector(
                  onTap: () => onRemoveSet(e.key),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 7, 9, 7),
                    decoration: BoxDecoration(
                      color: isBest
                          ? AppColors.gold.withValues(alpha: .12)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isBest ? AppColors.gold : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: chipColor.withValues(alpha: .2),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: chipColor)),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(e.value.display,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isBest
                                    ? AppColors.gold
                                    : AppColors.textPrimary)),
                        if (isBest) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.emoji_events_rounded,
                              size: 14, color: AppColors.gold),
                        ],
                        const SizedBox(width: 6),
                        Icon(Icons.close_rounded,
                            size: 13, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Saisie : poids / reps avec boutons rapides, puis validation.
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PickerColumn(
                        label: 'POIDS (KG)',
                        color: color,
                        onMinus: () => _stepWeight(-1),
                        onPlus: () => _stepWeight(1),
                        child: _WheelPicker<double?>(
                          items: _weights,
                          selected: selectedWeight,
                          display: (w) => w == null ? 'PDC' : fmtW(w),
                          onChanged: onWeightChanged,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerColumn(
                        label: 'REPS',
                        color: color,
                        onMinus: () => _stepReps(-1),
                        onPlus: () => _stepReps(1),
                        child: _WheelPicker<int>(
                          items: _repsOptions,
                          selected: selectedReps,
                          display: (r) => '$r',
                          onChanged: onRepsChanged,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: onAddSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: _onColor(color),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 22),
                    label: Text('Valider la série ${sets.length + 1}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _NoteField(note: note, onChanged: onNoteChanged),
        ],
      ),
    );
  }
}

// ── En-tête plein écran d'un exercice ─────────────────────────
class _ExerciseHero extends StatelessWidget {
  final Exercise exercise;
  final Color color;
  final int index, count;
  final VoidCallback? onRemove;

  const _ExerciseHero({
    required this.exercise,
    required this.color,
    required this.index,
    required this.count,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = exercise.photoAsset != null;
    Widget bigIcon() => Container(
          color: color.withValues(alpha: .18),
          child: Center(
            child: SvgPicture.asset(
              exercise.iconAsset,
              width: 120,
              height: 120,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasPhoto
                ? Image.asset(exercise.photoAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => bigIcon())
                : bigIcon(),
            // Dégradé pour la lisibilité du titre.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [.3, 1],
                  colors: [
                    Colors.black.withValues(alpha: hasPhoto ? .05 : 0),
                    Colors.black.withValues(alpha: .8),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(exercise.primaryMuscle.label.toUpperCase(),
                        style: TextStyle(
                            color: _onColor(color),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6)),
                  ),
                  const SizedBox(height: 6),
                  Text(exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: Colors.white)),
                ],
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('EXO ${index + 1} / $count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5)),
              ),
            ),
            if (onRemove != null)
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Puce d'information (icône + texte) ────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _InfoChip(
      {required this.icon,
      required this.label,
      required this.color,
      this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: .12) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: filled ? color : AppColors.textPrimary)),
          ],
        ),
      );
}

// ── Colonne de saisie : libellé + [−] roulette [+] ────────────
class _PickerColumn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onMinus, onPlus;
  final Widget child;

  const _PickerColumn(
      {required this.label,
      required this.color,
      required this.onMinus,
      required this.onPlus,
      required this.child});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .6)),
          const SizedBox(height: 6),
          Row(
            children: [
              _StepButton(
                  icon: Icons.remove_rounded, color: color, onTap: onMinus),
              const SizedBox(width: 6),
              Expanded(child: child),
              const SizedBox(width: 6),
              _StepButton(
                  icon: Icons.add_rounded, color: color, onTap: onPlus),
            ],
          ),
        ],
      );
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StepButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 38,
          height: 52,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
      );
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
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: widget.color.withValues(alpha: .3)),
          ),
          child: Center(
            child: Text(widget.display(widget.selected),
                style: TextStyle(
                    fontSize: 20,
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
                              style: TextStyle(
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
                      foregroundColor: _onColor(widget.color),
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
  final VoidCallback onStop, onCycle, onExtend;
  final String timerLabel;

  const _RestTimerBar(
      {required this.remaining,
      required this.total,
      required this.onStop,
      required this.onCycle,
      required this.onExtend,
      required this.timerLabel});

  @override
  Widget build(BuildContext context) {
    // « +30 s » peut dépasser la durée initiale : la barre reste pleine.
    final progress = (remaining / total).clamp(0.0, 1.0);
    final m = remaining ~/ 60, s = remaining % 60;
    final urgent = remaining <= 5;
    final color = urgent ? AppColors.error : AppColors.accent;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .45), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .14),
                        shape: BoxShape.circle),
                    child: Icon(Icons.timer_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REPOS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                              color: AppColors.textMuted)),
                      Text('$m:${s.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              color: color,
                              fontFeatures: const [
                                ui.FontFeature.tabularFigures()
                              ])),
                    ],
                  ),
                  const Spacer(),
                  _TimerAction(label: '+30 s', color: color, onTap: onExtend),
                  const SizedBox(width: 6),
                  _TimerAction(
                      label: timerLabel,
                      color: AppColors.textSecondary,
                      onTap: onCycle),
                  IconButton(
                    tooltip: 'Passer le repos',
                    onPressed: onStop,
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.bgCardElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TimerAction(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        // 44 px de haut minimum : cible tactile fiable avec les mains moites.
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: .35))),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ),
      );
}
