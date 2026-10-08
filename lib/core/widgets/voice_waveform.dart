import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';
import '../services/voice_service.dart';

class VoiceWaveform extends StatefulWidget {
  final VoiceState state;
  final double height;
  final double width;
  final Color? color;

  const VoiceWaveform({
    super.key,
    required this.state,
    this.height = 48,
    this.width = 160,
    this.color,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == VoiceState.idle) {
      if (_controller.isAnimating) _controller.stop();
    } else {
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? ThemeColors.primaryAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _WaveformPainter(
            animationValue: _controller.value,
            state: widget.state,
            color: effectiveColor,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double animationValue;
  final VoiceState state;
  final Color color;

  _WaveformPainter({
    required this.animationValue,
    required this.state,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 18;
    final barWidth = size.width / (barCount * 1.8);
    final spacing = (size.width - (barCount * barWidth)) / (barCount - 1);

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      double heightFactor;

      if (state == VoiceState.idle) {
        heightFactor = 0.15;
      } else if (state == VoiceState.listening) {
        // Pulsing gentle wave
        final phase = (i / barCount) * 2 * math.pi;
        heightFactor = 0.2 + 0.6 * math.sin(animationValue * 2 * math.pi + phase).abs();
      } else if (state == VoiceState.processing) {
        // Smooth sine ripple
        final phase = (i / barCount) * 3 * math.pi;
        heightFactor = 0.25 + 0.45 * (math.sin(animationValue * 4 * math.pi + phase) * 0.5 + 0.5);
      } else {
        // Speaking: energetic dynamic speech bars
        final harmonic = math.sin((animationValue * 6 * math.pi) + (i * 0.6));
        final subHarmonic = math.cos((animationValue * 3 * math.pi) + (i * 0.3));
        heightFactor = 0.25 + 0.7 * ((harmonic + subHarmonic).abs() / 2);
      }

      final barHeight = (size.height * heightFactor).clamp(6.0, size.height);
      final left = i * (barWidth + spacing);
      final top = (size.height - barHeight) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.state != state ||
        oldDelegate.color != color;
  }
}
