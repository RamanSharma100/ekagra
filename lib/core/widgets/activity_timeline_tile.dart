import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/services/app_blocker_service.dart';
import '../../data/models/activity.dart';

class ActivityTimelineTile extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ActivityTimelineTile({
    super.key,
    required this.activity,
    this.onDelete,
    this.onEdit,
  });

  Color _getCategoryColor(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.productive:
        return const Color(0xFF10B981); // Emerald
      case ActivityCategory.distracting:
        return const Color(0xFFEF4444); // Crimson/Coral
      case ActivityCategory.neutral:
        return const Color(0xFF818CF8); // Indigo
    }
  }

  String _getCategoryPrefix(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.productive:
        return '✦';
      case ActivityCategory.distracting:
        return '⚡';
      case ActivityCategory.neutral:
        return '⚙';
    }
  }

  void _showCategoryPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockerService = context.read<AppBlockerService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.l, vertical: ThemeSpacing.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(activity.icon, color: _getCategoryColor(activity.category), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Categorize \"${activity.name}\"",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Choose how Ekagra counts time spent in this application toward your focus goals:",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Category selection tiles
                ...ActivityCategory.values.map((cat) {
                  final isSelected = activity.category == cat;
                  final catColor = _getCategoryColor(cat);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: ThemeRadius.radiusM,
                      onTap: () {
                        blockerService.updateActivityCategory(activity, cat);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Categorized ${activity.name} as ${cat.displayName}"),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withAlpha(25)
                              : (isDark ? ThemeColors.darkSurface : ThemeColors.lightElevatedSurface),
                          borderRadius: ThemeRadius.radiusM,
                          border: Border.all(
                            color: isSelected ? catColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: catColor.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _getCategoryPrefix(cat),
                                style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.displayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? catColor
                                          : (isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary),
                                    ),
                                  ),
                                  Text(
                                    cat == ActivityCategory.productive
                                        ? "Counts toward daily focus goals and flow score"
                                        : cat == ActivityCategory.distracting
                                            ? "Reduces focus score and triggers shield protection"
                                            : "System tasks, utilities, and background tools",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: catColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(activity.category);
    final timeStr = DateFormat('hh:mm a').format(activity.timestamp);
    final displayCategory = activity.subcategory != null && activity.subcategory!.isNotEmpty
        ? activity.subcategory!
        : activity.category.displayName;

    return InkWell(
      onTap: onEdit,
      borderRadius: ThemeRadius.radiusM,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
          borderRadius: ThemeRadius.radiusM,
          border: Border.all(
            color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Container with Category Tint
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: catColor.withAlpha(25),
                borderRadius: ThemeRadius.radiusSm,
                border: Border.all(
                  color: catColor.withAlpha(60),
                  width: 1,
                ),
              ),
              child: Icon(
                activity.icon,
                size: 20,
                color: catColor,
              ),
            ),
            const SizedBox(width: 12),

            // Content Stack
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Line: Full App Name + Duration + Delete
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activity.formattedDuration,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                        ),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onDelete,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Bottom Line: Category Pill + Description / Timestamp
                  Row(
                    children: [
                      // Tappable Category Badge Pill
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showCategoryPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: catColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: catColor.withAlpha(90),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getCategoryPrefix(activity.category),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: catColor,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                displayCategory,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: catColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Description / Timestamp
                      Expanded(
                        child: Text(
                          activity.description != null && activity.description!.isNotEmpty
                              ? "${activity.description!} • $timeStr"
                              : timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
