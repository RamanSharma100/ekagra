import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? accentColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.accentColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ThemeRadius.radiusL,
        child: Container(
          padding: const EdgeInsets.all(ThemeSpacing.m),
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
                  Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (iconColor ?? ThemeColors.primaryAccent).withAlpha(35),
                            borderRadius: ThemeRadius.radiusSm,
                          ),
                          child: Icon(
                            icon,
                            size: 16,
                            color: iconColor ?? ThemeColors.primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
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
                  ?trailing,
                ],
              ),
              const SizedBox(height: ThemeSpacing.sm),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark
                      ? ThemeColors.darkTextPrimary
                      : ThemeColors.lightTextPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: ThemeSpacing.xxs),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ThemeColors.darkTextMuted
                        : ThemeColors.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
