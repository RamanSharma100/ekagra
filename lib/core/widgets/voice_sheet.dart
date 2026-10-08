import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../services/voice_service.dart';
import 'voice_waveform.dart';

class VoiceSheet extends StatefulWidget {
  final VoiceState voiceState;
  final String statusText;
  final String? spokenResponse;
  final VoidCallback onMicTapped;
  final Function(String command)? onCommandSelected;
  final VoidCallback onClose;

  const VoiceSheet({
    super.key,
    required this.voiceState,
    required this.statusText,
    this.spokenResponse,
    required this.onMicTapped,
    this.onCommandSelected,
    required this.onClose,
  });

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  final TextEditingController _textController = TextEditingController();

  static const List<String> _quickCommands = [
    "Start 45 min deep work",
    "How productive was I today?",
    "How much time on YouTube?",
    "Plan my afternoon",
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: ThemeSpacing.l,
        right: ThemeSpacing.l,
        top: ThemeSpacing.m,
        bottom: MediaQuery.of(context).viewInsets.bottom + ThemeSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: ThemeSpacing.m),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.voiceState == VoiceState.listening
                          ? ThemeColors.error
                          : widget.voiceState == VoiceState.speaking
                              ? ThemeColors.success
                              : ThemeColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Ekagra Companion",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? ThemeColors.darkTextPrimary
                          : ThemeColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: widget.onClose,
                color: isDark
                    ? ThemeColors.darkTextSecondary
                    : ThemeColors.lightTextSecondary,
              ),
            ],
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Waveform
          VoiceWaveform(
            state: widget.voiceState,
            height: 52,
            width: 180,
            color: ThemeColors.primaryAccent,
          ),

          const SizedBox(height: ThemeSpacing.m),

          // Status / Spoken text
          Text(
            widget.statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),

          if (widget.spokenResponse != null && widget.spokenResponse!.isNotEmpty) ...[
            const SizedBox(height: ThemeSpacing.m),
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.m),
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightElevatedSurface,
                borderRadius: ThemeRadius.radiusM,
                border: Border.all(
                  color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                ),
              ),
              child: Text(
                widget.spokenResponse!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? ThemeColors.darkTextPrimary
                      : ThemeColors.lightTextPrimary,
                ),
              ),
            ),
          ],

          const SizedBox(height: ThemeSpacing.l),

          // Microphone Action Button
          GestureDetector(
            onTap: widget.onMicTapped,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.voiceState == VoiceState.listening
                    ? ThemeColors.error
                    : ThemeColors.primaryAccent,
                boxShadow: [
                  BoxShadow(
                    color: (widget.voiceState == VoiceState.listening
                            ? ThemeColors.error
                            : ThemeColors.primaryAccent)
                        .withAlpha(80),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.voiceState == VoiceState.listening
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          const SizedBox(height: ThemeSpacing.xs),
          Text(
            widget.voiceState == VoiceState.listening
                ? "Listening... Tap to stop"
                : "Tap to talk",
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? ThemeColors.darkTextMuted
                  : ThemeColors.lightTextMuted,
            ),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Quick Voice Prompt suggestions
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Or try saying:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? ThemeColors.darkTextSecondary
                    : ThemeColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: ThemeSpacing.s),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickCommands.map((cmd) {
              return ActionChip(
                label: Text(
                  cmd,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ThemeColors.darkTextPrimary
                        : ThemeColors.lightTextPrimary,
                  ),
                ),
                backgroundColor: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightElevatedSurface,
                side: BorderSide(
                  color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: ThemeRadius.radiusFull,
                ),
                onPressed: () {
                  if (widget.onCommandSelected != null) {
                    widget.onCommandSelected!(cmd);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
