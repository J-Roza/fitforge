import '../data/models/log_models.dart';

/// Stub web : Health Connect n'existe pas sur le web. Toutes les opérations
/// sont des no-op afin que l'app compile et se comporte proprement.
class HealthService {
  HealthService._();

  static bool get isSupportedPlatform => false;

  static Future<bool> isAvailable() async => false;

  static Future<bool> isConnected() async => false;

  static Future<bool> connect() async => false;

  static Future<void> disconnect() async {}

  static Future<void> promptInstall() async {}

  static Future<bool> writeWorkout(
    LogSession session, {
    required DateTime start,
    required DateTime end,
  }) async =>
      false;
}
