# FitForge — Application Musculation iOS & Android

## Stack
- **Flutter** (Dart) — cross-platform iOS + Android
- **Riverpod** — state management
- **GoRouter** — navigation
- **fl_chart** — graphiques de progression
- **flutter_animate** — animations fluides
- **Google Fonts (Inter)** — typographie

## Structure du projet
```
lib/
├── main.dart                          # Entry point
├── app.dart                           # Root widget + theme
├── core/theme/
│   ├── app_colors.dart                # Palette de couleurs
│   └── app_theme.dart                 # Material 3 dark theme
├── data/
│   ├── models/
│   │   ├── exercise.dart              # Modèle exercice + enums
│   │   ├── workout.dart               # Séance, sets, sessions
│   │   └── user_profile.dart          # Profil + morphotype
│   └── datasources/
│       └── exercises_data.dart        # +35 exercices complets
├── providers/
│   ├── exercise_provider.dart         # Filtres, favoris
│   ├── workout_provider.dart          # Templates, session active, historique
│   └── user_provider.dart             # Profil + générateur IA
├── navigation/
│   └── app_router.dart                # Routes + bottom nav shell
└── presentation/
    ├── screens/
    │   ├── onboarding/                # 4 pages d'onboarding
    │   ├── home/                      # Dashboard + stats hebdo
    │   ├── exercises/                 # Bibliothèque + détail exercice
    │   ├── workout/                   # Séances + session active avec timer
    │   ├── progress/                  # Graphiques + heatmap + historique
    │   └── profile/                   # Profil + mensurations + réglages
    └── widgets/
        └── exercise_card.dart         # Carte exercice réutilisable
```

## Exercices inclus (+35)
| Groupe | Exercices |
|--------|-----------|
| Pectoraux | Développé couché, incliné, décliné, écarté, croisé câbles, pompes, dips |
| Dos | Tractions, soulevé de terre, rowing barre, lat pulldown, rowing câble, dumbbell row, face pull |
| Épaules | Développé militaire, élévations latérales, Arnold press, élévations frontales |
| Biceps | Curl barre, marteau, pupitre, concentration |
| Triceps | Skull crusher, poulie, développé serré, extension au-dessus tête |
| Jambes | Squat, presse, fentes, leg extension, leg curl, RDL, hip thrust, mollets |
| Abdos | Planche, crunch, Russian twist, relevé de jambes, roue abdominale |
| Full Body | Épaulé-jeté, kettlebell swing, burpee |

## Générateur de programme IA
Adapte automatiquement le split selon :
- **3j/semaine** → Full Body (A/B/C)
- **4j/semaine** → Upper/Lower
- **5-6j/semaine** → Push/Pull/Legs

## Installation
```bash
# Prérequis: Flutter SDK 3.3+
flutter pub get
flutter run                    # Émulateur/device connecté
flutter run -d android         # Android
flutter run -d ios             # iOS (macOS requis)
flutter build apk              # Build Android
flutter build ios              # Build iOS
```

## Fonctionnalités
- Onboarding personnalisé (morphotype, objectif, équipement)
- Bibliothèque d'exercices avec filtres muscle/difficulté/recherche
- Détail exercice : technique, muscles travaillés, erreurs à éviter
- Séances prédéfinies (Push/Pull/Legs, Full Body, Force, Core)
- Session active : timer, log séries/poids/reps, repos automatique
- Historique et statistiques de progression
- Graphique de volume hebdomadaire + heatmap 28 jours
- Profil complet avec BMI, mensurations, programme adapté
