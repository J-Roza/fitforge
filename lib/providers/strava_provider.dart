import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/strava_service.dart';

final stravaProvider = StateNotifierProvider<StravaNotifier, StravaAuthState?>(
  (ref) => StravaNotifier()..loadSaved(),
);

class StravaNotifier extends StateNotifier<StravaAuthState?> {
  StravaNotifier() : super(null);

  Future<void> loadSaved() async {
    state = await StravaService.loadSaved();
  }

  Future<bool> handleCallback(String code) async {
    final auth = await StravaService.exchangeCode(code);
    state = auth;
    return auth != null;
  }

  Future<void> disconnect() async {
    await StravaService.disconnect();
    state = null;
  }

  Future<bool> uploadSession(session) async {
    final auth = state;
    if (auth == null) return false;
    return StravaService.uploadSession(session, auth);
  }
}
