import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/models/exercise.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MuscleBodyDiagram — planche anatomique réaliste (images PNG) + halos de
//  surlignage rouge (muscle primaire) / orange (secondaires), confinés à la
//  silhouette grâce à un compositing BlendMode.srcATop.
//
//  Images : assets/body/muscles_front.png & muscles_back.png (405 × 1056).
// ─────────────────────────────────────────────────────────────────────────────

const double _imgW = 405;
const double _imgH = 1056;

const _primaryColor = Color(0xFFFF3B30); // rouge vif
const _secondaryColor = Color(0xFFFF9500); // orange vif

/// Une zone de surlignage, en coordonnées normalisées (0..1) relatives à
/// l'image de sa vue. `view` : 0 = face, 1 = dos.
class _Spot {
  final int view;
  final double cx, cy, rx, ry;
  const _Spot(this.view, this.cx, this.cy, this.rx, this.ry);
}

// Positions approximatives des muscles sur les deux images.
const Map<MuscleGroup, List<_Spot>> _spots = {
  MuscleGroup.chest: [
    _Spot(0, 0.357, 0.221, 0.182, 0.057),
    _Spot(0, 0.612, 0.221, 0.182, 0.057),
  ],
  MuscleGroup.shoulders: [
    _Spot(0, 0.211, 0.195, 0.109, 0.057),
    _Spot(0, 0.758, 0.195, 0.109, 0.057),
    _Spot(1, 0.44, 0.174, 0.237, 0.062), // trapèzes
    _Spot(1, 0.166, 0.205, 0.109, 0.052),
    _Spot(1, 0.713, 0.205, 0.109, 0.052),
  ],
  MuscleGroup.biceps: [
    _Spot(0, 0.138, 0.278, 0.082, 0.062),
    _Spot(0, 0.831, 0.278, 0.082, 0.062),
  ],
  MuscleGroup.triceps: [
    _Spot(1, 0.075, 0.289, 0.082, 0.062),
    _Spot(1, 0.804, 0.289, 0.082, 0.062),
  ],
  MuscleGroup.back: [
    _Spot(1, 0.44, 0.258, 0.292, 0.073),
    _Spot(1, 0.33, 0.299, 0.128, 0.052),
    _Spot(1, 0.549, 0.299, 0.128, 0.052),
  ],
  MuscleGroup.core: [
    _Spot(0, 0.485, 0.35, 0.173, 0.09),
  ],
  MuscleGroup.glutes: [
    _Spot(1, 0.33, 0.435, 0.128, 0.062),
    _Spot(1, 0.549, 0.435, 0.128, 0.062),
  ],
  MuscleGroup.legs: [
    _Spot(0, 0.339, 0.528, 0.137, 0.115),
    _Spot(0, 0.63, 0.528, 0.137, 0.115),
    _Spot(1, 0.312, 0.58, 0.128, 0.104),
    _Spot(1, 0.567, 0.58, 0.128, 0.104),
    _Spot(1, 0.33, 0.758, 0.091, 0.062),
    _Spot(1, 0.549, 0.758, 0.091, 0.062),
  ],
};

class _Glow {
  final double cx, cy, rx, ry;
  final Color color;
  const _Glow(this.cx, this.cy, this.rx, this.ry, this.color);
}

class MuscleBodyDiagram extends StatefulWidget {
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;

  const MuscleBodyDiagram({
    super.key,
    required this.primaryMuscle,
    required this.secondaryMuscles,
  });

  @override
  State<MuscleBodyDiagram> createState() => _MuscleBodyDiagramState();
}

class _MuscleBodyDiagramState extends State<MuscleBodyDiagram> {
  ui.Image? _front;
  ui.Image? _back;

  @override
  void initState() {
    super.initState();
    _load('assets/body/muscles_front.png')
        .then((img) => mounted ? setState(() => _front = img) : null);
    _load('assets/body/muscles_back.png')
        .then((img) => mounted ? setState(() => _back = img) : null);
  }

  Future<ui.Image> _load(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  List<_Glow> _glowsForView(int view) {
    final glows = <_Glow>[];
    for (final s in _spots[widget.primaryMuscle] ?? const <_Spot>[]) {
      if (s.view == view) glows.add(_Glow(s.cx, s.cy, s.rx, s.ry, _primaryColor));
    }
    for (final m in widget.secondaryMuscles) {
      if (m == widget.primaryMuscle) continue;
      for (final s in _spots[m] ?? const <_Spot>[]) {
        if (s.view == view) {
          glows.add(_Glow(s.cx, s.cy, s.rx, s.ry, _secondaryColor));
        }
      }
    }
    return glows;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: const [
              Expanded(
                child: Text('AVANT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF6B6880),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ),
              Expanded(
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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0D1C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2440)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _view(_front, 0)),
              const SizedBox(width: 8),
              Expanded(child: _view(_back, 1)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(color: _primaryColor, label: 'Primaire'),
              const SizedBox(width: 20),
              if (widget.secondaryMuscles.isNotEmpty)
                _Dot(color: _secondaryColor, label: 'Secondaire'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _view(ui.Image? image, int view) {
    return AspectRatio(
      aspectRatio: _imgW / _imgH,
      child: image == null
          ? const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : CustomPaint(
              painter: _BodyPainter(image, _glowsForView(view)),
              size: Size.infinite,
            ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final ui.Image image;
  final List<_Glow> glows;
  _BodyPainter(this.image, this.glows);

  @override
  void paint(Canvas canvas, Size size) {
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    // Nouveau calque : l'image sert de "destination", les halos en srcATop
    // ne s'affichent donc que sur la silhouette (pas sur le fond transparent).
    canvas.saveLayer(dst, Paint());
    canvas.drawImageRect(image, src, dst, Paint());

    for (final g in glows) {
      final rect = Rect.fromCenter(
        center: Offset(g.cx * size.width, g.cy * size.height),
        width: g.rx * 2 * size.width,
        height: g.ry * 2 * size.height,
      );
      final paint = Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = RadialGradient(
          colors: [
            g.color.withValues(alpha: 0.85),
            g.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      canvas.drawOval(rect, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.image != image || old.glows != glows;
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);
}
