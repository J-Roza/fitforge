import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/exercise.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MuscleBodyDiagram — polygones anatomiques (source: react-body-highlighter,
//  MIT licence, giavinh79/react-body-highlighter & HichamELBSI)
//
//  viewBox "0 0 200 202"  |  front : x 0-100  |  back : x 100-200
// ─────────────────────────────────────────────────────────────────────────────

class MuscleBodyDiagram extends StatelessWidget {
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;

  const MuscleBodyDiagram({
    super.key,
    required this.primaryMuscle,
    required this.secondaryMuscles,
  });

  // Mapping MuscleGroup → liste d'IDs SVG (avant et/ou arrière)
  static const _svgIds = {
    MuscleGroup.chest:     ['chest-f'],
    MuscleGroup.back:      ['back-b'],
    MuscleGroup.shoulders: ['shoulders-f', 'shoulders-b'],
    MuscleGroup.biceps:    ['biceps-f'],
    MuscleGroup.triceps:   ['triceps-f', 'triceps-b'],
    MuscleGroup.core:      ['core-f'],
    MuscleGroup.legs:      ['legs-f', 'legs-b'],
    MuscleGroup.glutes:    ['glutes-b'],
  };

  static const _inactive  = '#9E5840';
  static const _primary   = '#E53935';
  static const _secondary = '#FF7043';

  String _buildSvg() {
    var svg = _kBodySvg;

    void paint(MuscleGroup m, String color) {
      for (final id in _svgIds[m] ?? <String>[]) {
        svg = svg.replaceAll(
          'id="$id" fill="$_inactive"',
          'id="$id" fill="$color"',
        );
      }
    }

    paint(primaryMuscle, _primary);
    for (final m in secondaryMuscles) {
      if (m != primaryMuscle) paint(m, _secondary);
    }
    return svg;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Labels
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text('AVANT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF6B6880), fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
              Container(width: 1, height: 12, color: const Color(0xFF2A2440)),
              const Expanded(
                child: Text('ARRIÈRE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF6B6880), fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),

        // SVG
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0D1C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2440)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 200 / 202,
              child: SvgPicture.string(_buildSvg(), fit: BoxFit.contain),
            ),
          ),
        ),

        // Légende
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(color: const Color(0xFFE53935), label: 'Primaire'),
              const SizedBox(width: 20),
              if (secondaryMuscles.isNotEmpty)
                _Dot(color: const Color(0xFFFF7043), label: 'Secondaire'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SVG — polygones de react-body-highlighter (MIT)
//  Front view : coordonnées originales (x: 0-100)
//  Back view  : x + 100 (x: 100-200)
//  Couleur par défaut : #9E5840 (muscle inactif)
//  Rouge #E53935 / Orange #FF7043 injectés par substitution de string
// ─────────────────────────────────────────────────────────────────────────────
const _kBodySvg = '''
<svg viewBox="0 0 200 202" xmlns="http://www.w3.org/2000/svg">
  <rect width="200" height="202" fill="#0F0D1C"/>
  <line x1="100" y1="2" x2="100" y2="200" stroke="#2A2440" stroke-width="0.6"/>

  <!-- ═══════════════════ SKIN BASE ═══════════════════ -->
  <g fill="#C07858" stroke="#8A4A2A" stroke-width="0.3">
    <!-- HEAD front -->
    <polygon points="42.45 2.86 40 11.84 42.04 19.59 46.12 23.27 49.80 25.31 54.69 22.45 57.55 19.18 59.18 10.20 57.14 2.45 49.80 0"/>
    <!-- HEAD back -->
    <polygon points="150.64 0 145.96 0.85 140.85 5.53 140.43 12.77 145.11 20 155.74 20 159.15 13.62 159.57 4.68 155.74 1.28"/>
    <!-- NECK front -->
    <polygon points="55.51 23.67 50.61 33.47 50.61 39.18 61.63 40 70.61 44.90 69.39 36.73 63.27 35.10 58.37 30.61"/>
    <polygon points="28.98 44.90 30.20 37.14 36.33 35.10 41.22 30.20 44.49 24.49 48.98 33.88 48.57 39.18 37.96 39.59"/>
    <!-- NECK back -->
    <polygon points="144.68 24.49 148.98 33.88 152.34 38.30 147.66 21.70 152.34 21.70 155.32 38.30 160.85 24.49"/>
    <!-- FOREARM front -->
    <polygon points="6.12 88.57 10.20 75.10 14.69 70.20 16.33 74.29 19.18 73.47 4.49 97.55 0 100" fill="#B06844"/>
    <polygon points="84.49 69.80 83.27 73.47 80 73.06 95.10 98.37 100 100.41 93.47 89.39 89.80 76.33" fill="#B06844"/>
    <polygon points="77.55 72.24 77.55 77.55 80.41 84.08 85.31 89.80 92.24 101.22 94.69 99.59" fill="#B06844"/>
    <polygon points="6.94 101.22 13.47 90.61 18.78 84.08 21.63 77.14 21.22 71.84 4.90 98.78" fill="#B06844"/>
    <!-- FOREARM back -->
    <polygon points="186.38 75.74 191.06 83.40 193.19 94.04 200 106.38 196.17 104.26 188.09 89.36 184.26 83.83" fill="#B06844"/>
    <polygon points="113.62 75.74 108.94 83.83 106.81 93.62 100 106.38 103.83 104.26 112.34 88.51 115.74 82.98" fill="#B06844"/>
    <polygon points="181.28 79.57 177.45 77.87 179.15 84.68 191.06 103.83 193.19 108.94 194.47 104.68" fill="#B06844"/>
    <polygon points="118.72 79.57 122.13 77.87 120.85 84.26 109.36 102.98 106.81 108.51 105.11 104.68" fill="#B06844"/>
    <!-- KNEES front -->
    <polygon points="33.88 140 34.69 143.27 35.51 147.35 36.33 151.02 35.10 156.73 29.80 156.73 27.35 152.65 27.35 147.35 30.20 144.08" fill="#A06040"/>
    <polygon points="65.71 140 72.24 147.76 72.24 152.24 69.80 157.14 64.90 156.73 62.86 151.02" fill="#A06040"/>
    <!-- KNEES back -->
    <polygon points="134.47 153.19 131.06 159.15 133.62 166.38 137.45 162.55" fill="#A06040"/>
    <polygon points="166.38 153.62 162.98 162.98 166.81 166.38 169.36 159.15" fill="#A06040"/>
  </g>

  <!-- ═══════════════════ MUSCLES AVANT ═══════════════════ -->

  <!-- CHEST -->
  <g id="chest-f" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <polygon points="51.84 41.63 51.02 55.10 57.96 57.96 67.76 55.51 70.61 47.35 62.04 41.63"/>
    <polygon points="29.80 46.53 31.43 55.51 40.82 57.96 48.16 55.10 47.76 42.04 37.55 42.04"/>
  </g>

  <!-- OBLIQUES + ABS → core -->
  <g id="core-f" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <!-- obliques -->
    <polygon points="68.57 63.27 67.35 57.14 58.78 59.59 60 64.08 60.41 83.27 65.71 78.78 66.53 69.80"/>
    <polygon points="33.88 78.37 33.06 71.84 31.02 63.27 32.24 57.14 40.82 59.18 39.18 63.27 39.18 83.67"/>
    <!-- rectus abdominis -->
    <polygon points="56.33 59.18 57.96 64.08 58.37 77.96 58.37 92.65 56.33 98.37 55.10 104.08 51.43 107.76 51.02 84.49 50.61 67.35 51.02 57.14"/>
    <polygon points="43.67 58.78 48.57 57.14 48.98 67.35 48.57 84.49 48.16 107.35 44.49 103.67 40.82 91.43 40.82 78.37 41.22 64.49"/>
  </g>

  <!-- BICEPS -->
  <g id="biceps-f" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <polygon points="16.73 68.16 17.96 71.43 22.86 66.12 28.98 53.88 27.76 49.39 20.41 55.92"/>
    <polygon points="71.43 49.39 70.20 54.69 76.33 66.12 81.63 71.84 82.86 68.98 78.78 55.51"/>
  </g>

  <!-- TRICEPS front (small) -->
  <g id="triceps-f" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <polygon points="69.39 55.51 69.39 61.63 75.92 72.65 77.55 70.20 75.51 67.35"/>
    <polygon points="22.45 69.39 29.80 55.51 29.80 60.82 22.86 73.06"/>
  </g>

  <!-- SHOULDERS front (front-deltoids) -->
  <g id="shoulders-f" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <polygon points="78.37 53.06 79.59 47.76 79.18 41.22 75.92 37.96 71.02 36.33 72.24 42.86 71.43 47.35"/>
    <polygon points="28.16 47.35 21.22 53.06 20 47.76 20.41 40.82 24.49 37.14 28.57 37.14 26.94 43.27"/>
  </g>

  <!-- QUADRICEPS + ABDUCTORS → legs front -->
  <g id="legs-f" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <!-- abductors -->
    <polygon points="52.65 110.20 54.29 124.90 60 110.20 62.04 100 64.90 94.29 60 92.65 56.73 104.49"/>
    <polygon points="47.76 110.61 44.90 125.31 42.04 115.92 40.41 113.06 39.59 107.35 37.96 102.45 34.69 93.88 39.59 92.24 41.63 99.18 43.67 105.31"/>
    <!-- quadriceps - 6 polygons -->
    <polygon points="34.69 98.78 37.14 108.16 37.14 127.76 34.29 137.14 31.02 132.65 29.39 120 28.16 111.43 29.39 100.82 32.24 94.69"/>
    <polygon points="63.27 105.71 64.49 100 66.94 94.69 70.20 101.22 71.02 111.84 68.16 133.06 65.31 137.55 62.45 128.57 62.04 111.43"/>
    <polygon points="38.78 129.39 38.37 112.24 41.22 118.37 44.49 129.39 42.86 135.10 40 146.12 36.33 146.53 35.51 140"/>
    <polygon points="59.59 145.71 55.51 128.98 60.82 113.88 61.22 130.20 64.08 139.59 62.86 146.53"/>
    <polygon points="32.65 138.37 26.53 145.71 25.71 136.73 25.71 127.35 26.94 114.29 29.39 133.47"/>
    <polygon points="71.84 113.06 73.88 124.08 73.88 140.41 72.65 145.71 66.53 138.37 70.20 133.47"/>
    <!-- calves front (visible) -->
    <polygon points="71.43 160.41 73.47 153.47 76.73 161.22 79.59 167.76 78.37 187.76 79.59 195.51 74.69 195.51"/>
    <polygon points="24.90 194.69 27.76 164.90 28.16 160.41 26.12 154.29 24.90 157.55 22.45 161.63 20.82 167.76 22.04 188.16 20.82 195.51"/>
    <polygon points="72.65 195.10 69.80 159.18 65.31 158.37 64.08 162.45 64.08 165.31 65.71 177.14"/>
    <polygon points="35.51 158.37 35.92 162.45 35.92 166.94 35.10 172.24 35.10 176.73 32.24 182.04 30.61 187.35 26.94 194.69 27.35 187.76 28.16 180.41 28.57 175.51 28.98 169.80 29.80 164.08 30.20 158.78"/>
  </g>

  <!-- ═══════════════════ MUSCLES ARRIÈRE ═══════════════════ -->

  <!-- TRAPEZIUS + UPPER-BACK + LOWER-BACK → back -->
  <g id="back-b" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <!-- trapezius -->
    <polygon points="144.68 21.70 147.66 21.70 147.23 38.30 147.66 64.68 138.30 53.19 135.32 40.85 131.06 36.60 139.15 33.19 143.83 27.23"/>
    <polygon points="152.34 21.70 155.74 21.70 156.60 27.23 160.85 32.77 168.94 36.60 164.68 40.43 161.70 53.19 152.34 64.68 153.19 38.30"/>
    <!-- upper-back -->
    <polygon points="131.06 38.72 128.09 48.94 128.51 55.32 134.04 75.32 147.23 71.06 147.23 66.38 136.60 54.04 133.62 41.28"/>
    <polygon points="168.94 38.72 171.91 49.36 171.49 56.17 165.96 75.32 152.77 71.06 152.77 66.38 163.40 54.47 166.38 41.70"/>
    <!-- lower-back -->
    <polygon points="147.66 72.77 134.47 77.02 135.32 83.40 149.36 102.13 146.81 82.98"/>
    <polygon points="152.34 72.77 165.53 77.02 164.68 83.40 150.64 102.13 153.19 83.83"/>
  </g>

  <!-- SHOULDERS back (back-deltoids) -->
  <g id="shoulders-b" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <polygon points="129.36 37.02 122.98 39.15 117.45 44.26 118.30 53.62 124.26 49.36 127.23 46.38"/>
    <polygon points="171.06 37.02 178.30 39.57 182.55 44.68 181.70 53.62 174.89 48.94 172.34 45.11"/>
  </g>

  <!-- TRICEPS back (main) -->
  <g id="triceps-b" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <polygon points="126.81 49.79 117.87 55.74 114.47 72.34 116.60 81.70 121.70 63.83 126.81 55.74"/>
    <polygon points="173.62 50.21 182.13 55.74 185.96 73.19 183.40 82.13 177.87 62.98 173.19 55.74"/>
    <polygon points="126.81 58.30 126.81 68.51 122.98 75.32 119.15 77.45 122.55 65.53"/>
    <polygon points="172.77 58.30 177.02 64.68 180.43 77.45 176.60 75.32 172.77 68.94"/>
  </g>

  <!-- GLUTEAL + ABDUCTOR back -->
  <g id="glutes-b" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <!-- gluteal -->
    <polygon points="144.68 99.57 130.21 108.51 129.79 118.72 131.49 125.96 147.23 121.28 149.36 114.89"/>
    <polygon points="155.32 99.15 151.06 114.47 152.34 120.85 168.09 125.96 169.79 119.15 169.36 108.51"/>
    <!-- abductor -->
    <polygon points="148.09 122.98 144.68 122.98 141.28 125.53 145.11 144.26 148.51 135.74 148.94 129.36"/>
    <polygon points="151.91 122.55 155.74 123.40 159.15 125.96 154.89 144.26 151.91 136.17 151.06 129.36"/>
  </g>

  <!-- HAMSTRING + CALVES → legs back -->
  <g id="legs-b" fill="#9E5840" stroke="#5A2A14" stroke-width="0.3">
    <!-- hamstring -->
    <polygon points="128.94 122.13 131.06 129.36 136.60 125.96 135.32 135.32 134.47 150.21 129.36 158.30 128.94 146.81 127.66 141.28 127.23 131.49"/>
    <polygon points="171.49 121.70 169.36 128.94 163.83 125.96 165.53 136.60 166.38 150.21 171.06 158.30 171.49 147.66 172.77 142.13 173.62 131.91"/>
    <polygon points="138.72 125.53 144.26 145.96 140.43 166.81 136.17 152.77 137.02 135.32"/>
    <polygon points="161.70 125.53 163.40 136.17 164.26 153.19 160 166.81 156.17 146.38"/>
    <!-- calves back -->
    <polygon points="129.36 160.43 128.51 167.23 124.68 179.57 123.83 192.77 125.53 197.02 128.51 193.19 129.79 180 131.91 171.06 131.91 166.81"/>
    <polygon points="137.45 165.11 135.32 167.66 133.19 171.91 131.06 180.43 130.21 191.91 134.04 200 138.72 190.64 139.15 168.94"/>
    <polygon points="162.98 165.11 161.28 168.51 161.70 190.64 166.38 199.57 170.64 191.91 168.94 179.57 166.81 170.21"/>
    <polygon points="170.64 160.43 172.34 168.51 175.74 179.15 176.60 192.77 174.47 196.60 172.34 193.62 170.64 179.57 168.09 168.09"/>
  </g>

</svg>
''';
