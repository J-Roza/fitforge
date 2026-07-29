// Configuration Firebase pour la plateforme web.
//
// Sur Android, Firebase lit android/app/google-services.json (config native).
// Sur le web, il n'existe pas de fichier natif : il faut fournir ces options
// explicitement à Firebase.initializeApp().
//
// ⚠️ Ces valeurs (clé API, projectId…) ne sont PAS secrètes : elles sont de
// toute façon publiques dans le bundle JavaScript servi sur le web. La
// protection des données repose sur les règles de sécurité Firestore
// (chaque utilisateur n'accède qu'à son document users/{uid}).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  // Pas d'app « web » enregistrée dans la console Firebase : on réutilise
  // l'appId Android, ce qui est suffisant pour Auth (email/mot de passe) et
  // Firestore (basés sur apiKey + projectId).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBqW7FVbISdhS-B_RAo3zFE0M829sudMXU',
    appId: '1:144522140893:android:bd8f609ead13199f4acf34',
    messagingSenderId: '144522140893',
    projectId: 'fitforge-1e66d',
    authDomain: 'fitforge-1e66d.firebaseapp.com',
    storageBucket: 'fitforge-1e66d.firebasestorage.app',
  );
}
