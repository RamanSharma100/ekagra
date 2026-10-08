import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/theme/theme_radius.dart';
import '../../../app/theme/theme_spacing.dart';
import '../../../data/models/midday_digest.dart';
import '../insights_view_model.dart';
import 'midday_digest_sheet.dart';

class MiddayDigestCard extends StatelessWidget {
  final MiddayDigest digest;

  const MiddayDigestCard({
    super.key,
    required this.digest,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insightsVm = context.read<InsightsViewModel>();
    final topApp = digest.mostTimeConsumingApp;

    return Container(
      padding: const EdgeInsets.all(ThemeSpacing.l),
      decoration: BoxDecoration(
        color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
        borderRadius: ThemeRadius.radiusL,
        border: Border.all(
          color: ThemeColors.primaryAccent.withAlpha(60),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.primaryAccent.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryAccentSubtle,
                      borderRadius: ThemeRadius.radiusFull,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: ThemeColors.primaryAccent),
                        SizedBox(width: 4),
                        Text(
                          "12:00 PM MIDDAY DIGEST",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ThemeColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ThemeColors.successSubtle,
                      borderRadius: ThemeRadius.radiusFull,
                    ),
                    child: const Text(
                      "6-HOUR FLOW",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ThemeColors.success),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined, size: 20),
                tooltip: "Send 12 PM Alert (Test Notification)",
                color: ThemeColors.primaryAccent,
                onPressed: () async {
                  await insightsVm.sendTestMiddayNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🔔 12:00 PM Focus Digest notification sent to notification panel!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: ThemeSpacing.m),

          // Main Title
          Text(
            "Midday Activity & Time Sink Analysis",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            digest.headline,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: ThemeSpacing.m),

          // Highlight: Top Time Consumer Callout
          if (topApp != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightElevatedSurface,
                borderRadius: ThemeRadius.radiusM,
                border: Border.all(
                  color: topApp.category.contains('Distracting')
                      ? ThemeColors.error.withAlpha(60)
                      : ThemeColors.primaryAccent.withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: topApp.category.contains('Distracting')
                          ? ThemeColors.errorSubtle
                          : ThemeColors.primaryAccentSubtle,
                      borderRadius: ThemeRadius.radiusSm,
                    ),
                    child: Icon(
                      topApp.icon,
                      size: 20,
                      color: topApp.category.contains('Distracting')
                          ? ThemeColors.error
                          : ThemeColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "#1 Time Sink: ",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                              ),
                            ),
                            Text(
                              topApp.appName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${topApp.formattedDuration} spent (${topApp.percentage.round()}% of screen time)",
                          style: TextStyle(
                            fontSize: 11,
                            color: topApp.category.contains('Distracting')
                                ? ThemeColors.error
                                : ThemeColors.categoryProductive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: topApp.category.contains('Distracting')
                          ? ThemeColors.errorSubtle
                          : ThemeColors.successSubtle,
                      borderRadius: ThemeRadius.radiusFull,
                    ),
                    child: Text(
                      topApp.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: topApp.category.contains('Distracting')
                            ? ThemeColors.error
                            : ThemeColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: ThemeSpacing.m),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusM),
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: const Text("View 6h Dashboard", style: TextStyle(fontSize: 13)),
                  onPressed: () => MiddayDigestSheet.show(context, digest),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusM),
                ),
                icon: const Icon(Icons.notifications_outlined, size: 16),
                label: const Text("Test Alert", style: TextStyle(fontSize: 13)),
                onPressed: () async {
                  await insightsVm.sendTestMiddayNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🔔 12 PM Focus Digest sent to notification panel!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
