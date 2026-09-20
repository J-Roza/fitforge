import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_profile.dart';
import '../services/cloud_sync_service.dart';

const _uuid = Uuid();

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  static const _key = 'user_profile_v1';

  UserProfileNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        state = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  /// Recharge le profil depuis les prefs SANS recréer le notifier (utilisé
  /// après une restauration cloud : évite de passer par null, ce qui ferait
  /// clignoter l'onboarding / réinitialiser la navigation).
  Future<void> reloadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      state = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (state != null) {
      await prefs.setString(_key, jsonEncode(state!.toJson()));
    } else {
      await prefs.remove(_key);
    }
    CloudSyncService.pushIfSignedIn();
  }

  void createProfile({
    required String name,
    int? age,
    double? weightKg,
    double? heightCm,
    Somatotype? somatotype,
    required FitnessGoal goal,
    required FitnessLevel level,
    required AvailableEquipment equipment,
    int workoutsPerWeek = 4,
  }) {
    state = UserProfile(
      id: _uuid.v4(),
      name: name,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      somatotype: somatotype,
      goal: goal,
      level: level,
      equipment: equipment,
      workoutsPerWeek: workoutsPerWeek,
    );
    _save();
  }

  void update(UserProfile profile) {
    state = profile;
    _save();
  }

  void updateMeasurements(Measurements measurements) {
    if (state == null) return;
    state = state!.copyWith(measurements: measurements);
    _save();
  }
}
