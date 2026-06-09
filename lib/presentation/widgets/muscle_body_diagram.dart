import 'package:flutter/material.dart';
import '../../data/models/exercise.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MuscleBodyDiagram
//  Vue avant + arrière d'un corps humain stylisé.
//  Muscles primaires  → rouge vif
//  Muscles secondaires → rouge clair / orange
// ─────────────────────────────────────────────────────────────────────────────

class MuscleBodyDiagram extends StatelessWidget {
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;

  const MuscleBodyDiagram({
    super.key,
    required this.primaryMuscle,
    required this.secondaryMuscles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0E1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2640)),
      ),
      child: Row(
        children: [
          // ── Vue avant ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 6),
                  child: Text('AVANT',
                      style: TextStyle(
                          color: Color(0xFF6B6880),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: CustomPaint(
                      painter: _BodyPainter(
                        isFront: true,
                        primary: primaryMuscle,
                        secondary: secondaryMuscles,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Séparateur
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 16),
            color: const Color(0xFF2A2640),
          ),
          // ── Vue arrière ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 6),
                  child: Text('ARRIÈRE',
                      style: TextStyle(
                          color: Color(0xFF6B6880),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: CustomPaint(
                      painter: _BodyPainter(
                        isFront: false,
                        primary: primaryMuscle,
                        secondary: secondaryMuscles,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────────────────────────

class _BodyPainter extends CustomPainter {
  final bool isFront;
  final MuscleGroup primary;
  final List<MuscleGroup> secondary;

  static const _primaryColor   = Color(0xFFE53935); // rouge vif
  static const _secondaryColor = Color(0xFFFF6D00); // orange
  static const _skinBase       = Color(0xFF3A2E2E);  // silhouette sombre
  static const _skinHighlight  = Color(0xFF4A3A3A);  // relief musculaire
  static const _skinEdge       = Color(0xFF251A1A);  // contour

  // Canvas virtuel 100 × 240
  static const _vw = 100.0;
  static const _vh = 240.0;

  const _BodyPainter({
    required this.isFront,
    required this.primary,
    required this.secondary,
  });

  bool _isPrimary(MuscleGroup m) => m == primary;
  bool _isSecondary(MuscleGroup m) => secondary.contains(m);
  bool _isActive(MuscleGroup m) => _isPrimary(m) || _isSecondary(m);

  Color _muscleColor(MuscleGroup m) {
    if (_isPrimary(m)) return _primaryColor;
    if (_isSecondary(m)) return _secondaryColor;
    return Colors.transparent;
  }

  // ── Rendu d'une région musculaire ─────────────────────────────────────────
  void _fill(Canvas c, Path p, MuscleGroup m, {double opacity = 1.0}) {
    final col = _muscleColor(m);
    if (col == Colors.transparent) return;
    c.drawPath(p, Paint()
      ..color = col.withOpacity(opacity * (_isPrimary(m) ? 0.85 : 0.60))
      ..style = PaintingStyle.fill);
    // Contour rouge pour le muscle actif
    c.drawPath(p, Paint()
      ..color = col.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  // ── Silhouette de base ────────────────────────────────────────────────────
  void _silhouette(Canvas c) {
    final base  = Paint()..color = _skinBase ..style = PaintingStyle.fill;
    final edge  = Paint()..color = _skinEdge ..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final light = Paint()..color = _skinHighlight..style = PaintingStyle.fill;

    // ── Tête ──────────────────────────────────────────────────────────────
    final head = Path()..addOval(const Rect.fromLTWH(38, 2, 24, 26));
    c.drawPath(head, base);
    c.drawPath(head, edge);

    // ── Cou ───────────────────────────────────────────────────────────────
    final neck = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(44, 26, 12, 12), const Radius.circular(4)));
    c.drawPath(neck, base);

    // ── Torse ─────────────────────────────────────────────────────────────
    final torso = Path()
      ..moveTo(22, 32)
      ..quadraticBezierTo(16, 36, 14, 48)
      ..lineTo(18, 82)
      ..quadraticBezierTo(20, 92, 22, 98)
      ..lineTo(24, 116)
      ..lineTo(44, 118)
      ..lineTo(56, 118)
      ..lineTo(76, 116)
      ..lineTo(78, 98)
      ..quadraticBezierTo(80, 92, 82, 82)
      ..lineTo(86, 48)
      ..quadraticBezierTo(84, 36, 78, 32)
      ..quadraticBezierTo(66, 28, 50, 28)
      ..quadraticBezierTo(34, 28, 22, 32)
      ..close();
    c.drawPath(torso, base);

    // Ligne sternum / colonne (relief)
    c.drawPath(
      Path()
        ..moveTo(50, 30)
        ..quadraticBezierTo(50, 64, 50, 118),
      Paint()
        ..color = _skinEdge.withOpacity(0.4)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );

    c.drawPath(torso, edge);

    // ── Bras gauche ────────────────────────────────────────────────────────
    final lArm = Path()
      ..moveTo(22, 34)
      ..quadraticBezierTo(10, 38, 8, 52)
      ..lineTo(7, 92)
      ..quadraticBezierTo(6, 100, 8, 106)
      ..lineTo(10, 130)
      ..quadraticBezierTo(10, 134, 11, 136)
      ..lineTo(20, 136)
      ..quadraticBezierTo(21, 134, 21, 130)
      ..lineTo(20, 106)
      ..quadraticBezierTo(22, 100, 22, 92)
      ..lineTo(22, 52)
      ..close();
    c.drawPath(lArm, base);
    c.drawPath(lArm, edge);

    // ── Bras droit ─────────────────────────────────────────────────────────
    final rArm = Path()
      ..moveTo(78, 34)
      ..quadraticBezierTo(90, 38, 92, 52)
      ..lineTo(93, 92)
      ..quadraticBezierTo(94, 100, 92, 106)
      ..lineTo(90, 130)
      ..quadraticBezierTo(90, 134, 89, 136)
      ..lineTo(80, 136)
      ..quadraticBezierTo(79, 134, 79, 130)
      ..lineTo(80, 106)
      ..quadraticBezierTo(78, 100, 78, 92)
      ..lineTo(78, 52)
      ..close();
    c.drawPath(rArm, base);
    c.drawPath(rArm, edge);

    // ── Avant-bras gauche ──────────────────────────────────────────────────
    final lForearm = Path()
      ..moveTo(8, 106)
      ..quadraticBezierTo(6, 112, 5, 128)
      ..lineTo(5, 152)
      ..quadraticBezierTo(5, 158, 8, 160)
      ..lineTo(20, 160)
      ..quadraticBezierTo(22, 158, 22, 152)
      ..lineTo(21, 128)
      ..quadraticBezierTo(21, 112, 20, 106)
      ..close();
    c.drawPath(lForearm, base..color = _skinBase.withOpacity(0.85));
    c.drawPath(lForearm, edge);

    // ── Avant-bras droit ───────────────────────────────────────────────────
    final rForearm = Path()
      ..moveTo(92, 106)
      ..quadraticBezierTo(94, 112, 95, 128)
      ..lineTo(95, 152)
      ..quadraticBezierTo(95, 158, 92, 160)
      ..lineTo(80, 160)
      ..quadraticBezierTo(78, 158, 78, 152)
      ..lineTo(79, 128)
      ..quadraticBezierTo(79, 112, 80, 106)
      ..close();
    c.drawPath(rForearm, base..color = _skinBase.withOpacity(0.85));
    c.drawPath(rForearm, edge);

    base.color = _skinBase; // reset

    // ── Jambe gauche ───────────────────────────────────────────────────────
    final lThigh = Path()
      ..moveTo(24, 118)
      ..quadraticBezierTo(22, 124, 21, 132)
      ..lineTo(19, 172)
      ..quadraticBezierTo(18, 178, 20, 184)
      ..lineTo(21, 192)
      ..lineTo(38, 192)
      ..lineTo(38, 184)
      ..quadraticBezierTo(40, 178, 40, 172)
      ..lineTo(40, 132)
      ..quadraticBezierTo(40, 124, 40, 118)
      ..close();
    c.drawPath(lThigh, base);
    c.drawPath(lThigh, edge);

    // ── Jambe droite ────────────────────────────────────────────────────────
    final rThigh = Path()
      ..moveTo(76, 118)
      ..quadraticBezierTo(78, 124, 79, 132)
      ..lineTo(81, 172)
      ..quadraticBezierTo(82, 178, 80, 184)
      ..lineTo(79, 192)
      ..lineTo(62, 192)
      ..lineTo(62, 184)
      ..quadraticBezierTo(60, 178, 60, 172)
      ..lineTo(60, 132)
      ..quadraticBezierTo(60, 124, 60, 118)
      ..close();
    c.drawPath(rThigh, base);
    c.drawPath(rThigh, edge);

    // ── Mollet gauche ──────────────────────────────────────────────────────
    final lCalf = Path()
      ..moveTo(20, 192)
      ..quadraticBezierTo(18, 198, 18, 208)
      ..lineTo(19, 228)
      ..lineTo(23, 230)
      ..lineTo(38, 230)
      ..lineTo(40, 228)
      ..lineTo(40, 208)
      ..quadraticBezierTo(40, 198, 38, 192)
      ..close();
    c.drawPath(lCalf, base);
    c.drawPath(lCalf, edge);

    // ── Mollet droit ───────────────────────────────────────────────────────
    final rCalf = Path()
      ..moveTo(80, 192)
      ..quadraticBezierTo(82, 198, 82, 208)
      ..lineTo(81, 228)
      ..lineTo(77, 230)
      ..lineTo(62, 230)
      ..lineTo(60, 228)
      ..lineTo(60, 208)
      ..quadraticBezierTo(60, 198, 62, 192)
      ..close();
    c.drawPath(rCalf, base);
    c.drawPath(rCalf, edge);
  }

  // ── Muscles — vue avant ───────────────────────────────────────────────────
  void _frontMuscles(Canvas c) {
    // Pectoraux gauche
    _fill(c, Path()
      ..moveTo(26, 34)
      ..quadraticBezierTo(26, 30, 48, 30)
      ..quadraticBezierTo(50, 44, 48, 64)
      ..lineTo(36, 70)
      ..quadraticBezierTo(24, 60, 22, 48)
      ..quadraticBezierTo(22, 36, 26, 34)
      ..close(), MuscleGroup.chest);

    // Pectoraux droit
    _fill(c, Path()
      ..moveTo(74, 34)
      ..quadraticBezierTo(74, 30, 52, 30)
      ..quadraticBezierTo(50, 44, 52, 64)
      ..lineTo(64, 70)
      ..quadraticBezierTo(76, 60, 78, 48)
      ..quadraticBezierTo(78, 36, 74, 34)
      ..close(), MuscleGroup.chest);

    // Épaules ant. gauche
    _fill(c, Path()..addOval(const Rect.fromLTWH(8, 28, 22, 28)),
        MuscleGroup.shoulders);
    // Épaules ant. droit
    _fill(c, Path()..addOval(const Rect.fromLTWH(70, 28, 22, 28)),
        MuscleGroup.shoulders);

    // Biceps gauche
    _fill(c, _rr(const Rect.fromLTWH(8, 56, 15, 34), 7),
        MuscleGroup.biceps);
    // Biceps droit
    _fill(c, _rr(const Rect.fromLTWH(77, 56, 15, 34), 7),
        MuscleGroup.biceps);

    // Triceps (visible côté) gauche
    _fill(c, _rr(const Rect.fromLTWH(8, 56, 15, 34), 7),
        MuscleGroup.triceps, opacity: 0.4);
    _fill(c, _rr(const Rect.fromLTWH(77, 56, 15, 34), 7),
        MuscleGroup.triceps, opacity: 0.4);

    // Abdominaux
    _fill(c, _rr(const Rect.fromLTWH(34, 68, 32, 48), 5),
        MuscleGroup.core);
    _absGrid(c);

    // Obliques
    _fill(c, Path()
      ..moveTo(22, 72)
      ..lineTo(35, 70)
      ..lineTo(34, 112)
      ..lineTo(22, 108)
      ..close(), MuscleGroup.core, opacity: 0.55);
    _fill(c, Path()
      ..moveTo(78, 72)
      ..lineTo(65, 70)
      ..lineTo(66, 112)
      ..lineTo(78, 108)
      ..close(), MuscleGroup.core, opacity: 0.55);

    // Quadriceps gauche
    _fill(c, Path()
      ..moveTo(21, 119)
      ..lineTo(40, 119)
      ..quadraticBezierTo(40, 160, 40, 172)
      ..lineTo(21, 172)
      ..quadraticBezierTo(19, 148, 21, 119)
      ..close(), MuscleGroup.legs);

    // Quadriceps droit
    _fill(c, Path()
      ..moveTo(79, 119)
      ..lineTo(60, 119)
      ..quadraticBezierTo(60, 160, 60, 172)
      ..lineTo(79, 172)
      ..quadraticBezierTo(81, 148, 79, 119)
      ..close(), MuscleGroup.legs);

    // Tibias / mollets avant
    _fill(c, _rr(const Rect.fromLTWH(19, 193, 20, 32), 5),
        MuscleGroup.legs, opacity: 0.55);
    _fill(c, _rr(const Rect.fromLTWH(61, 193, 20, 32), 5),
        MuscleGroup.legs, opacity: 0.55);

    // Fessiers (avant visible)
    _fill(c, Path()
      ..moveTo(24, 104)
      ..lineTo(44, 118)
      ..lineTo(24, 118)
      ..close(), MuscleGroup.glutes, opacity: 0.5);
    _fill(c, Path()
      ..moveTo(76, 104)
      ..lineTo(56, 118)
      ..lineTo(76, 118)
      ..close(), MuscleGroup.glutes, opacity: 0.5);
  }

  void _absGrid(Canvas c) {
    if (!_isActive(MuscleGroup.core)) return;
    final line = Paint()
      ..color = const Color(0xFF0A0812).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // Ligne verticale (sternum)
    c.drawLine(const Offset(50, 68), const Offset(50, 116), line);
    // Lignes horizontales (packs)
    c.drawLine(const Offset(35, 82), const Offset(65, 82), line);
    c.drawLine(const Offset(35, 96), const Offset(65, 96), line);
    c.drawLine(const Offset(35, 108), const Offset(65, 108), line);
  }

  // ── Muscles — vue arrière ─────────────────────────────────────────────────
  void _backMuscles(Canvas c) {
    // Trapèze
    _fill(c, Path()
      ..moveTo(44, 30)
      ..lineTo(56, 30)
      ..quadraticBezierTo(76, 32, 78, 42)
      ..lineTo(70, 62)
      ..lineTo(50, 72)
      ..lineTo(30, 62)
      ..lineTo(22, 42)
      ..quadraticBezierTo(24, 32, 44, 30)
      ..close(), MuscleGroup.back);

    // Grand dorsal gauche
    _fill(c, Path()
      ..moveTo(22, 46)
      ..lineTo(44, 56)
      ..lineTo(40, 112)
      ..lineTo(24, 108)
      ..quadraticBezierTo(20, 88, 20, 72)
      ..close(), MuscleGroup.back);

    // Grand dorsal droit
    _fill(c, Path()
      ..moveTo(78, 46)
      ..lineTo(56, 56)
      ..lineTo(60, 112)
      ..lineTo(76, 108)
      ..quadraticBezierTo(80, 88, 80, 72)
      ..close(), MuscleGroup.back);

    // Érecteurs spinaux / lombes
    _fill(c, _rr(const Rect.fromLTWH(34, 72, 14, 44), 5),
        MuscleGroup.back, opacity: 0.65);
    _fill(c, _rr(const Rect.fromLTWH(52, 72, 14, 44), 5),
        MuscleGroup.back, opacity: 0.65);

    // Colonne (ligne de creux)
    if (_isActive(MuscleGroup.back)) {
      c.drawLine(
        const Offset(50, 30), const Offset(50, 116),
        Paint()
          ..color = const Color(0xFF0A0812).withOpacity(0.4)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }

    // Épaules post. gauche
    _fill(c, Path()..addOval(const Rect.fromLTWH(8, 28, 22, 26)),
        MuscleGroup.shoulders);
    // Épaules post. droit
    _fill(c, Path()..addOval(const Rect.fromLTWH(70, 28, 22, 26)),
        MuscleGroup.shoulders);

    // Triceps gauche
    _fill(c, _rr(const Rect.fromLTWH(8, 54, 15, 42), 7),
        MuscleGroup.triceps);
    // Triceps droit
    _fill(c, _rr(const Rect.fromLTWH(77, 54, 15, 42), 7),
        MuscleGroup.triceps);

    // Biceps légèrement visible
    _fill(c, _rr(const Rect.fromLTWH(8, 54, 15, 34), 7),
        MuscleGroup.biceps, opacity: 0.3);
    _fill(c, _rr(const Rect.fromLTWH(77, 54, 15, 34), 7),
        MuscleGroup.biceps, opacity: 0.3);

    // Fessiers gauche
    _fill(c, Path()
      ..moveTo(24, 110)
      ..lineTo(49, 110)
      ..lineTo(49, 148)
      ..quadraticBezierTo(38, 156, 24, 148)
      ..close(), MuscleGroup.glutes);

    // Fessiers droit
    _fill(c, Path()
      ..moveTo(76, 110)
      ..lineTo(51, 110)
      ..lineTo(51, 148)
      ..quadraticBezierTo(62, 156, 76, 148)
      ..close(), MuscleGroup.glutes);

    // Ischio-jambiers gauche
    _fill(c, Path()
      ..moveTo(21, 148)
      ..lineTo(40, 148)
      ..quadraticBezierTo(40, 170, 40, 182)
      ..lineTo(21, 182)
      ..quadraticBezierTo(19, 166, 21, 148)
      ..close(), MuscleGroup.legs);

    // Ischio-jambiers droit
    _fill(c, Path()
      ..moveTo(79, 148)
      ..lineTo(60, 148)
      ..quadraticBezierTo(60, 170, 60, 182)
      ..lineTo(79, 182)
      ..quadraticBezierTo(81, 166, 79, 148)
      ..close(), MuscleGroup.legs);

    // Mollets arrière gauche
    _fill(c, _rr(const Rect.fromLTWH(19, 193, 21, 34), 6),
        MuscleGroup.legs);
    // Mollets arrière droit
    _fill(c, _rr(const Rect.fromLTWH(60, 193, 21, 34), 6),
        MuscleGroup.legs);

    // Abdos dos (obliques arrière)
    _fill(c, _rr(const Rect.fromLTWH(36, 72, 28, 36), 4),
        MuscleGroup.core, opacity: 0.4);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Path _rr(Rect r, double radius) =>
      Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vw;
    final sy = size.height / _vh;
    canvas.save();
    canvas.scale(sx, sy);

    _silhouette(canvas);
    if (isFront) {
      _frontMuscles(canvas);
    } else {
      _backMuscles(canvas);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.isFront != isFront;
}
