import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_shell.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../goals/goals_screen.dart';
import 'insights_view_model.dart';
import 'widgets/midday_digest_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  void _handleInsightAction(BuildContext context, String? actionType) {
    if (actionType == null) return;
    switch (actionType) {
      case 'start_focus':
        AppShell.switchTab(context, 1); // Switch to Focus tab
        break;
      case 'view_activity':
        AppShell.switchTab(context, 2); // Switch to Activity tab
        break;
      case 'view_goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoalsScreen()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final insightsVm = context.watch<InsightsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (insightsVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final insights = insightsVm.insights;
    final summary = insightsVm.timeframeSummary;

    return RefreshIndicator(
      onRefresh: () => insightsVm.loadInsights(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
          ThemeSpacing.m,
          8,
          ThemeSpacing.m,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title & Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Productivity Insights",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark
                              ? ThemeColors.darkTextPrimary
                              : ThemeColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Actionable behavioral patterns detected by your calm AI companion.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? ThemeColors.darkTextSecondary
                              : ThemeColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => AppShell.switchTab(context, 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: insightsVm.hasGeminiKey
                                ? const Color(0xFF6366F1).withAlpha(30)
                                : (isDark ? Colors.white10 : Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: insightsVm.hasGeminiKey
                                  ? const Color(0xFF6366F1).withAlpha(120)
                                  : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: insightsVm.hasGeminiKey
                                    ? const Color(0xFF6366F1)
                                    : ThemeColors.primaryAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                insightsVm.hasGeminiKey
                                    ? "Google Gemini 1.5 Flash Active"
                                    : "Grounded On-Device Cognitive Engine",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: insightsVm.hasGeminiKey
                                      ? const Color(0xFF818CF8)
                                      : (isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Refresh Insights",
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => insightsVm.loadInsights(),
                ),
              ],
            ),
            const SizedBox(height: ThemeSpacing.m),

            // Timeframe Segmented Switcher (Daily / Weekly / Monthly)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightElevatedSurface,
                borderRadius: ThemeRadius.radiusM,
                border: Border.all(
                  color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                ),
              ),
              child: Row(
                children: InsightTimeframe.values.map((timeframe) {
                  final isSelected = insightsVm.selectedTimeframe == timeframe;
                  return Expanded(
                    child: InkWell(
                      onTap: () => insightsVm.selectTimeframe(timeframe),
                      borderRadius: ThemeRadius.radiusSm,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? ThemeColors.darkElevatedSurface
                                  : ThemeColors.lightSurface)
                              : Colors.transparent,
                          borderRadius: ThemeRadius.radiusSm,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          timeframe.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? ThemeColors.primaryAccent
                                : (isDark
                                    ? ThemeColors.darkTextSecondary
                                    : ThemeColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: ThemeSpacing.l),

            // Dynamic Executive Summary Hero Card
            if (summary != null)
              _buildExecutiveSummaryCard(context, summary, isDark),

            const SizedBox(height: ThemeSpacing.l),

            // 12:00 PM Midday Focus Digest & 6-Hour Analysis Card
            if (insightsVm.selectedTimeframe == InsightTimeframe.daily &&
                insightsVm.middayDigest != null) ...[
              MiddayDigestCard(digest: insightsVm.middayDigest!),
              const SizedBox(height: ThemeSpacing.l),
            ],

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${insightsVm.selectedTimeframe.displayName} Cognitive Breakdown",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? ThemeColors.darkTextPrimary
                        : ThemeColors.lightTextPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: ThemeColors.primaryAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${insights.length} Pattern${insights.length == 1 ? '' : 's'} Active",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: ThemeSpacing.m),

            // Dynamic AI Insight Cards List
            if (insights.isEmpty)
              const EmptyState(
                icon: Icons.lightbulb_outline_rounded,
                title: "Calibrating behavioral model...",
                description:
                    "As you complete focus sessions and use apps, your calm AI companion will dynamically reveal personalized cognitive flow windows.",
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: insights.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final insight = insights[index];
                  final accent = insight.accentColor ?? ThemeColors.primaryAccent;

                  return Container(
                    padding: const EdgeInsets.all(ThemeSpacing.l),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 8),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Top Header (Icon + Badge + AI spark)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accent.withAlpha(25),
                                    borderRadius: ThemeRadius.radiusSm,
                                    border: Border.all(
                                      color: accent.withAlpha(60),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    insight.icon,
                                    size: 18,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: ThemeSpacing.s),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withAlpha(20),
                                    borderRadius: ThemeRadius.radiusFull,
                                    border: Border.all(
                                      color: accent.withAlpha(60),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    insight.metricHighlight,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (insight.isAiGenerated)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: ThemeColors.primaryAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "AI Pattern",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? ThemeColors.darkTextMuted
                                          : ThemeColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        const SizedBox(height: ThemeSpacing.m),

                        // Headline
                        Text(
                          insight.headline,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark
                                ? ThemeColors.darkTextPrimary
                                : ThemeColors.lightTextPrimary,
                          ),
                        ),

                        const SizedBox(height: ThemeSpacing.xs),

                        // Description
                        Text(
                          insight.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark
                                ? ThemeColors.darkTextSecondary
                                : ThemeColors.lightTextSecondary,
                            height: 1.45,
                          ),
                        ),

                        // Interactive Action Button
                        if (insight.actionLabel != null) ...[
                          const SizedBox(height: ThemeSpacing.m),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                side: BorderSide(
                                  color: accent.withAlpha(80),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: accent.withAlpha(12),
                              ),
                              onPressed: () => _handleInsightAction(
                                context,
                                insight.actionType,
                              ),
                              icon: Icon(
                                Icons.arrow_outward_rounded,
                                size: 16,
                                color: accent,
                              ),
                              label: Text(
                                insight.actionLabel!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: ThemeSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXECUTIVE HERO SUMMARY CARD W/ INTERACTIVE BAR CHART
  // ---------------------------------------------------------------------------
  Widget _buildExecutiveSummaryCard(
    BuildContext context,
    TimeframeSummary summary,
    bool isDark,
  ) {
    final maxMins = summary.chartBars.fold<int>(
      1,
      (acc, bar) => (bar.productiveMinutes + bar.distractedMinutes) > acc
          ? (bar.productiveMinutes + bar.distractedMinutes)
          : acc,
    );

    return Container(
      padding: const EdgeInsets.all(ThemeSpacing.l),
      decoration: BoxDecoration(
        color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
        borderRadius: ThemeRadius.radiusL,
        border: Border.all(
          color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? ThemeColors.darkTextPrimary
                            : ThemeColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ThemeColors.darkTextMuted
                            : ThemeColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ThemeColors.primaryAccentSubtle,
                  borderRadius: ThemeRadius.radiusFull,
                ),
                child: Text(
                  summary.efficiencyRatio,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Key Metrics Triple Grid
          Row(
            children: [
              _buildStatPill(
                label: "Focus Time",
                value: summary.formattedFocus,
                icon: Icons.timer_rounded,
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              const SizedBox(width: ThemeSpacing.s),
              _buildStatPill(
                label: "Interceptions",
                value: "${summary.blockedAttempts} Deflected",
                icon: Icons.shield_rounded,
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
              const SizedBox(width: ThemeSpacing.s),
              _buildStatPill(
                label: "Flow Score",
                value: "${summary.flowScore}/100",
                icon: Icons.electric_bolt_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Target Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Target Goal: ${summary.formattedGoal}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ThemeColors.darkTextSecondary
                      : ThemeColors.lightTextSecondary,
                ),
              ),
              Text(
                "${(summary.goalProgress * 100).toInt()}% Achieved",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.goalProgress,
              minHeight: 7,
              backgroundColor: isDark
                  ? ThemeColors.darkBorder
                  : ThemeColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ThemeColors.primaryAccent,
              ),
            ),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Flow Distribution Interactive Bar Chart
          Text(
            "Flow Distribution & Intensity",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ThemeColors.darkTextSecondary
                  : ThemeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            height: 110,
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summary.chartBars.map((bar) {
                final totalBarMins = bar.productiveMinutes + bar.distractedMinutes;
                final heightFactor = maxMins > 0 ? (totalBarMins / maxMins).clamp(0.08, 1.0) : 0.08;
                final prodRatio = totalBarMins > 0 ? bar.productiveMinutes / totalBarMins : 1.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Minute tooltip text
                        Text(
                          totalBarMins > 0 ? '${totalBarMins}m' : '-',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: bar.isHighlight
                                ? ThemeColors.primaryAccent
                                : (isDark
                                    ? ThemeColors.darkTextMuted
                                    : ThemeColors.lightTextMuted),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Visual Bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: heightFactor,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: bar.isHighlight
                                        ? [
                                            const Color(0xFF6366F1),
                                            const Color(0xFF8B5CF6),
                                          ]
                                        : [
                                            prodRatio >= 0.5
                                                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1))
                                                : const Color(0xFFEF4444).withAlpha(120),
                                            bar.productiveMinutes > 0
                                                ? ThemeColors.primaryAccent.withAlpha(isDark ? 160 : 200)
                                                : (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                                          ],
                                  ),
                                  border: bar.isHighlight
                                      ? Border.all(
                                          color: Colors.white.withAlpha(120),
                                          width: 1.2,
                                        )
                                      : null,
                                  boxShadow: bar.isHighlight
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1).withAlpha(100),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Label
                        Text(
                          bar.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: bar.isHighlight ? FontWeight.w700 : FontWeight.w500,
                            color: bar.isHighlight
                                ? ThemeColors.primaryAccent
                                : (isDark
                                    ? ThemeColors.darkTextMuted
                                    : ThemeColors.lightTextMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? ThemeColors.darkElevatedSurface
              : ThemeColors.lightElevatedSurface,
          borderRadius: ThemeRadius.radiusM,
          border: Border.all(
            color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ThemeColors.darkTextMuted
                        : ThemeColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? ThemeColors.darkTextPrimary
                    : ThemeColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
