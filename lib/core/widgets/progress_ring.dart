import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Widget? centerChild;
  final Color? progressColor;
  final Color? trackColor;
  final List<Color>? gradientColors;
  final bool animate;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 180,
    this.strokeWidth = 14,
    this.centerChild,
    this.progressColor,
    this.trackColor,
    this.gradientColors,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveProgressColor = progressColor ?? ThemeColors.primaryAccent;
    final effectiveTrackColor = trackColor ??
        (isDark ? ThemeColors.darkBorderSubtle.withAlpha(90) : ThemeColors.lightBorder);

    final effectiveGradients = gradientColors ??
        [
          effectiveProgressColor,
          effectiveProgressColor.withAlpha(210),
        ];

    Widget buildRing(double animatedProgress) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: animatedProgress.clamp(0.0, 1.0),
                strokeWidth: strokeWidth,
                progressColor: effectiveProgressColor,
                trackColor: effectiveTrackColor,
                gradientColors: effectiveGradients,
              ),
            ),
            ?centerChild,
          ],
        ),
      );
    }

    if (!animate) {
      return buildRing(progress);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) => buildRing(val),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;
  final List<Color> gradientColors;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Sweep
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      // Soft glow pass underneath
      final glowPaint = Paint()
        ..color = (gradientColors.isNotEmpty ? gradientColors.first : progressColor).withAlpha(45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

      // Gradient arc
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (gradientColors.length >= 2) {
        progressPaint.shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: gradientColors,
          transform: GradientRotation(startAngle),
        ).createShader(rect);
      } else {
        progressPaint.color = progressColor;
      }

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
