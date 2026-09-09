import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Disques standard (kg), du plus lourd au plus léger.
const _plates = <double>[25, 20, 15, 10, 5, 2.5, 1.25];

// Couleur indicative par disque (codes couleur haltéro courants).
final Map<double, Color> _plateColor = {
  25: Color(0xFFE8484F),
  20: Color(0xFF4F9EE8),
  15: Color(0xFFFFD60A),
  10: Color(0xFF30D158),
  5: Color(0xFFEDEDED),
  2.5: Color(0xFFAF52DE),
  1.25: Color(0xFF8E8E93),
};

/// Ouvre le calculateur de disques (quels disques mettre de chaque côté).
void showPlateCalculator(BuildContext context, {double initialTarget = 60}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _PlateCalculatorSheet(initialTarget: initialTarget),
  );
}

String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

class _PlateCalculatorSheet extends StatefulWidget {
  final double initialTarget;
  const _PlateCalculatorSheet({required this.initialTarget});

  @override
  State<_PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<_PlateCalculatorSheet> {
  late double _target =
      (widget.initialTarget < 20 ? 20 : widget.initialTarget).toDouble();
  double _bar = 20;

  /// Disques d'un côté (greedy) + reste non atteignable.
  (List<double>, double) _compute() {
    var perSide = (_target - _bar) / 2;
    final out = <double>[];
    if (perSide <= 0) return (out, 0);
    for (final p in _plates) {
      while (perSide >= p - 1e-9) {
        out.add(p);
        perSide -= p;
      }
    }
    return (out, perSide);
  }

  @override
  Widget build(BuildContext context) {
    final (plates, rest) = _compute();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Calculateur de disques',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // Poids cible + / -
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => setState(() =>
                        _target = (_target - 2.5).clamp(_bar, 500).toDouble())),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text('${_fmt(_target)} kg',
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    const Text('poids total',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 20),
                _RoundBtn(
                    icon: Icons.add_rounded,
                    onTap: () => setState(
                        () => _target = (_target + 2.5).clamp(_bar, 500).toDouble())),
              ],
            ),
            const SizedBox(height: 18),

            // Barre
            Row(
              children: [
                const Text('Barre',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                ...[20.0, 15.0, 10.0].map((b) {
                  final sel = _bar == b;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _bar = b;
                        if (_target < _bar) _target = _bar;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.accent
                              : AppColors.bgCardElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  sel ? AppColors.accent : AppColors.border),
                        ),
                        child: Text('${_fmt(b)} kg',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            const Text('DE CHAQUE CÔTÉ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: .5)),
            const SizedBox(height: 10),
            if (plates.isEmpty)
              const Text('Barre à vide (aucun disque).',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plates
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (_plateColor[p] ?? AppColors.accent)
                                .withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: (_plateColor[p] ?? AppColors.accent)
                                    .withValues(alpha: .5)),
                          ),
                          child: Text('${_fmt(p)} kg',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _plateColor[p] ?? AppColors.accent)),
                        ))
                    .toList(),
              ),
            if (rest > 1e-6) ...[
              const SizedBox(height: 10),
              Text(
                  '⚠️ ${_fmt(double.parse(rest.toStringAsFixed(2)))} kg par côté non atteignable avec ces disques.',
                  style: const TextStyle(
                      color: Color(0xFFFF9F0A), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: AppColors.bgCardElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      );
}
