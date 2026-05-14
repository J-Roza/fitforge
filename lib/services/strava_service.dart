import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/workout.dart';

// ── Strava app credentials ────────────────────────────────────────────────────
// Créer une app sur https://www.strava.com/settings/api
// Copier Client ID et Client Secret ici, et définir le redirect URI :
//   fitforge://strava-callback
const _clientId = 'VOTRE_CLIENT_ID';
const _clientSecret = 'VOTRE_CLIENT_SECRET';
const _redirectUri = 'fitforge://strava-callback';
const _scope = 'activity:write,read';

const _prefsAccessToken = 'strava_access_token';
const _prefsRefreshToken = 'strava_refresh_token';
const _prefsExpiresAt = 'strava_expires_at';
const _prefsAthleteId = 'strava_athlete_id';
const _prefsAthleteName = 'strava_athlete_name';

class StravaAuthState {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final int athleteId;
  final String athleteName;

  const StravaAuthState({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.athleteId,
    required this.athleteName,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt - 60;
}

class StravaService {
  static Future<StravaAuthState?> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsAccessToken);
    if (token == null) return null;
    return StravaAuthState(
      accessToken: token,
      refreshToken: prefs.getString(_prefsRefreshToken) ?? '',
      expiresAt: prefs.getInt(_prefsExpiresAt) ?? 0,
      athleteId: prefs.getInt(_prefsAthleteId) ?? 0,
      athleteName: prefs.getString(_prefsAthleteName) ?? 'Athlete',
    );
  }

  static Future<void> _save(StravaAuthState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsAccessToken, state.accessToken);
    await prefs.setString(_prefsRefreshToken, state.refreshToken);
    await prefs.setInt(_prefsExpiresAt, state.expiresAt);
    await prefs.setInt(_prefsAthleteId, state.athleteId);
    await prefs.setString(_prefsAthleteName, state.athleteName);
  }

  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsAccessToken);
    await prefs.remove(_prefsRefreshToken);
    await prefs.remove(_prefsExpiresAt);
    await prefs.remove(_prefsAthleteId);
    await prefs.remove(_prefsAthleteName);
  }

  static void openAuthPage() {
    final uri = Uri.parse(
      'https://www.strava.com/oauth/authorize'
      '?client_id=$_clientId'
      '&response_type=code'
      '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
      '&approval_prompt=auto'
      '&scope=$_scope',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<StravaAuthState?> exchangeCode(String code) async {
    final resp = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
    );
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final athlete = data['athlete'] as Map<String, dynamic>? ?? {};
    final state = StravaAuthState(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresAt: data['expires_at'] as int,
      athleteId: athlete['id'] as int? ?? 0,
      athleteName: '${athlete['firstname'] ?? ''} ${athlete['lastname'] ?? ''}'.trim(),
    );
    await _save(state);
    return state;
  }

  static Future<StravaAuthState?> refreshIfNeeded(StravaAuthState state) async {
    if (!state.isExpired) return state;
    final resp = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'refresh_token',
        'refresh_token': state.refreshToken,
      },
    );
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final refreshed = StravaAuthState(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresAt: data['expires_at'] as int,
      athleteId: state.athleteId,
      athleteName: state.athleteName,
    );
    await _save(refreshed);
    return refreshed;
  }

  static Future<bool> uploadSession(WorkoutSession session, StravaAuthState auth) async {
    final validAuth = await refreshIfNeeded(auth);
    if (validAuth == null) return false;

    final description = session.exercises.map((e) {
      final setsInfo = e.sets
          .where((s) => s.completed)
          .map((s) => '${s.reps} reps × ${s.weight.toStringAsFixed(s.weight % 1 == 0 ? 0 : 1)} kg')
          .join(', ');
      return '${e.exercise.name}: $setsInfo';
    }).join('\n');

    final body = jsonEncode({
      'name': session.workout.name,
      'type': 'WeightTraining',
      'sport_type': 'WeightTraining',
      'start_date_local': session.startTime.toUtc().toIso8601String(),
      'elapsed_time': session.duration.inSeconds,
      'description': description,
      'trainer': 1,
    });

    final resp = await http.post(
      Uri.parse('https://www.strava.com/api/v3/activities'),
      headers: {
        'Authorization': 'Bearer ${validAuth.accessToken}',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    return resp.statusCode == 201;
  }
}
