import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/theme/theme_radius.dart';
import '../../../app/theme/theme_spacing.dart';

class FocusShieldOverlay extends StatefulWidget {
  final String appName;
  final IconData appIcon;
  final int remainingSeconds;
  final VoidCallback onReturnToFocus;

  const FocusShieldOverlay({
    super.key,
    required this.appName,
    required this.appIcon,
    required this.remainingSeconds,
    required this.onReturnToFocus,
  });

  static Future<void> show({
    required BuildContext context,
    required String appName,
    required IconData appIcon,
    required int remainingSeconds,
    required VoidCallback onReturnToFocus,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(220),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => FocusShieldOverlay(
        appName: appName,
        appIcon: appIcon,
        remainingSeconds: remainingSeconds,
        onReturnToFocus: onReturnToFocus,
      ),
    );
  }

  @override
  State<FocusShieldOverlay> createState() => _FocusShieldOverlayState();
}

class _FocusShieldOverlayState extends State<FocusShieldOverlay> {
  int _graceSeconds = 60;
  bool _graceActive = false;
  Timer? _graceTimer;

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  void _startGracePass() {
    setState(() {
      _graceActive = true;
      _graceSeconds = 60;
    });

    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_graceSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _graceActive = false);
        }
      } else {
        if (mounted) {
          setState(() => _graceSeconds--);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mins = widget.remainingSeconds ~/ 60;
    final secs = widget.remainingSeconds % 60;
    final timeStr = "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.l, vertical: ThemeSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shield Icon with pulsing aura
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColors.primaryAccentSubtle,
                  border: Border.all(color: ThemeColors.primaryAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.primaryAccent.withAlpha(80),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_rounded,
                    size: 48,
                    color: ThemeColors.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(height: ThemeSpacing.l),

              // Title & App Name
              Text(
                "Focus Shield Engaged",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeColors.errorSubtle,
                  borderRadius: ThemeRadius.radiusFull,
                  border: Border.all(color: ThemeColors.error.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.appIcon, size: 16, color: ThemeColors.error),
                    const SizedBox(width: 8),
                    Text(
                      "${widget.appName} is currently restricted",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ThemeSpacing.l),

              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: ThemeColors.darkSurface,
                  borderRadius: ThemeRadius.radiusL,
                  border: Border.all(color: ThemeColors.darkBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: ThemeColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "REMAINING IN FOCUS SESSION",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: ThemeColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ThemeSpacing.m),

              // Supportive AI Guidance text
              Text(
                "You are in deep flow. Protect your attention from quick impulses.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeColors.darkTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: ThemeSpacing.xl),

              // Primary Action: Return to Focus
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ThemeColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusM),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text(
                    "Return to Focus Session",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onReturnToFocus();
                  },
                ),
              ),
              const SizedBox(height: ThemeSpacing.m),

              // Emergency Pass Option with Friction
              if (_graceActive)
                Text(
                  "Emergency pass active: ${_graceSeconds}s remaining",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.warning,
                  ),
                )
              else
                TextButton(
                  onPressed: _startGracePass,
                  child: const Text(
                    "Need 60s emergency access?",
                    style: TextStyle(
                      fontSize: 13,
                      color: ThemeColors.darkTextMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
