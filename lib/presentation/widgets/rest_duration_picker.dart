import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/log_provider.dart';

/// Formate une durée en secondes : « 45s », « 2min », « 1m30 ».
String formatRestDuration(int s) {
  final m = s ~/ 60, sec = s % 60;
  if (m == 0) return '${sec}s';
  return sec == 0 ? '${m}min' : '${m}m${sec.toString().padLeft(2, '0')}';
}

/// Ouvre le sélecteur de temps de repos (1 à 5 min). Persiste le choix
/// et le retourne, ou `null` si l'utilisateur annule.
Future<int?> showRestDurationPicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(timerDurationProvider).value ?? 90;
  final picked = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
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
            const Text('Temps de repos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Entre chaque série.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: TimerDurationNotifier.durations.map((d) {
                final selected = d == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent
                          : AppColors.bgCardElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : AppColors.border),
                    ),
                    child: Text(
                      formatRestDuration(d),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
  if (picked != null) {
    await ref.read(timerDurationProvider.notifier).set(picked);
  }
  return picked;
}
