import 'package:flutter/material.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/theme/theme_radius.dart';
import '../../../app/theme/theme_spacing.dart';

class GoalMilestone {
  final String title;
  final int targetMinutes;
  final String timeOfDay;
  final IconData icon;

  const GoalMilestone({
    required this.title,
    required this.targetMinutes,
    required this.timeOfDay,
    required this.icon,
  });
}

class GoalPathwayWidget extends StatelessWidget {
  final int currentProductiveMinutes;
  final int goalMinutes;
  final VoidCallback onStartRemainingSession;

  const GoalPathwayWidget({
    super.key,
    required this.currentProductiveMinutes,
    required this.goalMinutes,
    required this.onStartRemainingSession,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingMinutes = (goalMinutes - currentProductiveMinutes).clamp(0, goalMinutes);
    final percent = goalMinutes > 0 ? ((currentProductiveMinutes / goalMinutes) * 100).toInt().clamp(0, 100) : 0;
    final isGoalAchieved = currentProductiveMinutes >= goalMinutes;

    final milestones = [
      const GoalMilestone(
        title: "Morning Alignment",
        targetMinutes: 60,
        timeOfDay: "09:00 AM - 11:00 AM",
        icon: Icons.wb_sunny_outlined,
      ),
      GoalMilestone(
        title: "Core Deep Flow",
        targetMinutes: (goalMinutes * 0.6).toInt(),
        timeOfDay: "11:30 AM - 02:00 PM",
        icon: Icons.bolt_rounded,
      ),
      GoalMilestone(
        title: "Daily Target Victory",
        targetMinutes: goalMinutes,
        timeOfDay: "03:00 PM - 06:00 PM",
        icon: Icons.emoji_events_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(ThemeSpacing.m),
      decoration: BoxDecoration(
        color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
        borderRadius: ThemeRadius.radiusL,
        border: Border.all(
          color: isGoalAchieved
              ? ThemeColors.success.withAlpha(120)
              : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryAccentSubtle,
                      borderRadius: ThemeRadius.radiusSm,
                    ),
                    child: const Icon(Icons.route_rounded, size: 16, color: ThemeColors.primaryAccent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Daily Goal Pathway",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGoalAchieved ? ThemeColors.successSubtle : ThemeColors.primaryAccentSubtle,
                  borderRadius: ThemeRadius.radiusFull,
                ),
                child: Text(
                  isGoalAchieved ? "GOAL CRUSHED" : "$percent% ON TRACK",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isGoalAchieved ? ThemeColors.success : ThemeColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeSpacing.s),

          // Context summary
          Text(
            isGoalAchieved
                ? "You reached your $goalMinutes min goal! Any extra focus strengthens your streak."
                : "You have completed $currentProductiveMinutes min of your $goalMinutes min daily target ($remainingMinutes min remaining).",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.m),

          // Stepper / Path Milestones
          Column(
            children: List.generate(milestones.length, (i) {
              final m = milestones[i];
              final isCompleted = currentProductiveMinutes >= m.targetMinutes;
              final isCurrent = !isCompleted &&
                  (i == 0 || currentProductiveMinutes >= milestones[i - 1].targetMinutes);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Node dot & connecting line
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? ThemeColors.success
                                : isCurrent
                                    ? ThemeColors.primaryAccent
                                    : (isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightElevatedSurface),
                            border: Border.all(
                              color: isCompleted
                                  ? ThemeColors.success
                                  : isCurrent
                                      ? ThemeColors.primaryAccent
                                      : ThemeColors.darkTextMuted,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : Icon(
                                    m.icon,
                                    size: 12,
                                    color: isCurrent ? Colors.white : ThemeColors.darkTextMuted,
                                  ),
                          ),
                        ),
                        if (i < milestones.length - 1)
                          Container(
                            width: 2,
                            height: 28,
                            color: isCompleted ? ThemeColors.success : ThemeColors.darkBorder,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Milestone details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                m.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                  color: isCompleted
                                      ? (isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary)
                                      : isCurrent
                                          ? ThemeColors.primaryAccent
                                          : ThemeColors.darkTextMuted,
                                ),
                              ),
                              Text(
                                "${m.targetMinutes}m target",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted ? ThemeColors.success : ThemeColors.darkTextMuted,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isCompleted
                                ? "Milestone achieved"
                                : isCurrent
                                    ? "${m.targetMinutes - currentProductiveMinutes}m left to unlock"
                                    : "Upcoming milestone",
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrent
                                  ? ThemeColors.primaryAccent
                                  : (isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          if (!isGoalAchieved) ...[
            const SizedBox(height: ThemeSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ThemeColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusM),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  "Launch ${remainingMinutes > 0 ? (remainingMinutes > 60 ? 45 : remainingMinutes) : 25}m Session to Advance Path",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: onStartRemainingSession,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
