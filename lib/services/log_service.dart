import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/log_models.dart';

class LogService {
  static const _histKey   = 'ff_log_hist';
  static const _planKey   = 'ff_log_plan';
  static const _lwKey     = 'ff_log_lw';
  static const _lrKey     = 'ff_log_lr';
  static const _timerKey  = 'ff_log_timer';
  static const _customKey = 'ff_log_custom';
  static const _sessionsConfigKey = 'ff_log_sessions_config';

  // ── History ───────────────────────────────────────────────
  Future<List<LogSession>> loadHistory() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_histKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => LogSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveHistory(List<LogSession> sessions) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_histKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  // ── Planning ──────────────────────────────────────────────
  Future<Map<int, int>> loadPlanning() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_planKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> savePlanning(Map<int, int> plan) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_planKey, jsonEncode(plan.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ── Last weights ─────────────────────────────────────────
  Future<Map<String, double?>> loadLastWeights() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_lwKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as double?));
  }

  Future<void> saveLastWeights(Map<String, double?> lw) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_lwKey, jsonEncode(lw));
  }

  // ── Last reps ──────────────────────────────────────────────
  Future<Map<String, int>> loadLastReps() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_lrKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveLastReps(Map<String, int> lr) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_lrKey, jsonEncode(lr));
  }

  // ── Timer duration ────────────────────────────────────────
  Future<int> loadTimerDuration() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_timerKey) ?? 90;
  }

  Future<void> saveTimerDuration(int seconds) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_timerKey, seconds);
  }

  // ── Timer sound ────────────────────────────────────────────
  static const _timerSoundKey = 'ff_timer_sound';

  /// 'alarme' (défaut, fort) ou 'beep'.
  Future<String> loadTimerSound() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_timerSoundKey) ?? 'alarme';
  }

  Future<void> saveTimerSound(String sound) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_timerSoundKey, sound);
  }

  // ── Brouillon de séance en cours (reprise après retour arrière) ──
  // Permet de retrouver une séance commencée si on quitte l'écran sans
  // l'avoir terminée. Un brouillon par type de séance. Local uniquement.
  static const _draftKey = 'ff_log_draft';

  Future<Map<int, Map<String, dynamic>>> _loadAllDrafts() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_draftKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
        (k, v) => MapEntry(int.parse(k), Map<String, dynamic>.from(v as Map)));
  }

  Future<void> _saveAllDrafts(Map<int, Map<String, dynamic>> all) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _draftKey, jsonEncode(all.map((k, v) => MapEntry(k.toString(), v))));
  }

  /// Brouillon pour un type de séance, ou `null` si aucun.
  Future<Map<String, dynamic>?> loadDraft(int type) async {
    final all = await _loadAllDrafts();
    return all[type];
  }

  Future<void> saveDraft(int type, Map<String, dynamic> draft) async {
    final all = await _loadAllDrafts();
    all[type] = draft;
    await _saveAllDrafts(all);
  }

  Future<void> clearDraft(int type) async {
    final all = await _loadAllDrafts();
    if (all.remove(type) != null) await _saveAllDrafts(all);
  }

  // ── Purge des anciennes séances de démo (one-time) ────────
  // L'app injectait autrefois des séances "seed_*" factices au premier
  // lancement. On les retire définitivement des installations existantes.
  static const _seedPurgedKey = 'ff_log_seed_purged_v1';

  /// Retire les séances de démo héritées. Retourne `true` si l'historique
  /// a changé (pour déclencher une synchro cloud).
  Future<bool> purgeSeedSessionsOnce() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_seedPurgedKey) == true) return false; // déjà fait

    final existing = await loadHistory();
    final cleaned = existing.where((s) => !s.id.startsWith('seed_')).toList();
    final changed = cleaned.length != existing.length;
    if (changed) {
      await saveHistory(cleaned);
    }
    await p.setBool(_seedPurgedKey, true);
    return changed;
  }

  // ── Custom sessions ───────────────────────────────────────
  Future<Map<int, List<String>>> loadCustomSessions() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_customKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), List<String>.from(v as List)));
  }

  Future<void> saveCustomSessions(Map<int, List<String>> custom) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_customKey, jsonEncode(custom.map((k, v) => MapEntry(k.toString(), v))));
  }

  // ── Sessions config (séances créées/éditées par l'utilisateur) ────
  /// Retourne `null` si rien n'a encore été persisté (utiliser les défauts).
  Future<List<SessionConfig>?> loadSessionsConfig() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_sessionsConfigKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => SessionConfig.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSessionsConfig(List<SessionConfig> sessions) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_sessionsConfigKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }
}
