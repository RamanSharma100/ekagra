import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/activity.dart';
import '../../data/models/focus_session.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/voice_sheet.dart';
import '../activity/activity_view_model.dart';
import '../activity/widgets/quick_log_activity_dialog.dart';
import '../../core/widgets/activity_timeline_tile.dart';
import '../ai_companion/ai_companion_view_model.dart';
import '../focus/app_blocker_screen.dart';
import '../focus/focus_view_model.dart';
import 'home_view_model.dart';
import 'widgets/goal_status_alert_banner.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToFocus;
  final VoidCallback onNavigateToAI;
  final VoidCallback? onOpenVoice;

  const HomeScreen({
    super.key,
    required this.onNavigateToFocus,
    required this.onNavigateToAI,
    this.onOpenVoice,
  });

  void _openVoiceSheet(BuildContext context) {
    final focusVm = context.read<FocusViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<AiCompanionViewModel>(
          builder: (context, vm, child) {
            return VoiceSheet(
              voiceState: vm.voiceState,
              statusText: vm.currentStatusText,
              spokenResponse: vm.lastSpokenResponse,
              onMicTapped: () => vm.toggleVoiceInteraction(),
              onCommandSelected: (cmd) {
                if (cmd.contains("45 min") || cmd.contains("focus")) {
                  Navigator.pop(sheetContext);
                  focusVm.startSession(durationMinutes: 45);
                  onNavigateToFocus();
                } else {
                  vm.processVoiceInput(cmd);
                }
              },
              onClose: () {
                vm.stopSpeaking();
                Navigator.pop(sheetContext);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final focusVm = context.watch<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (homeVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = homeVm.user;
    final score = homeVm.score;

    return RefreshIndicator(
      onRefresh: () => homeVm.loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ThemeSpacing.m,
          8,
          ThemeSpacing.m,
          84,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Greeting & AI Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${homeVm.greeting}, ${user?.name ?? 'Friend'}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark
                              ? ThemeColors.darkTextPrimary
                              : ThemeColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ThemeColors.primaryAccent.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ThemeColors.primaryAccent.withAlpha(60),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, size: 12, color: ThemeColors.primaryAccent),
                                const SizedBox(width: 4),
                                Text(
                                  user?.title ?? 'Deep Work Practitioner',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeColors.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        homeVm.aiStatusMessage,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? ThemeColors.darkTextSecondary
                              : ThemeColors.lightTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.mic_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: ThemeColors.primaryAccentSubtle,
                    foregroundColor: ThemeColors.primaryAccent,
                  ),
                  tooltip: "Voice Companion",
                  onPressed: onOpenVoice ?? () => _openVoiceSheet(context),
                ),
              ],
            ),

            const SizedBox(height: ThemeSpacing.m),

            // Real-Time Goal Status & App Shield Alert Banner
            GoalStatusAlertBanner(
              productiveMinutes: score?.productiveMinutes ?? 0,
              goalMinutes: score?.goalMinutes ?? 240,
              distractedMinutes: score?.distractedMinutes ?? 0,
              onStartSession: () {
                final remaining = ((score?.goalMinutes ?? 240) - (score?.productiveMinutes ?? 0)).clamp(15, 90);
                focusVm.startSession(durationMinutes: remaining);
                onNavigateToFocus();
              },
              onOpenShield: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppBlockerScreen()),
                );
              },
            ),

            const SizedBox(height: ThemeSpacing.m),

            // Main Productivity Score Card
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.l),
              decoration: BoxDecoration(
                color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
                borderRadius: ThemeRadius.radiusXl,
                border: Border.all(
                  color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                  width: 1,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 18,
                            color: (score?.score ?? 0) > 0
                                ? ThemeColors.warning
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Today's Focus Score",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? ThemeColors.darkTextPrimary
                                  : ThemeColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.successSubtle,
                          borderRadius: ThemeRadius.radiusFull,
                        ),
                        child: Text(
                          "${user?.currentStreakDays ?? 1} Day Streak",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ThemeColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ThemeSpacing.m),

                  // Circular Score Visualization with dynamic gradient & qualitative feedback
                  () {
                    final scoreVal = score?.score ?? 0;
                    final List<Color> ringGradients = scoreVal == 0
                        ? [ThemeColors.primaryAccent.withAlpha(90), ThemeColors.primaryAccent.withAlpha(90)]
                        : scoreVal < 40
                            ? [const Color(0xFFF59E0B), const Color(0xFFEC4899)]
                            : scoreVal < 70
                                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                : scoreVal < 85
                                    ? [const Color(0xFF6366F1), const Color(0xFF10B981)]
                                    : [const Color(0xFF10B981), const Color(0xFF06B6D4)];

                    return Column(
                      children: [
                        ProgressRing(
                          progress: score != null ? (scoreVal / 100.0) : 0.0,
                          size: 164,
                          strokeWidth: 13,
                          gradientColors: ringGradients,
                          progressColor: ringGradients.first,
                          centerChild: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$scoreVal",
                                style: TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                  color: isDark
                                      ? ThemeColors.darkTextPrimary
                                      : ThemeColors.lightTextPrimary,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: scoreVal > 0
                                      ? ringGradients.first.withAlpha(30)
                                      : (isDark ? Colors.white10 : Colors.black.withAlpha(10)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  score?.qualityLabel ?? "Ready to Start",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: scoreVal > 0
                                        ? ringGradients.first
                                        : (isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                scoreVal > 0
                                    ? "${((score?.progressToGoal ?? 0) * 100).round()}% of Target"
                                    : "0m of ${score?.formattedGoal ?? '4h'}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? ThemeColors.darkTextMuted
                                      : ThemeColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            score?.qualityDescription ?? "Start a focus sprint to establish today's flow score.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }(),

                  const SizedBox(height: ThemeSpacing.m),

                  // Mini Attention Purity Proportion Bar
                  () {
                    final prod = score?.productiveMinutes ?? 0;
                    final dist = score?.distractedMinutes ?? 0;
                    final total = prod + dist;
                    final prodRatio = total > 0 ? (prod / total) : 0.0;
                    final distRatio = total > 0 ? (dist / total) : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Attention Purity",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                              ),
                            ),
                            Text(
                              total > 0 ? "${(prodRatio * 100).round()}% Productive" : "No Distractions",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: prodRatio >= 0.7
                                    ? ThemeColors.success
                                    : (total == 0 ? ThemeColors.primaryAccent : ThemeColors.warning),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              children: [
                                if (total > 0 && prodRatio > 0)
                                  Expanded(
                                    flex: (prodRatio * 100).round(),
                                    child: Container(color: ThemeColors.categoryProductive),
                                  ),
                                if (total > 0 && distRatio > 0)
                                  Expanded(
                                    flex: (distRatio * 100).round(),
                                    child: Container(color: ThemeColors.categoryDistracting),
                                  ),
                                if (total == 0)
                                  Expanded(
                                    child: Container(
                                      color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }(),

                  const SizedBox(height: ThemeSpacing.m),

                  // Four metric stats row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightElevatedSurface,
                      borderRadius: ThemeRadius.radiusM,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            label: "Focused",
                            value: score?.formattedProductive ?? "0m",
                            color: ThemeColors.categoryProductive,
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: "Distracted",
                            value: score?.formattedDistracted ?? "0m",
                            color: ThemeColors.categoryDistracting,
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: "Purity",
                            value: score?.formattedPurity ?? "100%",
                            color: const Color(0xFF06B6D4),
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: "Goal",
                            value: score?.formattedGoal ?? "4h",
                            color: ThemeColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: ThemeSpacing.l),

            // Current Focus Card / Quick Sprint Launcher
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.l),
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeColors.darkElevatedSurface
                    : ThemeColors.lightElevatedSurface,
                borderRadius: ThemeRadius.radiusL,
                border: Border.all(
                  color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                  width: 1,
                ),
              ),
              child: focusVm.isActive || focusVm.isPaused
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    color: focusVm.isActive
                                        ? ThemeColors.success
                                        : ThemeColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  focusVm.selectedMode.displayName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                    color: ThemeColors.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              focusVm.formattedRemainingTime,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: isDark
                                    ? ThemeColors.darkTextPrimary
                                    : ThemeColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (focusVm.goalNote.isNotEmpty) ...[
                          const SizedBox(height: ThemeSpacing.xs),
                          Text(
                            focusVm.goalNote,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? ThemeColors.darkTextSecondary
                                  : ThemeColors.lightTextSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: ThemeSpacing.m),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: focusVm.isActive
                                    ? focusVm.pauseSession
                                    : focusVm.resumeSession,
                                child: Text(focusVm.isActive ? "Pause" : "Resume"),
                              ),
                            ),
                            const SizedBox(width: ThemeSpacing.m),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ThemeColors.error,
                                ),
                                onPressed: focusVm.endSession,
                                child: const Text("End Session"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, size: 18, color: ThemeColors.primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  "Quick Launch Sprint",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: onNavigateToFocus,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text("Zen Timer →", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Dedicate distraction-free focus blocks tailored to your craft:",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: ThemeSpacing.m),
                        () {
                          final craft = user?.title ?? 'Deep Work Practitioner';
                          final lowerCraft = craft.toLowerCase();
                          final List<Map<String, dynamic>> sprintPresets;
                          if (lowerCraft.contains('engineer') || lowerCraft.contains('code') || lowerCraft.contains('dev')) {
                            sprintPresets = [
                              {'mins': 25, 'title': 'Code Sprint', 'icon': '💻', 'mode': FocusMode.coding, 'color': ThemeColors.primaryAccent},
                              {'mins': 45, 'title': 'Debug Focus', 'icon': '🐞', 'mode': FocusMode.deepWork, 'color': ThemeColors.info},
                              {'mins': 60, 'title': 'System Arch', 'icon': '🏗️', 'mode': FocusMode.coding, 'color': ThemeColors.categoryProductive},
                            ];
                          } else if (lowerCraft.contains('student') || lowerCraft.contains('academic')) {
                            sprintPresets = [
                              {'mins': 25, 'title': 'Flashcards', 'icon': '📖', 'mode': FocusMode.study, 'color': ThemeColors.info},
                              {'mins': 45, 'title': 'Study Block', 'icon': '📚', 'mode': FocusMode.study, 'color': ThemeColors.primaryAccent},
                              {'mins': 60, 'title': 'Exam Prep', 'icon': '🎯', 'mode': FocusMode.deepWork, 'color': ThemeColors.categoryProductive},
                            ];
                          } else if (lowerCraft.contains('writer') || lowerCraft.contains('creator')) {
                            sprintPresets = [
                              {'mins': 25, 'title': 'Draft Sprint', 'icon': '✍️', 'mode': FocusMode.deepWork, 'color': const Color(0xFFF59E0B)},
                              {'mins': 45, 'title': 'Deep Writing', 'icon': '🎨', 'mode': FocusMode.deepWork, 'color': ThemeColors.primaryAccent},
                              {'mins': 60, 'title': 'Research Flow', 'icon': '🔍', 'mode': FocusMode.study, 'color': ThemeColors.categoryProductive},
                            ];
                          } else if (lowerCraft.contains('founder') || lowerCraft.contains('builder')) {
                            sprintPresets = [
                              {'mins': 20, 'title': 'Inbox Zero', 'icon': '⚡', 'mode': FocusMode.deepWork, 'color': ThemeColors.info},
                              {'mins': 45, 'title': 'Product Sprint', 'icon': '🚀', 'mode': FocusMode.deepWork, 'color': ThemeColors.primaryAccent},
                              {'mins': 60, 'title': 'Strategy Flow', 'icon': '📊', 'mode': FocusMode.deepWork, 'color': ThemeColors.categoryProductive},
                            ];
                          } else {
                            sprintPresets = [
                              {'mins': 25, 'title': 'Pomodoro', 'icon': '⚡', 'mode': FocusMode.deepWork, 'color': ThemeColors.primaryAccent},
                              {'mins': 45, 'title': 'Deep Work', 'icon': '📚', 'mode': FocusMode.study, 'color': ThemeColors.info},
                              {'mins': 60, 'title': 'Flow State', 'icon': '💻', 'mode': FocusMode.coding, 'color': ThemeColors.categoryProductive},
                            ];
                          }

                          return Row(
                            children: sprintPresets.map((preset) {
                              final mins = preset['mins'] as int;
                              final title = preset['title'] as String;
                              final icon = preset['icon'] as String;
                              final mode = preset['mode'] as FocusMode;
                              final color = preset['color'] as Color;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      focusVm.selectMode(mode);
                                      focusVm.startSession(durationMinutes: mins, note: title);
                                      onNavigateToFocus();
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("$icon ${mins}m", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(
                                          title,
                                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }(),
                      ],
                    ),
            ),

            const SizedBox(height: ThemeSpacing.l),

            // AI Companion Conversational Prompt Card
            Container(
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
                      Text(
                        "AI Companion",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? ThemeColors.darkTextPrimary
                              : ThemeColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ThemeSpacing.s),
                  Text(
                    "Want to plan your sprint or review your flow?",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? ThemeColors.darkTextSecondary
                          : ThemeColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.m),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: () {
                      final craft = user?.title ?? 'Deep Work Practitioner';
                      final lowerCraft = craft.toLowerCase();
                      if (lowerCraft.contains('engineer') || lowerCraft.contains('code') || lowerCraft.contains('dev')) {
                        return [
                          ActionChip(
                            avatar: const Icon(Icons.code_rounded, size: 14),
                            label: const Text("45m Code Sprint"),
                            onPressed: () {
                              focusVm.selectMode(FocusMode.coding);
                              focusVm.startSession(durationMinutes: 45, note: "Code Sprint");
                              onNavigateToFocus();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.shield_rounded, size: 14),
                            label: const Text("Shield Slack & Social"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Shield Slack and distractions for coding");
                              onNavigateToAI();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.insights_rounded, size: 14),
                            label: const Text("Review Dev Flow"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Review my productive engineering hours today");
                              onNavigateToAI();
                            },
                          ),
                        ];
                      } else if (lowerCraft.contains('student') || lowerCraft.contains('academic')) {
                        return [
                          ActionChip(
                            avatar: const Icon(Icons.school_rounded, size: 14),
                            label: const Text("45m Study Block"),
                            onPressed: () {
                              focusVm.selectMode(FocusMode.study);
                              focusVm.startSession(durationMinutes: 45, note: "Study Block");
                              onNavigateToFocus();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.shield_rounded, size: 14),
                            label: const Text("Shield YouTube & IG"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Shield entertainment apps for study block");
                              onNavigateToAI();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.menu_book_rounded, size: 14),
                            label: const Text("Plan Exam Prep"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Plan today's study milestones");
                              onNavigateToAI();
                            },
                          ),
                        ];
                      } else if (lowerCraft.contains('writer') || lowerCraft.contains('creator')) {
                        return [
                          ActionChip(
                            avatar: const Icon(Icons.edit_note_rounded, size: 14),
                            label: const Text("45m Writing Sprint"),
                            onPressed: () {
                              focusVm.selectMode(FocusMode.deepWork);
                              focusVm.startSession(durationMinutes: 45, note: "Writing Sprint");
                              onNavigateToFocus();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.lightbulb_rounded, size: 14),
                            label: const Text("Brainstorm Ideas"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Help me brainstorm creative structure");
                              onNavigateToAI();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.shield_rounded, size: 14),
                            label: const Text("Distraction-free Draft"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Shield distractions while I write");
                              onNavigateToAI();
                            },
                          ),
                        ];
                      } else if (lowerCraft.contains('founder') || lowerCraft.contains('builder')) {
                        return [
                          ActionChip(
                            avatar: const Icon(Icons.rocket_launch_rounded, size: 14),
                            label: const Text("45m Execution Sprint"),
                            onPressed: () {
                              focusVm.selectMode(FocusMode.deepWork);
                              focusVm.startSession(durationMinutes: 45, note: "Product Execution");
                              onNavigateToFocus();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.track_changes_rounded, size: 14),
                            label: const Text("Top 3 Priorities"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Help me pick top 3 high leverage tasks");
                              onNavigateToAI();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.bar_chart_rounded, size: 14),
                            label: const Text("Review Purity"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Review today's focus purity");
                              onNavigateToAI();
                            },
                          ),
                        ];
                      } else {
                        return [
                          ActionChip(
                            avatar: const Icon(Icons.calendar_today_rounded, size: 14),
                            label: const Text("Plan my day"),
                            onPressed: () {
                              context.read<AiCompanionViewModel>().sendTextMessage("Plan my afternoon");
                              onNavigateToAI();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.timer_outlined, size: 14),
                            label: const Text("Start focus"),
                            onPressed: onNavigateToFocus,
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                            label: const Text("Talk to me"),
                            onPressed: onNavigateToAI,
                          ),
                        ];
                      }
                    }(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: ThemeSpacing.l),

            // Today's Activity Timeline with Interactive Quick Log
            // Today's Activity Timeline with Interactive Quick Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SectionHeader(
                    title: "Today's Timeline",
                    subtitle: "Chronological flow of your focus and apps",
                  ),
                ),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (homeVm.timeline.isNotEmpty)
                      IconButton(
                        tooltip: "Clear timeline",
                        icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                        color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Clear Timeline?"),
                              content: const Text("Are you sure you want to clear all logged activities for today?"),
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
                            await homeVm.clearAllActivities();
                          }
                        },
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16, color: ThemeColors.primaryAccent),
                      label: const Text("+ Quick Log", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        final actVm = context.read<ActivityViewModel>();
                        QuickLogActivityDialog.show(context, actVm);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: ThemeSpacing.s),

            if (homeVm.timeline.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSpacing.l,
                  vertical: ThemeSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
                  borderRadius: ThemeRadius.radiusL,
                  border: Border.all(
                    color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: ThemeColors.primaryAccentSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_empty_rounded,
                        color: ThemeColors.primaryAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: ThemeSpacing.m),
                    Text(
                      "No activity logged today yet",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Start a focus session or tap '+ Quick Log' above to record what you're working on.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: ThemeSpacing.m),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text("Start Focus Session"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeColors.primaryAccent,
                        side: const BorderSide(color: ThemeColors.primaryAccent),
                        shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusM),
                      ),
                      onPressed: () {
                        focusVm.startSession(durationMinutes: 25);
                        onNavigateToFocus();
                      },
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: homeVm.timeline.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final activity = homeVm.timeline[index];
                  return ActivityTimelineTile(
                    activity: activity,
                    onEdit: () {
                      final actVm = context.read<ActivityViewModel>();
                      _showEditActivityDialog(context, activity, actVm);
                    },
                    onDelete: () => homeVm.deleteActivity(activity.id),
                  );
                },
              ),

            const SizedBox(height: ThemeSpacing.xxl),
          ],
        ),
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
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? ThemeColors.darkTextSecondary
                      : ThemeColors.lightTextSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
