import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/exercise.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MuscleBodyDiagram  —  SVG anatomique fourni, couleurs substituées par muscle
// ─────────────────────────────────────────────────────────────────────────────

class MuscleBodyDiagram extends StatelessWidget {
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;

  const MuscleBodyDiagram({
    super.key,
    required this.primaryMuscle,
    required this.secondaryMuscles,
  });

  // Correspondance MuscleGroup → id SVG
  static const _svgId = {
    MuscleGroup.chest:     'chest',
    MuscleGroup.back:      'back',
    MuscleGroup.shoulders: 'shoulders',
    MuscleGroup.biceps:    'biceps',
    MuscleGroup.triceps:   'triceps',
    MuscleGroup.core:      'core',
    MuscleGroup.legs:      'legs',
    MuscleGroup.glutes:    'glutes',
  };

  static const _inactive  = '#9E5840';
  static const _primary   = '#E53935';
  static const _secondary = '#FF7043';

  String _buildSvg() {
    var svg = _kBodySvg;

    // Muscle primaire → rouge
    final pid = _svgId[primaryMuscle];
    if (pid != null) {
      svg = svg.replaceAll(
        'id="$pid" fill="$_inactive"',
        'id="$pid" fill="$_primary"',
      );
    }

    // Muscles secondaires → orange
    for (final m in secondaryMuscles) {
      if (m == primaryMuscle) continue;
      final sid = _svgId[m];
      if (sid != null) {
        svg = svg.replaceAll(
          'id="$sid" fill="$_inactive"',
          'id="$sid" fill="$_secondary"',
        );
      }
    }

    return svg;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Labels AVANT / ARRIÈRE
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text('AVANT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF6B6880),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ),
              Container(width: 1, height: 12, color: const Color(0xFF2A2440)),
              const Expanded(
                child: Text('ARRIÈRE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF6B6880),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ),
            ],
          ),
        ),

        // Diagramme SVG — AspectRatio 200:280 pour éviter l'hauteur infinie
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0D1C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2440)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 200 / 280,
              child: SvgPicture.string(
                _buildSvg(),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Légende
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFFE53935), label: 'Primaire'),
              const SizedBox(width: 20),
              if (secondaryMuscles.isNotEmpty)
                _LegendDot(color: const Color(0xFFFF7043), label: 'Secondaire'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SVG source (200×280, front x=50 / back x=150, IDs par groupe musculaire)
// ─────────────────────────────────────────────────────────────────────────────
const _kBodySvg = '''
<svg viewBox="0 0 200 280" xmlns="http://www.w3.org/2000/svg" font-family="sans-serif">
  <rect x="0" y="0" width="200" height="280" fill="#0F0D1C"/>

  <!-- séparateur central -->
  <line x1="100" y1="8" x2="100" y2="272" stroke="#2A2440" stroke-width="0.8"/>

  <!-- ============================ FRONT VIEW (centerline x=50) ============================ -->
  <g stroke="#5A2A14" stroke-linejoin="round" stroke-linecap="round">

    <!-- ARMS (skin) -->
    <g fill="#C07858" stroke-width="1">
      <path d="M71 55 C76 55 79 61 80 68 C81 78 81 88 80 97 C79 110 78 122 77 133 C77 140 77 145 76 149 C74 151 72 151 71 149 C70 145 70 140 70 133 C70 122 70 110 70 97 C70 86 70 74 70 66 C70 61 70 58 71 55 Z"/>
      <path d="M29 55 C24 55 21 61 20 68 C19 78 19 88 20 97 C21 110 22 122 23 133 C23 140 23 145 24 149 C26 151 28 151 29 149 C30 145 30 140 30 133 C30 122 30 110 30 97 C30 86 30 74 30 66 C30 61 30 58 29 55 Z"/>
    </g>

    <!-- LEGS (skin) -->
    <g fill="#C07858" stroke-width="1">
      <path d="M67 116 C69 132 68 156 65 178 C64 183 63 185 62 190 C61 202 60 216 58 233 C57 238 57 241 57 244 C58 248 60 251 59 256 C58 260 55 261 53 260 C51 259 50 256 50 252 C50 248 51 246 51 243 C51 224 51 206 51 190 C51 170 51 150 51 132 C51 128 51 126 50 126 Z"/>
      <path d="M33 116 C31 132 32 156 35 178 C36 183 37 185 38 190 C39 202 40 216 42 233 C43 238 43 241 43 244 C42 248 40 251 41 256 C42 260 45 261 47 260 C49 259 50 256 50 252 C50 248 49 246 49 243 C49 224 49 206 49 190 C49 170 49 150 49 132 C49 128 49 126 50 126 Z"/>
    </g>

    <!-- TORSO + HEAD + NECK (skin) -->
    <path fill="#C07858" stroke-width="1.1" d="M50 16
      C56 16 59 21 59 27 C59 33 57 37 55 39 C54 41 54 43 53 45 C53 47 54 48 56 49
      C62 50 68 52 73 56 C74 58 73 62 71 66
      C69 78 64 92 62 104 C62 110 64 113 67 116
      C64 122 57 127 50 127
      C43 127 36 122 33 116 C36 113 38 110 38 104
      C36 92 31 78 29 66 C27 62 26 58 27 56
      C32 52 38 50 44 49 C46 48 47 47 47 45 C47 43 46 41 45 39
      C43 37 41 33 41 27 C41 21 44 16 50 16 Z"/>

    <!-- face -->
    <g fill="none" stroke="#5A2A14" stroke-width="0.7" opacity="0.55">
      <path d="M45 26 C46 25 48 25 49 26"/>
      <path d="M51 26 C52 25 54 25 55 26"/>
      <path d="M50 28 L50 33 M48 33 C49 34 51 34 52 33"/>
      <path d="M47 37 C49 38 51 38 53 37"/>
    </g>

  </g>

  <!-- ============================ BACK VIEW (centerline x=150) ============================ -->
  <g stroke="#5A2A14" stroke-linejoin="round" stroke-linecap="round">

    <g fill="#C07858" stroke-width="1">
      <path d="M171 55 C176 55 179 61 180 68 C181 78 181 88 180 97 C179 110 178 122 177 133 C177 140 177 145 176 149 C174 151 172 151 171 149 C170 145 170 140 170 133 C170 122 170 110 170 97 C170 86 170 74 170 66 C170 61 170 58 171 55 Z"/>
      <path d="M129 55 C124 55 121 61 120 68 C119 78 119 88 120 97 C121 110 122 122 123 133 C123 140 123 145 124 149 C126 151 128 151 129 149 C130 145 130 140 130 133 C130 122 130 110 130 97 C130 86 130 74 130 66 C130 61 130 58 129 55 Z"/>
    </g>

    <g fill="#C07858" stroke-width="1">
      <path d="M167 116 C169 132 168 156 165 178 C164 183 163 185 162 190 C161 202 160 216 158 233 C157 238 157 241 157 244 C158 248 160 251 159 256 C158 260 155 261 153 260 C151 259 150 256 150 252 C150 248 151 246 151 243 C151 224 151 206 151 190 C151 170 151 150 151 132 C151 128 151 126 150 126 Z"/>
      <path d="M133 116 C131 132 132 156 135 178 C136 183 137 185 138 190 C139 202 140 216 142 233 C143 238 143 241 143 244 C142 248 140 251 141 256 C142 260 145 261 147 260 C149 259 150 256 150 252 C150 248 149 246 149 243 C149 224 149 206 149 190 C149 170 149 150 149 132 C149 128 149 126 150 126 Z"/>
    </g>

    <path fill="#C07858" stroke-width="1.1" d="M150 16
      C156 16 159 21 159 27 C159 33 157 37 155 39 C154 41 154 43 153 45 C153 47 154 48 156 49
      C162 50 168 52 173 56 C174 58 173 62 171 66
      C169 78 164 92 162 104 C162 110 164 113 167 116
      C164 122 157 127 150 127
      C143 127 136 122 133 116 C136 113 138 110 138 104
      C136 92 131 78 129 66 C127 62 126 58 127 56
      C132 52 138 50 144 49 C146 48 147 47 147 45 C147 43 146 41 145 39
      C143 37 141 33 141 27 C141 21 144 16 150 16 Z"/>
  </g>

  <!-- ================= MUSCLE GROUPS ================= -->
  <g stroke="#5A2A14" stroke-linejoin="round" stroke-width="0.7">

    <g id="shoulders" fill="#9E5840">
      <path d="M64 51 C70 51 74 55 74 61 C74 66 72 69 68 69 C65 67 64 60 64 53 Z"/>
      <path d="M36 51 C30 51 26 55 26 61 C26 66 28 69 32 69 C35 67 36 60 36 53 Z"/>
      <path d="M164 51 C170 51 174 55 174 61 C174 66 172 69 168 69 C165 67 164 60 164 53 Z"/>
      <path d="M136 51 C130 51 126 55 126 61 C126 66 128 69 132 69 C135 67 136 60 136 53 Z"/>
      <g fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5">
        <path d="M66 56 C69 56 71 58 72 62"/><path d="M34 56 C31 56 29 58 28 62"/>
        <path d="M166 56 C169 56 171 58 172 62"/><path d="M134 56 C131 56 129 58 128 62"/>
      </g>
    </g>

    <g id="chest" fill="#9E5840">
      <path d="M50 51 C58 51 64 53 68 57 C69 64 66 71 60 75 C55 77 51 76 50 73 Z"/>
      <path d="M50 51 C42 51 36 53 32 57 C31 64 34 71 40 75 C45 77 49 76 50 73 Z"/>
      <g fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5">
        <path d="M50 54 C56 55 62 57 66 60"/><path d="M50 54 C44 55 38 57 34 60"/>
      </g>
    </g>

    <g id="back" fill="#9E5840">
      <path d="M150 47 C158 48 166 52 173 57 C166 62 158 64 150 65 C142 64 134 62 127 57 C134 52 142 48 150 47 Z"/>
      <path d="M150 64 L158 86 L150 97 L142 86 Z"/>
      <path d="M172 60 C173 74 168 92 160 104 C156 101 154 93 154 84 C154 74 162 64 172 60 Z"/>
      <path d="M128 60 C127 74 132 92 140 104 C144 101 146 93 146 84 C146 74 138 64 128 60 Z"/>
      <g fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5">
        <path d="M150 49 L150 96"/>
        <path d="M168 64 C162 74 159 88 157 100"/><path d="M132 64 C138 74 141 88 143 100"/>
      </g>
    </g>

    <g id="core" fill="#9E5840">
      <path d="M58 78 C62 82 63 94 61 104 C59 102 56 96 55 88 C55 84 56 80 58 78 Z"/>
      <path d="M42 78 C38 82 37 94 39 104 C41 102 44 96 45 88 C45 84 44 80 42 78 Z"/>
      <path d="M50 77 C54 77 56 79 56 84 C56 96 55 106 50 112 C45 106 44 96 44 84 C44 79 46 77 50 77 Z"/>
      <g fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.55">
        <path d="M50 78 L50 110"/>
        <path d="M44 85 L56 85"/><path d="M44 93 L56 93"/><path d="M45 101 L55 101"/>
      </g>
    </g>

    <g id="biceps" fill="#9E5840">
      <path d="M72 67 C76 66 79 68 79 74 C80 82 79 90 77 95 C74 96 72 94 72 90 C71 82 71 74 72 67 Z"/>
      <path d="M28 67 C24 66 21 68 21 74 C20 82 21 90 23 95 C26 96 28 94 28 90 C29 82 29 74 28 67 Z"/>
    </g>

    <g id="triceps" fill="#9E5840">
      <path d="M172 67 C176 66 179 68 179 74 C180 82 179 90 177 95 C174 96 172 94 172 90 C171 82 171 74 172 67 Z"/>
      <path d="M128 67 C124 66 121 68 121 74 C120 82 121 90 123 95 C126 96 128 94 128 90 C129 82 129 74 128 67 Z"/>
      <g fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5">
        <path d="M176 70 L176 93"/><path d="M124 70 L124 93"/>
      </g>
    </g>

    <g id="glutes" fill="#9E5840">
      <path d="M150 117 C158 117 165 121 166 130 C166 138 160 143 153 142 C150 139 150 128 150 117 Z"/>
      <path d="M150 117 C142 117 135 121 134 130 C134 138 140 143 147 142 C150 139 150 128 150 117 Z"/>
    </g>

    <g id="legs" fill="#9E5840">
      <path d="M56 126 C62 128 64 145 62 165 C61 174 59 179 56 181 C53 179 53 165 53 150 C53 140 53 130 56 126 Z"/>
      <path d="M44 126 C38 128 36 145 38 165 C39 174 41 179 44 181 C47 179 47 165 47 150 C47 140 47 130 44 126 Z"/>
      <path d="M156 128 C162 130 164 146 162 166 C161 174 159 179 156 181 C153 179 153 165 153 150 C153 142 153 132 156 128 Z"/>
      <path d="M144 128 C138 130 136 146 138 166 C139 174 141 179 144 181 C147 179 147 165 147 150 C147 142 147 132 144 128 Z"/>
      <path d="M159 191 C162 194 163 206 161 220 C160 228 158 232 157 233 C155 232 154 220 154 209 C154 200 156 194 159 191 Z"/>
      <path d="M141 191 C138 194 137 206 139 220 C140 228 142 232 143 233 C145 232 146 220 146 209 C146 200 144 194 141 191 Z"/>
      <g fill="none" stroke="#5A2A14" stroke-width="0.5" opacity="0.5">
        <path d="M58 130 C60 148 58 166 56 178"/><path d="M42 130 C40 148 42 166 44 178"/>
        <path d="M156 132 L156 178"/><path d="M144 132 L144 178"/>
      </g>
    </g>

  </g>
</svg>
''';
