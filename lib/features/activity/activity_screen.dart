import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/activity_timeline_tile.dart';
import '../../data/models/activity.dart';
import 'activity_view_model.dart';
import 'widgets/quick_log_activity_dialog.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activityVm = context.watch<ActivityViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activityVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activities = activityVm.filteredActivities;
    final summaries = activityVm.categorySummaries;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ThemeSpacing.m,
        8,
        ThemeSpacing.m,
        84,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Activity Breakdown",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.xxs),
          Text(
            "Track productive vs distracting time across your daily tools.",
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? ThemeColors.darkTextSecondary
                  : ThemeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.l),

          // High-level visual category bar
          Container(
            padding: const EdgeInsets.all(ThemeSpacing.l),
            decoration: BoxDecoration(
              color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
              borderRadius: ThemeRadius.radiusL,
              border: Border.all(
                color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
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
                      "Distribution",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ThemeColors.darkTextPrimary
                            : ThemeColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      "${activityVm.totalDuration.inHours}h ${activityVm.totalDuration.inMinutes.remainder(60)}m logged",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? ThemeColors.darkTextSecondary
                            : ThemeColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ThemeSpacing.m),

                // Multi-segment horizontal progress bar
                if (summaries.isEmpty)
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                      borderRadius: ThemeRadius.radiusFull,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: ThemeRadius.radiusFull,
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: summaries.map((summary) {
                          return Expanded(
                            flex: (summary.percentage * 1000).toInt(),
                            child: Container(
                              color: summary.category.color,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: ThemeSpacing.m),

                // Legend items
                if (summaries.isEmpty)
                  Text(
                    "No activity recorded today yet. Log an app or start a focus session to see distribution.",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: summaries.map((summary) {
                      final percent = (summary.percentage * 100).toInt();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: summary.category.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${summary.category.displayName} ($percent%)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? ThemeColors.darkTextSecondary
                                  : ThemeColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Category filter pills (Horizontally scrollable for all screen widths)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill(
                  context: context,
                  label: "All",
                  isSelected: activityVm.selectedFilter == null,
                  onTap: () => activityVm.setFilter(null),
                  count: activityVm.activities.length,
                ),
                ...ActivityCategory.values.map((cat) {
                  final isSelected = activityVm.selectedFilter == cat;
                  Color catColor;
                  String prefix;
                  switch (cat) {
                    case ActivityCategory.productive:
                      catColor = const Color(0xFF10B981);
                      prefix = '✦';
                      break;
                    case ActivityCategory.distracting:
                      catColor = const Color(0xFFEF4444);
                      prefix = '⚡';
                      break;
                    case ActivityCategory.neutral:
                      catColor = const Color(0xFF818CF8);
                      prefix = '⚙';
                      break;
                  }
                  final count = activityVm.activities.where((a) => a.category == cat).length;
                  return _buildFilterPill(
                    context: context,
                    label: cat.displayName,
                    isSelected: isSelected,
                    onTap: () => activityVm.setFilter(isSelected ? null : cat),
                    activeColor: catColor,
                    prefixIcon: prefix,
                    count: count,
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: ThemeSpacing.l),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SectionHeader(
                  title: "Logged Applications & Sites",
                  subtitle: "Detailed breakdown of where your time went",
                ),
              ),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (activities.isNotEmpty)
                    IconButton(
                      tooltip: "Clear all activities",
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                      color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Clear All Activities?"),
                            content: const Text("Are you sure you want to delete all logged activities for today?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: ThemeColors.categoryDistracting,
                                ),
                                child: const Text("Clear All"),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await activityVm.clearAllActivities();
                        }
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16, color: ThemeColors.primaryAccent),
                    label: const Text("+ Quick Log", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () => QuickLogActivityDialog.show(context, activityVm),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ThemeSpacing.s),

          if (activities.isEmpty)
            const EmptyState(
              icon: Icons.access_time_rounded,
              title: "No activity recorded yet",
              description:
                  "Start your first focus session or quick-log an app to see your productivity breakdown here.",
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ActivityTimelineTile(
                  activity: activity,
                  onEdit: () => _showEditActivityDialog(context, activity, activityVm),
                  onDelete: () => activityVm.deleteActivity(activity.id),
                );
              },
            ),

          const SizedBox(height: ThemeSpacing.xxl),
        ],
      ),
    );
  }

  void _showEditActivityDialog(BuildContext context, Activity activity, ActivityViewModel activityVm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final descCtrl = TextEditingController(text: activity.description ?? '');
    var selectedCategory = activity.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(activity.icon, color: ThemeColors.primaryAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Organize: ${activity.name}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Work note / Description:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  hintText: "e.g. Watched React course, research, or coding",
                  filled: true,
                  fillColor: isDark ? ThemeColors.darkSurface : ThemeColors.lightBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Classify Attention:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ActivityCategory.values.map((cat) {
                  final isSelected = selectedCategory == cat;
                  Color catColor;
                  String prefix;
                  switch (cat) {
                    case ActivityCategory.productive:
                      catColor = const Color(0xFF10B981);
                      prefix = '✦';
                      break;
                    case ActivityCategory.distracting:
                      catColor = const Color(0xFFEF4444);
                      prefix = '⚡';
                      break;
                    case ActivityCategory.neutral:
                      catColor = const Color(0xFF818CF8);
                      prefix = '⚙';
                      break;
                  }
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setModalState(() {
                          selectedCategory = cat;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withAlpha(isDark ? 40 : 30)
                              : (isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? catColor.withAlpha(isDark ? 180 : 140)
                                : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: catColor.withAlpha(isDark ? 35 : 20),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prefix,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? catColor
                                    : (isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cat.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? Colors.white : catColor)
                                    : (isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final updated = activity.copyWith(
                      description: descCtrl.text.trim(),
                      category: selectedCategory,
                    );
                    activityVm.updateActivity(updated);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Save & Update Timeline"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
    String? prefixIcon,
    int? count,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? ThemeColors.primaryAccent;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withAlpha(isDark ? 35 : 25)
                  : (isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? color.withAlpha(isDark ? 160 : 120)
                    : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withAlpha(isDark ? 30 : 15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prefixIcon != null) ...[
                  Text(
                    prefixIcon,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? color
                          : (isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : color)
                        : (isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary),
                  ),
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(45)
                          : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? color
                            : (isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
