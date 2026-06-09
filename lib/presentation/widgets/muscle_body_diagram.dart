import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/exercise.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MuscleBodyDiagram  —  style anatomique : corps chair + muscles en rouge
// ─────────────────────────────────────────────────────────────────────────────

class MuscleBodyDiagram extends StatelessWidget {
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;

  const MuscleBodyDiagram({
    super.key,
    required this.primaryMuscle,
    required this.secondaryMuscles,
  });

  String _color(MuscleGroup m) {
    if (m == primaryMuscle) return '#E53935';
    if (secondaryMuscles.contains(m)) return '#FF7043';
    return '#9E5E48'; // muscle inactif — couleur chair sombre
  }

  String _opacity(MuscleGroup m) {
    if (m == primaryMuscle) return '0.92';
    if (secondaryMuscles.contains(m)) return '0.80';
    return '0.55';
  }

  @override
  Widget build(BuildContext context) {
    final c = {for (var m in MuscleGroup.values) m: _color(m)};
    final o = {for (var m in MuscleGroup.values) m: _opacity(m)};

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2440)),
      ),
      child: Row(
        children: [
          Expanded(child: _BodyView(svg: _frontSvg(c, o), label: 'AVANT')),
          Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFF2A2440)),
          Expanded(child: _BodyView(svg: _backSvg(c, o), label: 'ARRIÈRE')),
        ],
      ),
    );
  }

  // ── SVG AVANT ──────────────────────────────────────────────────────────────
  String _frontSvg(Map<MuscleGroup, String> c, Map<MuscleGroup, String> o) => '''
<svg viewBox="0 0 100 230" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="headGrad" cx="50%" cy="45%" r="50%">
      <stop offset="0%" stop-color="#C07858"/>
      <stop offset="100%" stop-color="#8A4A2E"/>
    </radialGradient>
    <linearGradient id="torsoGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#7A3A22"/>
      <stop offset="40%" stop-color="#9E5840"/>
      <stop offset="60%" stop-color="#9E5840"/>
      <stop offset="100%" stop-color="#7A3A22"/>
    </linearGradient>
  </defs>

  <!-- ── TÊTE ── -->
  <ellipse cx="50" cy="12" rx="11" ry="13" fill="url(#headGrad)" stroke="#5A2A14" stroke-width="0.5"/>
  <!-- oreilles -->
  <ellipse cx="39" cy="13" rx="2.5" ry="4" fill="#8A4A2E" stroke="#5A2A14" stroke-width="0.4"/>
  <ellipse cx="61" cy="13" rx="2.5" ry="4" fill="#8A4A2E" stroke="#5A2A14" stroke-width="0.4"/>
  <!-- traits visage -->
  <path d="M 46 10 Q 50 9 54 10" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.6"/>
  <line x1="50" y1="16" x2="50" y2="19" stroke="#5A2A14" stroke-width="0.4" opacity="0.5"/>

  <!-- ── COU ── -->
  <path d="M 45 23 Q 50 21 55 23 L 55 33 Q 50 31 45 33 Z"
        fill="#9E5840" stroke="#5A2A14" stroke-width="0.5"/>
  <!-- sterno-cléido -->
  <line x1="48" y1="24" x2="44" y2="33" stroke="#7A3A22" stroke-width="0.6" opacity="0.7"/>
  <line x1="52" y1="24" x2="56" y2="33" stroke="#7A3A22" stroke-width="0.6" opacity="0.7"/>

  <!-- ── CLAVICULES ── -->
  <path d="M 44 32 Q 38 30 24 36" fill="none" stroke="#C89070" stroke-width="1.0" opacity="0.7"/>
  <path d="M 56 32 Q 62 30 76 36" fill="none" stroke="#C89070" stroke-width="1.0" opacity="0.7"/>

  <!-- ── ÉPAULES (deltoïde antérieur) ── -->
  <path d="M 22 38 Q 14 36 10 44 Q 8 52 12 60 Q 16 66 22 64 Q 26 60 26 52 Z"
        fill="${c[MuscleGroup.shoulders]}" opacity="${o[MuscleGroup.shoulders]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 78 38 Q 86 36 90 44 Q 92 52 88 60 Q 84 66 78 64 Q 74 60 74 52 Z"
        fill="${c[MuscleGroup.shoulders]}" opacity="${o[MuscleGroup.shoulders]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <!-- fibres deltoïdes -->
  <path d="M 14 42 Q 18 54 22 60" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 86 42 Q 82 54 78 60" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── PECTORAUX ── -->
  <path d="M 26 34 Q 26 32 48 32 Q 50 46 48 66 L 36 72 Q 24 64 22 52 Q 22 38 26 34 Z"
        fill="${c[MuscleGroup.chest]}" opacity="${o[MuscleGroup.chest]}"
        stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 74 34 Q 74 32 52 32 Q 50 46 52 66 L 64 72 Q 76 64 78 52 Q 78 38 74 34 Z"
        fill="${c[MuscleGroup.chest]}" opacity="${o[MuscleGroup.chest]}"
        stroke="#5A2A14" stroke-width="0.7"/>
  <!-- séparation sternum pecs -->
  <line x1="50" y1="32" x2="50" y2="70" stroke="#5A2A14" stroke-width="0.6" opacity="0.7"/>
  <!-- fibres pecs -->
  <path d="M 28 38 Q 38 52 48 64" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 72 38 Q 62 52 52 64" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 26 46 Q 36 58 46 68" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.35"/>
  <path d="M 74 46 Q 64 58 54 68" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.35"/>

  <!-- ── BICEPS ── -->
  <path d="M 10 62 Q 8 68 8 78 Q 8 92 10 98 Q 14 104 18 100 Q 22 94 22 80 Q 22 68 20 62 Z"
        fill="${c[MuscleGroup.biceps]}" opacity="${o[MuscleGroup.biceps]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 90 62 Q 92 68 92 78 Q 92 92 90 98 Q 86 104 82 100 Q 78 94 78 80 Q 78 68 80 62 Z"
        fill="${c[MuscleGroup.biceps]}" opacity="${o[MuscleGroup.biceps]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <!-- séparation biceps/brachial -->
  <path d="M 11 70 Q 15 82 11 96" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 89 70 Q 85 82 89 96" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>

  <!-- ── TRICEPS (légèrement visibles côté) ── -->
  <path d="M 10 62 Q 8 68 8 78 Q 8 92 10 98 Q 14 104 18 100 Q 22 94 22 80 Q 22 68 20 62 Z"
        fill="${c[MuscleGroup.triceps]}" opacity="0.2" stroke="none"/>
  <path d="M 90 62 Q 92 68 92 78 Q 92 92 90 98 Q 86 104 82 100 Q 78 94 78 80 Q 78 68 80 62 Z"
        fill="${c[MuscleGroup.triceps]}" opacity="0.2" stroke="none"/>

  <!-- ── AVANT-BRAS ── -->
  <path d="M 8 100 Q 6 108 6 118 Q 6 130 8 136 L 18 136 L 20 128 Q 22 114 20 100 Z"
        fill="#7A3A22" opacity="0.75" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 92 100 Q 94 108 94 118 Q 94 130 92 136 L 82 136 L 80 128 Q 78 114 80 100 Z"
        fill="#7A3A22" opacity="0.75" stroke="#5A2A14" stroke-width="0.5"/>
  <!-- tendons poignet -->
  <path d="M 8 128 Q 10 132 12 136" fill="none" stroke="#C89070" stroke-width="0.5" opacity="0.6"/>
  <path d="M 92 128 Q 90 132 88 136" fill="none" stroke="#C89070" stroke-width="0.5" opacity="0.6"/>

  <!-- ── SERRATUS ANTERIOR ── -->
  <path d="M 22 64 Q 24 68 28 72 Q 28 76 26 80 Q 24 76 22 72 Z"
        fill="#8A4030" opacity="0.7" stroke="#5A2A14" stroke-width="0.4"/>
  <path d="M 78 64 Q 76 68 72 72 Q 72 76 74 80 Q 76 76 78 72 Z"
        fill="#8A4030" opacity="0.7" stroke="#5A2A14" stroke-width="0.4"/>
  <line x1="22" y1="70" x2="28" y2="74" stroke="#5A2A14" stroke-width="0.4" opacity="0.5"/>
  <line x1="78" y1="70" x2="72" y2="74" stroke="#5A2A14" stroke-width="0.4" opacity="0.5"/>

  <!-- ── GRANDS DROITS (abdominaux) ── -->
  <path d="M 36 70 Q 36 68 44 68 L 44 116 Q 44 118 36 118 Z"
        fill="${c[MuscleGroup.core]}" opacity="${o[MuscleGroup.core]}"
        stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 64 70 Q 64 68 56 68 L 56 116 Q 56 118 64 118 Z"
        fill="${c[MuscleGroup.core]}" opacity="${o[MuscleGroup.core]}"
        stroke="#5A2A14" stroke-width="0.5"/>
  <!-- grille abdominale -->
  <line x1="36" y1="82" x2="64" y2="82" stroke="#5A2A14" stroke-width="0.7" opacity="0.8"/>
  <line x1="36" y1="94" x2="64" y2="94" stroke="#5A2A14" stroke-width="0.7" opacity="0.8"/>
  <line x1="36" y1="106" x2="64" y2="106" stroke="#5A2A14" stroke-width="0.7" opacity="0.8"/>
  <line x1="50" y1="68" x2="50" y2="118" stroke="#5A2A14" stroke-width="0.7" opacity="0.8"/>

  <!-- ── OBLIQUES ── -->
  <path d="M 22 74 Q 22 80 24 92 Q 26 102 28 112 Q 34 118 36 118 L 36 70 Q 30 70 22 74 Z"
        fill="${c[MuscleGroup.core]}" opacity="0.5" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 78 74 Q 78 80 76 92 Q 74 102 72 112 Q 66 118 64 118 L 64 70 Q 70 70 78 74 Z"
        fill="${c[MuscleGroup.core]}" opacity="0.5" stroke="#5A2A14" stroke-width="0.5"/>
  <!-- fibres obliques diagonales -->
  <path d="M 24 80 L 34 100" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 25 90 L 35 110" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 76 80 L 66 100" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 75 90 L 65 110" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>

  <!-- ── CONTOUR TORSE ── -->
  <path d="M 22 38 Q 22 32 26 30 Q 38 26 50 26 Q 62 26 74 30 Q 78 32 78 38
           L 82 78 Q 80 90 78 100 L 76 118 L 24 118 L 22 100 Q 20 90 18 78 Z"
        fill="none" stroke="#5A2A14" stroke-width="0.8"/>

  <!-- ── HANCHES / FLÉCHISSEURS ── -->
  <path d="M 24 118 Q 24 126 26 132 Q 30 138 38 138 L 44 120 Z"
        fill="${c[MuscleGroup.glutes]}" opacity="0.45" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 76 118 Q 76 126 74 132 Q 70 138 62 138 L 56 120 Z"
        fill="${c[MuscleGroup.glutes]}" opacity="0.45" stroke="#5A2A14" stroke-width="0.5"/>

  <!-- ── QUADRICEPS ── -->
  <!-- Rectus femoris (central) gauche -->
  <path d="M 34 138 Q 30 148 29 168 Q 28 180 30 188 L 38 188 Q 40 178 40 164 Q 40 148 38 138 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <!-- Vastus lateralis gauche -->
  <path d="M 25 140 Q 22 152 21 170 Q 20 182 22 190 L 30 190 Q 28 180 29 168 Q 30 150 34 138 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}" stroke="#5A2A14" stroke-width="0.5"/>
  <!-- Vastus medialis gauche (teardrop) -->
  <path d="M 38 138 Q 42 152 42 168 Q 42 178 40 188 L 44 188 Q 46 178 46 162 Q 45 148 40 138 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}" stroke="#5A2A14" stroke-width="0.5"/>
  <!-- Séparations quadri gauche -->
  <path d="M 34 140 Q 32 160 30 188" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.6"/>
  <path d="M 38 140 Q 40 162 40 188" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.6"/>
  <!-- lignes fibres quads -->
  <path d="M 24 150 Q 32 155 40 150" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 24 162 Q 32 168 40 162" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 24 174 Q 32 180 40 174" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- Quadriceps droit (miroir) -->
  <path d="M 66 138 Q 70 148 71 168 Q 72 180 70 188 L 62 188 Q 60 178 60 164 Q 60 148 62 138 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 75 140 Q 78 152 79 170 Q 80 182 78 190 L 70 190 Q 72 180 71 168 Q 70 150 66 138 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 62 138 Q 58 152 58 168 Q 58 178 60 188 L 56 188 Q 54 178 54 162 Q 55 148 60 138 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 66 140 Q 68 160 70 188" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.6"/>
  <path d="M 62 140 Q 60 162 60 188" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.6"/>
  <path d="M 76 150 Q 68 155 60 150" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 76 162 Q 68 168 60 162" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 76 174 Q 68 180 60 174" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── GENOUX ── -->
  <ellipse cx="31" cy="192" rx="9" ry="5" fill="#A07050" opacity="0.7" stroke="#5A2A14" stroke-width="0.5"/>
  <ellipse cx="69" cy="192" rx="9" ry="5" fill="#A07050" opacity="0.7" stroke="#5A2A14" stroke-width="0.5"/>

  <!-- ── TIBIALIS ANTERIOR / MOLLETS AVANT ── -->
  <path d="M 24 196 Q 22 206 22 218 Q 22 226 24 230 L 32 230 Q 34 224 34 214 Q 34 204 32 196 Z"
        fill="${c[MuscleGroup.legs]}" opacity="0.6" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 76 196 Q 78 206 78 218 Q 78 226 76 230 L 68 230 Q 66 224 66 214 Q 66 204 68 196 Z"
        fill="${c[MuscleGroup.legs]}" opacity="0.6" stroke="#5A2A14" stroke-width="0.5"/>

  <!-- ── CONTOUR JAMBES ── -->
  <path d="M 24 138 Q 20 148 20 172 Q 19 184 21 192" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 44 138 Q 46 148 46 162 Q 46 176 44 190" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 76 138 Q 80 148 80 172 Q 81 184 79 192" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 56 138 Q 54 148 54 162 Q 54 176 56 190" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
</svg>
''';

  // ── SVG ARRIÈRE ────────────────────────────────────────────────────────────
  String _backSvg(Map<MuscleGroup, String> c, Map<MuscleGroup, String> o) => '''
<svg viewBox="0 0 100 230" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="headGradB" cx="50%" cy="45%" r="50%">
      <stop offset="0%" stop-color="#B07050"/>
      <stop offset="100%" stop-color="#7A3A20"/>
    </radialGradient>
  </defs>

  <!-- ── TÊTE (arrière) ── -->
  <ellipse cx="50" cy="12" rx="11" ry="13" fill="url(#headGradB)" stroke="#5A2A14" stroke-width="0.5"/>
  <ellipse cx="39" cy="13" rx="2.5" ry="4" fill="#8A4A2E" stroke="#5A2A14" stroke-width="0.4"/>
  <ellipse cx="61" cy="13" rx="2.5" ry="4" fill="#8A4A2E" stroke="#5A2A14" stroke-width="0.4"/>

  <!-- ── COU ── -->
  <path d="M 45 23 Q 50 21 55 23 L 56 33 Q 50 31 44 33 Z"
        fill="#9E5840" stroke="#5A2A14" stroke-width="0.5"/>

  <!-- ── TRAPÈZE ── -->
  <path d="M 44 26 Q 50 24 56 26 L 72 38 Q 78 50 74 64 L 60 72 L 50 76 L 40 72 L 26 64 Q 22 50 28 38 Z"
        fill="${c[MuscleGroup.back]}" opacity="${o[MuscleGroup.back]}"
        stroke="#5A2A14" stroke-width="0.7"/>
  <!-- fibres trapèze -->
  <path d="M 50 26 L 50 76" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 44 28 Q 42 48 40 70" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 56 28 Q 58 48 60 70" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 36 36 Q 40 50 42 68" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.35"/>
  <path d="M 64 36 Q 60 50 58 68" fill="none" stroke="#5A2A14" stroke-width="0.35" opacity="0.35"/>
  <path d="M 29 44 L 40 68" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.35"/>
  <path d="M 71 44 L 60 68" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.35"/>

  <!-- ── ÉPAULES (deltoïde postérieur) ── -->
  <path d="M 22 38 Q 14 36 10 44 Q 8 52 12 60 Q 16 66 22 64 Q 26 60 26 52 Z"
        fill="${c[MuscleGroup.shoulders]}" opacity="${o[MuscleGroup.shoulders]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 78 38 Q 86 36 90 44 Q 92 52 88 60 Q 84 66 78 64 Q 74 60 74 52 Z"
        fill="${c[MuscleGroup.shoulders]}" opacity="${o[MuscleGroup.shoulders]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 14 42 Q 18 54 22 60" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 86 42 Q 82 54 78 60" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── GRAND DORSAL gauche ── -->
  <path d="M 22 52 Q 24 50 36 58 Q 40 66 40 80 Q 40 96 38 112 L 24 108 Q 20 90 20 74 Q 18 62 22 52 Z"
        fill="${c[MuscleGroup.back]}" opacity="${o[MuscleGroup.back]}"
        stroke="#5A2A14" stroke-width="0.7"/>
  <!-- fibres dorsaux gauche -->
  <path d="M 24 56 Q 36 74 38 108" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 21 64 Q 32 80 36 108" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 20 74 Q 30 88 34 110" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.35"/>

  <!-- ── GRAND DORSAL droit ── -->
  <path d="M 78 52 Q 76 50 64 58 Q 60 66 60 80 Q 60 96 62 112 L 76 108 Q 80 90 80 74 Q 82 62 78 52 Z"
        fill="${c[MuscleGroup.back]}" opacity="${o[MuscleGroup.back]}"
        stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 76 56 Q 64 74 62 108" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 79 64 Q 68 80 64 108" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 80 74 Q 70 88 66 110" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.35"/>

  <!-- ── TRICEPS gauche ── -->
  <path d="M 10 60 Q 8 66 8 78 Q 8 92 10 100 Q 14 106 18 102 Q 22 96 22 80 Q 22 66 20 60 Z"
        fill="${c[MuscleGroup.triceps]}" opacity="${o[MuscleGroup.triceps]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <!-- chef long / latéral -->
  <path d="M 11 68 Q 15 82 11 98" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 14 64 Q 18 82 16 100" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── TRICEPS droit ── -->
  <path d="M 90 60 Q 92 66 92 78 Q 92 92 90 100 Q 86 106 82 102 Q 78 96 78 80 Q 78 66 80 60 Z"
        fill="${c[MuscleGroup.triceps]}" opacity="${o[MuscleGroup.triceps]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 89 68 Q 85 82 89 98" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 86 64 Q 82 82 84 100" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── AVANT-BRAS EXTENSEURS ── -->
  <path d="M 8 102 Q 6 110 6 120 Q 6 132 8 136 L 18 136 L 20 128 Q 22 114 20 102 Z"
        fill="#7A3A22" opacity="0.75" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 92 102 Q 94 110 94 120 Q 94 132 92 136 L 82 136 L 80 128 Q 78 114 80 102 Z"
        fill="#7A3A22" opacity="0.75" stroke="#5A2A14" stroke-width="0.5"/>

  <!-- ── ÉRECTEURS / COLONNE ── -->
  <path d="M 42 76 Q 42 72 45 72 L 46 116 Q 44 118 42 116 Z"
        fill="${c[MuscleGroup.back]}" opacity="0.65" stroke="#5A2A14" stroke-width="0.5"/>
  <path d="M 58 76 Q 58 72 55 72 L 54 116 Q 56 118 58 116 Z"
        fill="${c[MuscleGroup.back]}" opacity="0.65" stroke="#5A2A14" stroke-width="0.5"/>
  <!-- vertèbres -->
  <line x1="50" y1="30" x2="50" y2="116" stroke="#C89070" stroke-width="0.7" opacity="0.5"/>

  <!-- ── CONTOUR TORSE ── -->
  <path d="M 22 38 Q 22 32 26 30 Q 38 26 50 26 Q 62 26 74 30 Q 78 32 78 38
           L 82 78 Q 80 90 78 100 L 76 118 L 24 118 L 22 100 Q 20 90 18 78 Z"
        fill="none" stroke="#5A2A14" stroke-width="0.8"/>

  <!-- ── FESSIERS ── -->
  <path d="M 24 118 Q 22 128 22 140 Q 22 152 26 158 Q 34 164 44 158 Q 48 150 48 138 L 50 120 Z"
        fill="${c[MuscleGroup.glutes]}" opacity="${o[MuscleGroup.glutes]}"
        stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 76 118 Q 78 128 78 140 Q 78 152 74 158 Q 66 164 56 158 Q 52 150 52 138 L 50 120 Z"
        fill="${c[MuscleGroup.glutes]}" opacity="${o[MuscleGroup.glutes]}"
        stroke="#5A2A14" stroke-width="0.7"/>
  <!-- sillon fessier -->
  <path d="M 50 120 Q 50 138 50 158" fill="none" stroke="#5A2A14" stroke-width="0.6" opacity="0.6"/>
  <!-- fibres fessiers -->
  <path d="M 25 126 Q 36 134 46 126" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 24 136 Q 36 144 46 138" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 75 126 Q 64 134 54 126" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 76 136 Q 64 144 54 138" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── ISCHIO-JAMBIERS gauche ── -->
  <path d="M 24 160 Q 22 172 22 186 Q 22 196 24 202 L 32 202 L 36 196 Q 38 182 38 168 Q 38 158 36 154 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <!-- séparation ischio -->
  <path d="M 29 158 Q 28 178 29 200" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 33 158 Q 34 178 33 200" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <!-- fibres ischio -->
  <path d="M 23 168 Q 30 172 37 168" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 23 180 Q 30 184 37 180" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── ISCHIO-JAMBIERS droit ── -->
  <path d="M 76 160 Q 78 172 78 186 Q 78 196 76 202 L 68 202 L 64 196 Q 62 182 62 168 Q 62 158 64 154 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 71 158 Q 72 178 71 200" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 67 158 Q 66 178 67 200" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 77 168 Q 70 172 63 168" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 77 180 Q 70 184 63 180" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── GASTROCNÉMIENS (mollets) ── -->
  <path d="M 22 202 Q 20 212 20 222 Q 20 232 22 236 L 26 238 L 36 236 Q 38 230 38 220 Q 38 210 36 202 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <!-- séparation chef médial/latéral -->
  <path d="M 29 204 Q 28 218 28 236" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <!-- fibres mollet -->
  <path d="M 22 210 Q 28 214 36 210" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 21 220 Q 28 224 37 220" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <path d="M 78 202 Q 80 212 80 222 Q 80 232 78 236 L 74 238 L 64 236 Q 62 230 62 220 Q 62 210 64 202 Z"
        fill="${c[MuscleGroup.legs]}" opacity="${o[MuscleGroup.legs]}"
        stroke="#5A2A14" stroke-width="0.6"/>
  <path d="M 71 204 Q 72 218 72 236" fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5"/>
  <path d="M 78 210 Q 72 214 64 210" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>
  <path d="M 79 220 Q 72 224 63 220" fill="none" stroke="#5A2A14" stroke-width="0.4" opacity="0.4"/>

  <!-- ── CONTOUR JAMBES ── -->
  <path d="M 24 158 Q 20 172 20 190 Q 20 200 22 202" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 46 152 Q 48 162 48 178 Q 48 192 44 202" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 76 158 Q 80 172 80 190 Q 80 200 78 202" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
  <path d="M 54 152 Q 52 162 52 178 Q 52 192 56 202" fill="none" stroke="#5A2A14" stroke-width="0.7"/>
</svg>
''';
}

// ─────────────────────────────────────────────────────────────────────────────
class _BodyView extends StatelessWidget {
  final String svg;
  final String label;
  const _BodyView({required this.svg, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF6B6880),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
              child: SvgPicture.string(svg, fit: BoxFit.contain),
            ),
          ),
        ],
      );
}
