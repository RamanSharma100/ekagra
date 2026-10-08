import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_spacing.dart';
import 'primary_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.l),
              decoration: BoxDecoration(
                color: (isDark ? ThemeColors.darkSurface : ThemeColors.lightElevatedSurface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: ThemeColors.primaryAccent,
              ),
            ),
            const SizedBox(height: ThemeSpacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ThemeColors.darkTextPrimary
                    : ThemeColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: ThemeSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? ThemeColors.darkTextSecondary
                    : ThemeColors.lightTextSecondary,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: ThemeSpacing.l),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction!,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
