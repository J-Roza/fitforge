import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/log_models.dart';

/// Intégration Google Health Connect (Android).
///
/// L'utilisateur active la synchro depuis le profil (« Connecter Health
/// Connect »). Une fois l'autorisation d'écriture accordée, chaque séance
/// terminée est envoyée comme un entraînement « Musculation ».
class HealthService {
  HealthService._();

  static final Health _health = Health();
  static bool _configured = false;

  // On n'écrit que des entraînements → permission d'écriture sur WORKOUT.
  static const List<HealthDataType> _types = [HealthDataType.WORKOUT];
  static const List<HealthDataAccess> _perms = [HealthDataAccess.WRITE];

  // Drapeau local : l'utilisateur a explicitement activé la synchro.
  static const _connectedKey = 'ff_health_connected';

  /// Plateforme prise en charge (Health Connect = Android uniquement ici).
  static bool get isSupportedPlatform => Platform.isAndroid;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Health Connect est-il disponible/installé sur cet appareil ?
  static Future<bool> isAvailable() async {
    if (!isSupportedPlatform) return false;
    try {
      await _ensureConfigured();
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return false;
    }
  }

  /// L'utilisateur a-t-il activé la synchro (drapeau local) ?
  static Future<bool> isConnected() async {
    if (!isSupportedPlatform) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(_connectedKey) ?? false;
  }

  /// Ouvre la demande d'autorisation Health Connect. Retourne true si accordée.
  static Future<bool> connect() async {
    if (!isSupportedPlatform) return false;
    try {
      await _ensureConfigured();
      if (!await _health.isHealthConnectAvailable()) return false;
      var granted =
          await _health.hasPermissions(_types, permissions: _perms) ?? false;
      if (!granted) {
        granted =
            await _health.requestAuthorization(_types, permissions: _perms);
      }
      final p = await SharedPreferences.getInstance();
      await p.setBool(_connectedKey, granted);
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Coupe la synchro côté app (drapeau local ; ne révoque pas l'autorisation
  /// dans Health Connect lui-même, ce qui se fait dans les réglages Android).
  static Future<void> disconnect() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_connectedKey, false);
  }

  /// Redirige vers le Play Store pour installer Health Connect si absent.
  static Future<void> promptInstall() async {
    if (!isSupportedPlatform) return;
    try {
      await _ensureConfigured();
      await _health.installHealthConnect();
    } catch (_) {}
  }

  /// Écrit une séance comme entraînement « Musculation » dans Health Connect.
  /// Ne fait rien si l'utilisateur n'a pas activé la synchro.
  static Future<bool> writeWorkout(
    LogSession session, {
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isSupportedPlatform) return false;
    try {
      if (!await isConnected()) return false;
      await _ensureConfigured();
      final granted =
          await _health.hasPermissions(_types, permissions: _perms) ?? false;
      if (!granted) return false;
      // Health Connect exige une fin strictement postérieure au début.
      final safeEnd =
          end.isAfter(start) ? end : start.add(const Duration(minutes: 1));
      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
        start: start,
        end: safeEnd,
        title: 'FitForge — Séance S${session.sessionType}',
      );
    } catch (_) {
      return false;
    }
  }
}
