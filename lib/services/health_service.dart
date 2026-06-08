// Health Connect integration - requires health package compatible with your Gradle version
// To enable: add compatible health package to pubspec.yaml and uncomment implementation
import '../data/models/log_models.dart';

class HealthService {
  static Future<bool> writeWorkout(LogSession session) async {
    // TODO: implement with health package when Gradle compatibility is resolved
    return false;
  }
}