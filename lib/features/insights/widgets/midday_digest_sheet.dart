import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/theme/theme_radius.dart';
import '../../../app/theme/theme_spacing.dart';
import '../../../core/services/app_blocker_service.dart';
import '../../../data/models/midday_digest.dart';

class MiddayDigestSheet extends StatelessWidget {
  final MiddayDigest digest;

  const MiddayDigestSheet({
    super.key,
    required this.digest,
  });

  static Future<void> show(BuildContext context, MiddayDigest digest) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => MiddayDigestSheet(digest: digest),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockerService = context.watch<AppBlockerService>();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.l),
        child: ListView(
          controller: scrollController,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeColors.primaryAccentSubtle,
                        borderRadius: ThemeRadius.radiusSm,
                      ),
                      child: const Icon(Icons.analytics_rounded, color: ThemeColors.primaryAccent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "12 PM Midday Focus Digest",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          "6-Hour Interval Activity & Attention Analysis",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: ThemeSpacing.l),

            // Score & Total Time Card
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.m),
              decoration: BoxDecoration(
                color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
                borderRadius: ThemeRadius.radiusM,
                border: Border.all(color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCol(
                        label: "Logged Time",
                        value: digest.formattedTotalTime,
                        color: ThemeColors.primaryAccent,
                        isDark: isDark,
                      ),
                      Container(width: 1, height: 36, color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                      _StatCol(
                        label: "Productive",
                        value: "${digest.productiveMinutes}m",
                        color: ThemeColors.categoryProductive,
                        isDark: isDark,
                      ),
                      Container(width: 1, height: 36, color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                      _StatCol(
                        label: "Distracted",
                        value: "${digest.distractedMinutes}m",
                        color: ThemeColors.categoryDistracting,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Linear Distribution Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (digest.productiveMinutes > 0)
                            Expanded(
                              flex: digest.productiveMinutes,
                              child: Container(color: ThemeColors.categoryProductive),
                            ),
                          if (digest.neutralMinutes > 0)
                            Expanded(
                              flex: digest.neutralMinutes,
                              child: Container(color: ThemeColors.categoryNeutral),
                            ),
                          if (digest.distractedMinutes > 0)
                            Expanded(
                              flex: digest.distractedMinutes,
                              child: Container(color: ThemeColors.categoryDistracting),
                            ),
                          if (digest.totalMinutes <= 0)
                            Expanded(
                              child: Container(color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeSpacing.l),

            // AI Behavioral Advice Callout
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.m),
              decoration: BoxDecoration(
                color: ThemeColors.primaryAccentSubtle.withAlpha(25),
                borderRadius: ThemeRadius.radiusM,
                border: Border.all(color: ThemeColors.primaryAccent.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: ThemeColors.primaryAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          digest.headline,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          digest.recommendation,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeSpacing.l),

            // Top Time-Consuming Applications Leaderboard
            Text(
              "Top Time-Consuming Applications",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Ranked breakdown of where attention was invested in this 6-hour cycle.",
              style: TextStyle(fontSize: 12, color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
            ),
            const SizedBox(height: 12),

            if (digest.topApps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No heavy application consumption recorded.",
                    style: TextStyle(color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: digest.topApps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = digest.topApps[index];
                  final isTop1 = index == 0;
                  final isShielded = blockerService.isAppBlocked(item.packageName);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
                      borderRadius: ThemeRadius.radiusM,
                      border: Border.all(
                        color: isTop1
                            ? ThemeColors.primaryAccent.withAlpha(80)
                            : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank chip
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isTop1
                                ? ThemeColors.primaryAccent
                                : (isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightElevatedSurface),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "#${index + 1}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isTop1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(item.icon, size: 20, color: ThemeColors.primaryAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.appName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: item.category.contains('Distracting')
                                          ? ThemeColors.errorSubtle
                                          : ThemeColors.successSubtle,
                                      borderRadius: ThemeRadius.radiusFull,
                                    ),
                                    child: Text(
                                      item.category,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: item.category.contains('Distracting')
                                            ? ThemeColors.error
                                            : ThemeColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: (item.percentage / 100).clamp(0.02, 1.0),
                                        minHeight: 4,
                                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                        valueColor: AlwaysStoppedAnimation(
                                          item.category.contains('Distracting')
                                              ? ThemeColors.error
                                              : ThemeColors.primaryAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${item.percentage.round()}% of screen time",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.formattedDuration,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                              ),
                            ),
                            // Quick Shield Toggle
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isShielded ? "Shielded" : "Shield",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isShielded ? ThemeColors.error : ThemeColors.darkTextMuted,
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isShielded,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  activeTrackColor: ThemeColors.error,
                                  onChanged: (val) {
                                    blockerService.toggleAppBlock(item.packageName, val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.shield_rounded, size: 18),
                label: const Text("Arm App Shield & Close"),
                onPressed: () {
                  blockerService.setShieldActive(true);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCol({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
