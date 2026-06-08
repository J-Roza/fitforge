import 'package:health/health.dart';
import '../data/models/log_models.dart';

class HealthService {
  static final _health = Health();

  static Future<bool> requestPermissions() async {
    await _health.configure(useHealthConnectIfAvailable: true);
    final types = [HealthDataType.WORKOUT];
    return _health.requestAuthorization(types,
        permissions: [HealthDataAccess.READ_WRITE]);
  }

  static Future<bool> writeWorkout(LogSession session) async {
    try {
      final granted = await requestPermissions();
      if (!granted) return false;

      // Write exercise session to Health Connect
      // Zepp Health reads workouts from Health Connect
      final start = session.date;
      final end = session.date.add(const Duration(minutes: 60)); // estimate

      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
        start: start,
        end: end,
        totalEnergyBurned: 300, // estimate kcal
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
    } catch (e) {
      return false;
    }
  }
}
