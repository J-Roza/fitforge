import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synchronisation des données locales vers Firestore.
///
/// Chaque utilisateur possède un document `users/{uid}` qui contient un
/// miroir des données stockées en SharedPreferences (historique, planning,
/// séances perso, profil…). La sync montante est déclenchée automatiquement
/// après chaque séance ; le pull se fait à la connexion ou à la demande.
class CloudSyncService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // Mêmes clés que BackupService
  static const _stringKeys = [
    'ff_log_hist',
    'ff_log_plan',
    'ff_log_lw',
    'ff_log_lr',
    'ff_log_custom',
    'ff_log_sessions_config',
    'ff_timer_sound',
    'user_profile_v1',
  ];
  static const _intKeys = ['ff_log_timer'];
  static const _boolKeys = ['ff_log_seeded_v1'];

  static User? get currentUser => _auth.currentUser;
  static bool get isSignedIn => _auth.currentUser != null;
  static String? get email => _auth.currentUser?.email;
  static Stream<User?> authState() => _auth.authStateChanges();

  // ── Auth ──────────────────────────────────────────────────
  static Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<void> signOut() => _auth.signOut();

  static DocumentReference<Map<String, dynamic>> get _docRef =>
      _db.collection('users').doc(_auth.currentUser!.uid);

  // ── Push : local → cloud ──────────────────────────────────
  /// Envoie tout l'état local vers Firestore.
  static Future<void> pushAll() async {
    if (!isSignedIn) return;
    final p = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final k in _stringKeys) {
      final v = p.getString(k);
      if (v != null) data[k] = v;
    }
    for (final k in _intKeys) {
      final v = p.getInt(k);
      if (v != null) data[k] = v;
    }
    for (final k in _boolKeys) {
      final v = p.getBool(k);
      if (v != null) data[k] = v;
    }
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _docRef.set(data, SetOptions(merge: true));
  }

  /// Push silencieux (ne lève pas d'exception) — pour la sync auto.
  static Future<void> pushIfSignedIn() async {
    if (!isSignedIn) return;
    try {
      await pushAll();
    } catch (_) {
      // hors-ligne ou erreur réseau : on réessaiera au prochain changement
    }
  }

  // ── Pull : cloud → local ──────────────────────────────────
  /// Récupère l'état cloud et l'écrit en local. Retourne le nombre de
  /// séances restaurées, ou `null` si aucun document cloud n'existe.
  static Future<int?> pullAll() async {
    if (!isSignedIn) return null;
    final snap = await _docRef.get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;

    final p = await SharedPreferences.getInstance();
    for (final k in _stringKeys) {
      if (data[k] is String) await p.setString(k, data[k] as String);
    }
    for (final k in _intKeys) {
      final v = data[k];
      if (v is int) await p.setInt(k, v);
    }
    for (final k in _boolKeys) {
      if (data[k] is bool) await p.setBool(k, data[k] as bool);
    }

    final raw = data['ff_log_hist'];
    if (raw is String) {
      try {
        return (jsonDecode(raw) as List).length;
      } catch (_) {}
    }
    return 0;
  }

  /// Nombre de séances présentes dans le cloud (pour décider push vs pull).
  /// Retourne `null` si aucun document cloud.
  static Future<int?> cloudSessionCount() async {
    if (!isSignedIn) return null;
    final snap = await _docRef.get();
    if (!snap.exists) return null;
    final raw = snap.data()?['ff_log_hist'];
    if (raw is String) {
      try {
        return (jsonDecode(raw) as List).length;
      } catch (_) {}
    }
    return 0;
  }
}
