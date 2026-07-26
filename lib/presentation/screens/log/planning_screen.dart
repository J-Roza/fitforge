import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/log_provider.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  static const _dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(sessionsConfigProvider);
    final planAsync = ref.watch(planningProvider);
    final plan = planAsync.value ?? {};
    final today = DateTime.now().weekday % 7;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: const Text('Mon Programme',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Appuie sur un jour pour lui attribuer une séance.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: List.generate(7, (i) {
                final dayIdx = (i + 1) % 7;
                final isToday = dayIdx == today;
                final sessionType = plan[dayIdx];
                final config = sessionType != null
                    ? configs.firstWhere((c) => c.type == sessionType,
                        orElse: () => configs.first)
                    : null;

                return GestureDetector(
                  onTap: () async {
                    final types = configs.map((c) => c.type).toList();
                    final cur = plan[dayIdx];
                    final idx = cur == null ? -1 : types.indexOf(cur);
                    final next =
                        (idx == -1 || idx == types.length - 1) ? null : types[idx + 1];
                    final newType = cur == null
                        ? (types.isEmpty ? null : types.first)
                        : next;
                    await ref
                        .read(planningProvider.notifier)
                        .setDay(dayIdx, newType);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: config != null
                          ? config.color.withValues(alpha: .1)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isToday
                              ? AppColors.accent
                              : (config?.color ?? AppColors.border),
                          width: isToday ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_dayNames[dayIdx],
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: config?.color ??
                                    AppColors.textMuted,
                                letterSpacing: .5)),
                        const SizedBox(height: 8),
                        if (config != null) ...[
                          Text('S${config.type}',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: config.color)),
                          Text(config.name,
                              style: TextStyle(
                                  fontSize: 8, color: config.color),
                              textAlign: TextAlign.center),
                        ] else
                          Text('—',
                              style: TextStyle(
                                  fontSize: 22,
                                  color: AppColors.textMuted
                                      .withValues(alpha: .3))),
                        if (isToday) ...[
                          const SizedBox(height: 4),
                          Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text(
                "Appuie encore pour changer, une fois de plus pour effacer.",
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
