# Installer FitForge sur Android

## Étape 1 — Installer Flutter SDK

1. Télécharge Flutter : https://docs.flutter.dev/get-started/install/windows
2. Extrais dans `C:\flutter` (chemin recommandé, sans espaces)
3. Ajoute `C:\flutter\bin` dans les variables d'environnement (PATH)
4. Vérifie l'installation : ouvre un terminal et tape `flutter doctor`

## Étape 2 — Installer Android Studio (ou juste les outils SDK)

### Option A — Android Studio complet (recommandé)
1. Télécharge : https://developer.android.com/studio
2. Installe avec les composants par défaut (SDK + émulateur)
3. Lance `flutter doctor` → accepte les licences Android si demandé :
   ```
   flutter doctor --android-licenses
   ```

### Option B — Juste les outils en ligne de commande
1. Télécharge "Command line tools only" sur https://developer.android.com/studio#downloads
2. Extrais dans `C:\Android\cmdline-tools\latest`
3. Configure la variable d'environnement `ANDROID_HOME=C:\Android`

## Étape 3 — Tester sur ton téléphone Android

### Activer le mode développeur sur ton téléphone
1. Paramètres → À propos du téléphone
2. Appuie **7 fois** sur "Numéro de build"
3. Retourne dans Paramètres → Options pour les développeurs
4. Active **Débogage USB**

### Connecter et installer
```bash
cd "D:\Mes documents\Claude Projet\fitforge"

# Vérifier que le téléphone est détecté
flutter devices

# Installer et lancer directement sur le téléphone
flutter run

# OU construire l'APK et l'envoyer manuellement
flutter build apk --release
```

L'APK sera dans :
```
build\app\outputs\flutter-apk\app-release.apk
```

Tu peux l'envoyer par câble USB, email ou AirDrop sur ton téléphone et l'installer.

## Étape 4 — Build rapide (double-clic)

Lance simplement `build_apk.bat` dans le dossier du projet.

## Résolution de problèmes

| Erreur | Solution |
|--------|----------|
| `flutter: command not found` | Ajouter `C:\flutter\bin` au PATH |
| `Android SDK not found` | Lancer `flutter doctor` et suivre les instructions |
| `License not accepted` | `flutter doctor --android-licenses` |
| `No devices found` | Vérifier Débogage USB activé + téléphone déverrouillé |
| Build Gradle timeout | Relancer, la première fois télécharge Gradle (~200 MB) |

## Commandes utiles

```bash
flutter doctor          # Diagnostic complet
flutter devices         # Liste tes appareils connectés
flutter run             # Lance sur l'appareil connecté
flutter run --release   # Mode release (plus rapide)
flutter build apk       # Build APK debug
flutter build apk --release   # Build APK release (optimisé)
flutter build apk --split-per-abi  # APK plus léger par architecture
```
