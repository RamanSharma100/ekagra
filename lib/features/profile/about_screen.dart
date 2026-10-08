import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About Ekagra"),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: ThemeSpacing.m),
            // App Logo Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ThemeColors.primaryAccent, ThemeColors.categoryProductive],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: ThemeRadius.radiusL,
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.primaryAccent.withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.spa_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: ThemeSpacing.m),
            Text(
              "Ekagra",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Version 1.0.0 • Build 2026.10",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.primaryAccentSubtle,
                borderRadius: ThemeRadius.radiusFull,
              ),
              child: const Text(
                "Calm AI Focus Companion",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.primaryAccent,
                ),
              ),
            ),
            const SizedBox(height: ThemeSpacing.xl),

            // Card 1: Vision & Principles
            _InfoSection(
              title: "Product Vision",
              icon: Icons.lightbulb_outline_rounded,
              content:
                  "Ekagra (एकाग्र — One-pointed focus) is designed to help engineers, creators, and students achieve deep flow states through calm AI reflection, minimal distraction, and voice-assisted productivity.",
            ),
            const SizedBox(height: ThemeSpacing.m),

            // Card 2: Privacy Guarantee
            _InfoSection(
              title: "Privacy-First Architecture",
              icon: Icons.shield_outlined,
              content:
                  "• 100% on-device local storage for focus sessions and metrics.\n• Zero behavioral ad-tracking or keystroke logging.\n• On-device speech recognition when supported by your platform.\n• Full user ownership: export or purge your data anytime.",
            ),
            const SizedBox(height: ThemeSpacing.m),

            // Card 3: Open Source & Standards
            _InfoSection(
              title: "Open Source & Licensing",
              icon: Icons.code_rounded,
              content:
                  "Ekagra is open-source software licensed under the MIT License.\nBuilt adhering to Google Open Source Guidelines, Material 3 design specifications, and clean Flutter reactive state architecture.",
            ),
            const SizedBox(height: ThemeSpacing.m),

            // Card 4: Technical Stack
            _InfoSection(
              title: "Technology Stack",
              icon: Icons.layers_outlined,
              content:
                  "• Flutter 3.47 / Dart 3.13\n• Provider Reactive State Management\n• Flutter TTS & Speech Recognition Pipeline\n• Clean Domain-Driven Architecture",
            ),
            const SizedBox(height: ThemeSpacing.l),

            // Legal & Credits Footer
            Text(
              "Designed with care for peaceful human attention.\n© 2026 Ekagra Open Source Community",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: ThemeSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ThemeSpacing.m),
      decoration: BoxDecoration(
        color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
        borderRadius: ThemeRadius.radiusM,
        border: Border.all(
          color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ThemeColors.primaryAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeSpacing.s),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
