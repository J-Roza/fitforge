import 'package:flutter/material.dart';
import '../../data/models/exercise.dart';
import '../../core/theme/app_colors.dart';

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
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.bgCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 4),
                  child: Text('Avant',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
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
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 4),
                  child: Text('Arrière',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
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

class _BodyPainter extends CustomPainter {
  final bool isFront;
  final MuscleGroup primary;
  final List<MuscleGroup> secondary;

  const _BodyPainter({
    required this.isFront,
    required this.primary,
    required this.secondary,
  });

  // Virtual canvas 100 × 220
  static const _vw = 100.0;
  static const _vh = 220.0;

  Color _colorFor(MuscleGroup m) {
    if (m == primary) return m.color;
    if (secondary.contains(m)) return m.color.withOpacity(0.45);
    return Colors.transparent;
  }

  void _paintPath(Canvas canvas, Path path, MuscleGroup m,
      {double opacity = 0.75}) {
    final c = _colorFor(m);
    if (c == Colors.transparent) return;
    canvas.drawPath(
      path,
      Paint()
        ..color = c.withOpacity(opacity)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vw;
    final sy = size.height / _vh;
    canvas.save();
    canvas.scale(sx, sy);

    _drawSilhouette(canvas);
    if (isFront) {
      _drawFrontMuscles(canvas);
    } else {
      _drawBackMuscles(canvas);
    }

    canvas.restore();
  }

  // ── Silhouette ───────────────────────────────────────────────────────────

  void _drawSilhouette(Canvas canvas) {
    final p = Paint()
      ..color = const Color(0xFF1C1930)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(const Offset(50, 12), 10, p);

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(44, 21, 12, 11), const Radius.circular(3)),
      p,
    );

    // Torso – hourglass
    final torso = Path()
      ..moveTo(24, 30) // left shoulder top
      ..quadraticBezierTo(20, 33, 20, 42) // left shoulder slope
      ..lineTo(24, 76) // left waist
      ..quadraticBezierTo(24, 84, 26, 92) // waist–hip flare left
      ..lineTo(26, 108) // left hip
      ..quadraticBezierTo(26, 115, 30, 117)
      ..lineTo(42, 117) // crotch left
      ..lineTo(58, 117) // crotch right
      ..quadraticBezierTo(74, 115, 74, 108)
      ..lineTo(74, 92)
      ..quadraticBezierTo(76, 84, 76, 76) // waist–hip flare right
      ..lineTo(80, 42)
      ..quadraticBezierTo(80, 33, 76, 30) // right shoulder slope
      ..close();
    canvas.drawPath(torso, p);

    // Left arm
    final lArm = Path()
      ..moveTo(22, 32) // shoulder
      ..quadraticBezierTo(13, 36, 11, 46)
      ..lineTo(10, 80) // upper arm outer
      ..quadraticBezierTo(9, 86, 10, 92) // elbow
      ..lineTo(11, 118)
      ..lineTo(12, 126) // hand
      ..lineTo(22, 126)
      ..lineTo(22, 118)
      ..lineTo(22, 92)
      ..quadraticBezierTo(22, 86, 22, 80) // elbow inner
      ..lineTo(22, 46) // inner upper arm
      ..close();
    canvas.drawPath(lArm, p);

    // Right arm
    final rArm = Path()
      ..moveTo(78, 32)
      ..quadraticBezierTo(87, 36, 89, 46)
      ..lineTo(90, 80)
      ..quadraticBezierTo(91, 86, 90, 92)
      ..lineTo(89, 118)
      ..lineTo(88, 126)
      ..lineTo(78, 126)
      ..lineTo(78, 118)
      ..lineTo(78, 92)
      ..quadraticBezierTo(78, 86, 78, 80)
      ..lineTo(78, 46)
      ..close();
    canvas.drawPath(rArm, p);

    // Left leg
    final lLeg = Path()
      ..moveTo(26, 117)
      ..quadraticBezierTo(24, 122, 23, 128)
      ..lineTo(21, 162) // outer thigh
      ..quadraticBezierTo(20, 168, 22, 172) // knee
      ..lineTo(21, 204)
      ..lineTo(20, 213) // foot
      ..lineTo(35, 213)
      ..lineTo(34, 204)
      ..lineTo(34, 172)
      ..quadraticBezierTo(36, 168, 37, 162) // knee inner
      ..lineTo(38, 128)
      ..quadraticBezierTo(38, 122, 38, 117)
      ..close();
    canvas.drawPath(lLeg, p);

    // Right leg
    final rLeg = Path()
      ..moveTo(74, 117)
      ..quadraticBezierTo(76, 122, 77, 128)
      ..lineTo(79, 162)
      ..quadraticBezierTo(80, 168, 78, 172)
      ..lineTo(79, 204)
      ..lineTo(80, 213)
      ..lineTo(65, 213)
      ..lineTo(66, 204)
      ..lineTo(66, 172)
      ..quadraticBezierTo(64, 168, 63, 162)
      ..lineTo(62, 128)
      ..quadraticBezierTo(62, 122, 62, 117)
      ..close();
    canvas.drawPath(rLeg, p);

    // Subtle outline for definition
    final outline = Paint()
      ..color = const Color(0xFF2A2640)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawCircle(const Offset(50, 12), 10, outline);
    canvas.drawPath(torso, outline);
    canvas.drawPath(lArm, outline);
    canvas.drawPath(rArm, outline);
    canvas.drawPath(lLeg, outline);
    canvas.drawPath(rLeg, outline);
  }

  // ── Front muscle regions ─────────────────────────────────────────────────

  void _drawFrontMuscles(Canvas canvas) {
    // Chest – left pec
    _paintPath(
        canvas,
        Path()
          ..moveTo(28, 32)
          ..lineTo(49, 32)
          ..quadraticBezierTo(50, 46, 48, 62)
          ..lineTo(34, 67)
          ..quadraticBezierTo(26, 60, 24, 48)
          ..quadraticBezierTo(24, 36, 28, 32)
          ..close(),
        MuscleGroup.chest);
    // Chest – right pec
    _paintPath(
        canvas,
        Path()
          ..moveTo(72, 32)
          ..lineTo(51, 32)
          ..quadraticBezierTo(50, 46, 52, 62)
          ..lineTo(66, 67)
          ..quadraticBezierTo(74, 60, 76, 48)
          ..quadraticBezierTo(76, 36, 72, 32)
          ..close(),
        MuscleGroup.chest);

    // Shoulders – anterior deltoids
    _paintPath(
        canvas,
        _ovalPath(const Rect.fromLTWH(10, 30, 20, 26)),
        MuscleGroup.shoulders);
    _paintPath(
        canvas,
        _ovalPath(const Rect.fromLTWH(70, 30, 20, 26)),
        MuscleGroup.shoulders);

    // Biceps
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(10, 54, 14, 28), 6),
        MuscleGroup.biceps);
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(76, 54, 14, 28), 6),
        MuscleGroup.biceps);

    // Triceps (slightly visible front)
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(10, 54, 14, 28), 6),
        MuscleGroup.triceps,
        opacity: 0.4);
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(76, 54, 14, 28), 6),
        MuscleGroup.triceps,
        opacity: 0.4);

    // Abs / Core
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(34, 66, 32, 48), 5),
        MuscleGroup.core);
    _drawAbsLines(canvas);

    // Hip flexors / glutes (front)
    _paintPath(
        canvas,
        Path()
          ..moveTo(26, 100)
          ..lineTo(42, 116)
          ..lineTo(26, 116)
          ..close(),
        MuscleGroup.glutes,
        opacity: 0.55);
    _paintPath(
        canvas,
        Path()
          ..moveTo(74, 100)
          ..lineTo(58, 116)
          ..lineTo(74, 116)
          ..close(),
        MuscleGroup.glutes,
        opacity: 0.55);

    // Quads (thighs front)
    _paintPath(
        canvas,
        Path()
          ..moveTo(23, 117)
          ..lineTo(38, 117)
          ..lineTo(37, 162)
          ..lineTo(22, 162)
          ..close(),
        MuscleGroup.legs);
    _paintPath(
        canvas,
        Path()
          ..moveTo(77, 117)
          ..lineTo(62, 117)
          ..lineTo(63, 162)
          ..lineTo(78, 162)
          ..close(),
        MuscleGroup.legs);

    // Calves front
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(22, 172, 14, 28), 5),
        MuscleGroup.legs,
        opacity: 0.55);
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(64, 172, 14, 28), 5),
        MuscleGroup.legs,
        opacity: 0.55);
  }

  void _drawAbsLines(Canvas canvas) {
    final c = _colorFor(MuscleGroup.core);
    if (c == Colors.transparent) return;
    final line = Paint()
      ..color = const Color(0xFF0D0B1A).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(50, 66), const Offset(50, 114), line);
    canvas.drawLine(const Offset(34, 82), const Offset(66, 82), line);
    canvas.drawLine(const Offset(34, 98), const Offset(66, 98), line);
  }

  // ── Back muscle regions ──────────────────────────────────────────────────

  void _drawBackMuscles(Canvas canvas) {
    // Trapezius
    _paintPath(
        canvas,
        Path()
          ..moveTo(44, 29)
          ..lineTo(56, 29)
          ..lineTo(68, 56)
          ..lineTo(50, 66)
          ..lineTo(32, 56)
          ..close(),
        MuscleGroup.back);

    // Lats
    _paintPath(
        canvas,
        Path()
          ..moveTo(26, 52)
          ..lineTo(44, 58)
          ..lineTo(40, 108)
          ..lineTo(26, 106)
          ..close(),
        MuscleGroup.back);
    _paintPath(
        canvas,
        Path()
          ..moveTo(74, 52)
          ..lineTo(56, 58)
          ..lineTo(60, 108)
          ..lineTo(74, 106)
          ..close(),
        MuscleGroup.back);

    // Rear deltoids
    _paintPath(
        canvas,
        _ovalPath(const Rect.fromLTWH(10, 30, 20, 22)),
        MuscleGroup.shoulders);
    _paintPath(
        canvas,
        _ovalPath(const Rect.fromLTWH(70, 30, 20, 22)),
        MuscleGroup.shoulders);

    // Triceps (back of upper arms)
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(10, 48, 14, 36), 6),
        MuscleGroup.triceps);
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(76, 48, 14, 36), 6),
        MuscleGroup.triceps);

    // Biceps slightly visible back
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(10, 54, 14, 28), 6),
        MuscleGroup.biceps,
        opacity: 0.35);
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(76, 54, 14, 28), 6),
        MuscleGroup.biceps,
        opacity: 0.35);

    // Erector spinae / lower back
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(34, 68, 14, 40), 5),
        MuscleGroup.back,
        opacity: 0.55);
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(52, 68, 14, 40), 5),
        MuscleGroup.back,
        opacity: 0.55);

    // Core back
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(36, 68, 28, 40), 4),
        MuscleGroup.core,
        opacity: 0.45);

    // Glutes
    _paintPath(
        canvas,
        Path()
          ..moveTo(26, 108)
          ..lineTo(49, 108)
          ..lineTo(49, 145)
          ..quadraticBezierTo(38, 150, 26, 145)
          ..close(),
        MuscleGroup.glutes);
    _paintPath(
        canvas,
        Path()
          ..moveTo(74, 108)
          ..lineTo(51, 108)
          ..lineTo(51, 145)
          ..quadraticBezierTo(62, 150, 74, 145)
          ..close(),
        MuscleGroup.glutes);

    // Hamstrings
    _paintPath(
        canvas,
        Path()
          ..moveTo(23, 130)
          ..lineTo(37, 130)
          ..lineTo(36, 165)
          ..lineTo(22, 165)
          ..close(),
        MuscleGroup.legs);
    _paintPath(
        canvas,
        Path()
          ..moveTo(77, 130)
          ..lineTo(63, 130)
          ..lineTo(64, 165)
          ..lineTo(78, 165)
          ..close(),
        MuscleGroup.legs);

    // Calves back
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(21, 172, 14, 30), 5),
        MuscleGroup.legs);
    _paintPath(
        canvas,
        _roundRect(const Rect.fromLTWH(65, 172, 14, 30), 5),
        MuscleGroup.legs);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Path _ovalPath(Rect r) => Path()..addOval(r);

  Path _roundRect(Rect r, double radius) =>
      Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.isFront != isFront;
}
