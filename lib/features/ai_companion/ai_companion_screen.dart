import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/services/voice_service.dart';
import '../../core/widgets/voice_waveform.dart';
import 'ai_companion_view_model.dart';

class AiCompanionScreen extends StatefulWidget {
  const AiCompanionScreen({super.key});

  @override
  State<AiCompanionScreen> createState() => _AiCompanionScreenState();
}

class _AiCompanionScreenState extends State<AiCompanionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(AiCompanionViewModel vm) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    vm.sendTextMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiCompanionViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? ThemeColors.darkBackground
          : ThemeColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ThemeColors.primaryAccentSubtle,
                borderRadius: ThemeRadius.radiusSm,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: ThemeColors.primaryAccent,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Ekagra Companion",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (vm.voiceState == VoiceState.speaking)
            IconButton(
              icon: const Icon(Icons.volume_off_rounded),
              tooltip: "Stop speaking",
              onPressed: () => vm.stopSpeaking(),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ambient voice status banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeSpacing.m,
                vertical: ThemeSpacing.s,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? ThemeColors.darkBorderSubtle
                        : ThemeColors.lightBorderSubtle,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: vm.voiceState == VoiceState.listening
                              ? ThemeColors.error
                              : vm.voiceState == VoiceState.speaking
                                  ? ThemeColors.success
                                  : ThemeColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vm.currentStatusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? ThemeColors.darkTextSecondary
                              : ThemeColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  VoiceWaveform(
                    state: vm.voiceState,
                    height: 24,
                    width: 72,
                    color: vm.voiceState == VoiceState.listening
                        ? ThemeColors.error
                        : ThemeColors.primaryAccent,
                  ),
                ],
              ),
            ),

            // Messages chat list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(ThemeSpacing.m),
                itemCount: vm.messages.length,
                itemBuilder: (context, index) {
                  final msg = vm.messages[index];
                  final isUser = msg.isUser;
                  final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: ThemeSpacing.m),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ThemeColors.primaryAccentSubtle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: ThemeColors.primaryAccent,
                                ),
                              ),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? ThemeColors.primaryAccent
                                      : (isDark
                                          ? ThemeColors.darkElevatedSurface
                                          : ThemeColors.lightSurface),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(
                                          color: isDark
                                              ? ThemeColors.darkBorder
                                              : ThemeColors.lightBorder,
                                        ),
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: isUser
                                        ? Colors.white
                                        : (isDark
                                            ? ThemeColors.darkTextPrimary
                                            : ThemeColors.lightTextPrimary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.only(
                            left: isUser ? 0 : 36,
                            right: isUser ? 4 : 0,
                          ),
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? ThemeColors.darkTextMuted
                                  : ThemeColors.lightTextMuted,
                            ),
                          ),
                        ),

                        // Suggested actions if any
                        if (msg.suggestedActions != null &&
                            msg.suggestedActions!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 36),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: msg.suggestedActions!.map((action) {
                                return ActionChip(
                                  label: Text(
                                    action,
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
                                    color: isDark
                                        ? ThemeColors.darkBorder
                                        : ThemeColors.lightBorder,
                                  ),
                                  onPressed: () {
                                    vm.sendTextMessage(action);
                                    _scrollToBottom();
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Input Bar & Voice Mic Button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeSpacing.m,
                vertical: ThemeSpacing.s,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? ThemeColors.darkBorder
                        : ThemeColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Microphone Button
                  IconButton.filledTonal(
                    icon: Icon(
                      vm.voiceState == VoiceState.listening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: vm.voiceState == VoiceState.listening
                          ? ThemeColors.error
                          : ThemeColors.primaryAccentSubtle,
                      foregroundColor: vm.voiceState == VoiceState.listening
                          ? Colors.white
                          : ThemeColors.primaryAccent,
                    ),
                    onPressed: () => vm.toggleVoiceInteraction(),
                  ),
                  const SizedBox(width: 8),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _sendMessage(vm),
                      decoration: const InputDecoration(
                        hintText: "Ask Ekagra anything...",
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  // Send button
                  IconButton(
                    icon: const Icon(Icons.send_rounded, size: 20),
                    color: ThemeColors.primaryAccent,
                    onPressed: () => _sendMessage(vm),
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
