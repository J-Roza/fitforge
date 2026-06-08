import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/log_models.dart';

class LogService {
  static const _histKey   = 'ff_log_hist';
  static const _planKey   = 'ff_log_plan';
  static const _lwKey     = 'ff_log_lw';
  static const _timerKey  = 'ff_log_timer';
  static const _customKey = 'ff_log_custom';

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

  // ── Timer duration ────────────────────────────────────────
  Future<int> loadTimerDuration() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_timerKey) ?? 90;
  }

  Future<void> saveTimerDuration(int seconds) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_timerKey, seconds);
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
}
