import 'package:flutter/material.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/theme/theme_radius.dart';
import '../../../app/theme/theme_spacing.dart';

class GoalStatusAlertBanner extends StatelessWidget {
  final int productiveMinutes;
  final int goalMinutes;
  final int distractedMinutes;
  final VoidCallback onStartSession;
  final VoidCallback onOpenShield;

  const GoalStatusAlertBanner({
    super.key,
    required this.productiveMinutes,
    required this.goalMinutes,
    required this.distractedMinutes,
    required this.onStartSession,
    required this.onOpenShield,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = (goalMinutes - productiveMinutes).clamp(0, goalMinutes);
    final isAchieved = productiveMinutes >= goalMinutes;

    Color bannerColor;
    Color iconColor;
    IconData iconData;
    String alertTitle;
    String alertMessage;
    String actionLabel;
    VoidCallback actionCallback;

    if (isAchieved) {
      bannerColor = ThemeColors.successSubtle;
      iconColor = ThemeColors.success;
      iconData = Icons.verified_rounded;
      alertTitle = "Daily Target Accomplished!";
      alertMessage = "You've completed $productiveMinutes mins of focus today. Flow momentum is at peak.";
      actionLabel = "Log Wind-down";
      actionCallback = onStartSession;
    } else if (distractedMinutes > 30) {
      bannerColor = ThemeColors.warningSubtle;
      iconColor = ThemeColors.warning;
      iconData = Icons.shield_outlined;
      alertTitle = "Focus Shield Alert: $distractedMinutes min Distracted";
      alertMessage = "Social & media apps are competing for your attention. Arm the App Shield to block them during your next sprint.";
      actionLabel = "Arm App Shield";
      actionCallback = onOpenShield;
    } else if (productiveMinutes == 0) {
      bannerColor = ThemeColors.primaryAccentSubtle;
      iconColor = ThemeColors.primaryAccent;
      iconData = Icons.flag_outlined;
      final goalHours = (goalMinutes / 60).toStringAsFixed(goalMinutes % 60 == 0 ? 0 : 1);
      alertTitle = "Daily Focus Target: ${goalHours}h";
      alertMessage = "Ready to start today's focus? Launch a sprint to build momentum.";
      actionLabel = "Start Sprint (25m)";
      actionCallback = onStartSession;
    } else {
      bannerColor = ThemeColors.primaryAccentSubtle;
      iconColor = ThemeColors.primaryAccent;
      iconData = Icons.track_changes_rounded;
      final goalHours = (goalMinutes / 60).toStringAsFixed(goalMinutes % 60 == 0 ? 0 : 1);
      alertTitle = "Goal Alert: $remaining mins to ${goalHours}h Goal";
      alertMessage = "You are on track! A ${remaining > 45 ? 45 : remaining}m focus session will advance you to 100% of today's target.";
      actionLabel = "Start Session (${remaining > 45 ? 45 : remaining}m)";
      actionCallback = onStartSession;
    }

    return Container(
      padding: const EdgeInsets.all(ThemeSpacing.m),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: ThemeRadius.radiusL,
        border: Border.all(color: iconColor.withAlpha(80), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alertTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alertMessage,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.m),
          Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusFull),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: actionCallback,
              ),
              const SizedBox(width: 8),
              if (!isAchieved && distractedMinutes <= 30)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusFull),
                  ),
                  icon: const Icon(Icons.shield_rounded, size: 14),
                  label: const Text("App Shield", style: TextStyle(fontSize: 12)),
                  onPressed: onOpenShield,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
