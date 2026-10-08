import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/widgets/empty_state.dart';
import 'routines_view_model.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routinesVm = context.watch<RoutinesViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (routinesVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final routines = routinesVm.routines;

    return Scaffold(
      backgroundColor: isDark
          ? ThemeColors.darkBackground
          : ThemeColors.lightBackground,
      appBar: AppBar(
        title: const Text("Focus Routines"),
      ),
      body: routines.isEmpty
          ? const EmptyState(
              icon: Icons.checklist_rounded,
              title: "No routines set",
              description: "Build deliberate routines to transition smoothly into focus.",
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(ThemeSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Daily Rituals",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.xxs),
                  Text(
                    "Calm repetitive habits remove decision fatigue before deep work.",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? ThemeColors.darkTextSecondary
                          : ThemeColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.l),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routines.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final routine = routines[index];

                      return Container(
                        padding: const EdgeInsets.all(ThemeSpacing.m),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ThemeColors.darkSurface
                              : ThemeColors.lightSurface,
                          borderRadius: ThemeRadius.radiusL,
                          border: Border.all(
                            color: isDark
                                ? ThemeColors.darkBorder
                                : ThemeColors.lightBorder,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  routine.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: routine.isFullyCompleted
                                        ? ThemeColors.successSubtle
                                        : ThemeColors.primaryAccentSubtle,
                                    borderRadius: ThemeRadius.radiusFull,
                                  ),
                                  child: Text(
                                    "${routine.completedStepsCount}/${routine.steps.length} Complete",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: routine.isFullyCompleted
                                          ? ThemeColors.success
                                          : ThemeColors.primaryAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              routine.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? ThemeColors.darkTextSecondary
                                    : ThemeColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: ThemeSpacing.m),
                            const Divider(),
                            const SizedBox(height: ThemeSpacing.s),

                            // Steps checklist
                            ...routine.steps.map((step) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: InkWell(
                                  onTap: () => routinesVm.toggleStep(
                                    routine.id,
                                    step.id,
                                  ),
                                  borderRadius: ThemeRadius.radiusSm,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          step.isCompleted
                                              ? Icons.check_box_rounded
                                              : Icons.check_box_outline_blank_rounded,
                                          size: 20,
                                          color: step.isCompleted
                                              ? ThemeColors.success
                                              : ThemeColors.darkTextMuted,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            step.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              decoration: step.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: isDark
                                                  ? ThemeColors.darkTextPrimary
                                                  : ThemeColors.lightTextPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          step.time,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? ThemeColors.darkTextMuted
                                                : ThemeColors.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
