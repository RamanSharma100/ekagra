import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/services/app_blocker_service.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/progress_ring.dart';
import '../../data/models/blocked_app.dart';
import '../../data/models/focus_session.dart';
import 'app_blocker_screen.dart';
import 'focus_view_model.dart';
import 'widgets/focus_shield_overlay.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final TextEditingController _goalController = TextEditingController();
  bool _isShowingCompletionDialog = false;

  static const List<int> _presetDurations = [25, 45, 60, 90];

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _showCompletionDialog(BuildContext context, FocusViewModel vm) {
    if (_isShowingCompletionDialog) return;
    _isShowingCompletionDialog = true;
    int selectedRating = 5;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark
                  ? ThemeColors.darkElevatedSurface
                  : ThemeColors.lightSurface,
              shape: const RoundedRectangleBorder(
                borderRadius: ThemeRadius.radiusL,
              ),
              title: const Text(
                "Focus Session Complete",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(ThemeSpacing.m),
                    decoration: BoxDecoration(
                      color: ThemeColors.successSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: ThemeColors.success,
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.m),
                  Text(
                    "${(vm.elapsedSeconds / 60).ceil()} minutes focused",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.xs),
                  Text(
                    "You protected your attention and achieved meaningful depth.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? ThemeColors.darkTextSecondary
                          : ThemeColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.l),
                  const Text(
                    "How focused did you feel?",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: ThemeSpacing.s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: ThemeColors.warning,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                PrimaryButton(
                  label: "Save & Done",
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    vm.submitCompletionRating(selectedRating);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isShowingCompletionDialog = false;
        });
      } else {
        _isShowingCompletionDialog = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusVm = context.watch<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if session completed and prompt rating dialog
    if (focusVm.isCompleted && !_isShowingCompletionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog(context, focusVm);
      });
    }

    final bool isSessionRunning = focusVm.isActive || focusVm.isPaused;

    return Scaffold(
      backgroundColor: isDark
          ? (isSessionRunning ? ThemeColors.darkBackground : ThemeColors.darkBackground)
          : (isSessionRunning ? ThemeColors.lightSurface : ThemeColors.lightBackground),
      body: SafeArea(
        child: isSessionRunning
            ? _buildActiveSessionView(context, focusVm, isDark)
            : _buildSetupView(context, focusVm, isDark),
      ),
    );
  }

  Widget _buildSetupView(
    BuildContext context,
    FocusViewModel vm,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ThemeSpacing.l,
        8,
        ThemeSpacing.l,
        84,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Start Focus",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.xs),
          Text(
            "Set your intention, choose your mode, and enter the flow state.",
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ThemeColors.darkTextSecondary
                  : ThemeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.l),

          // Focus Modes
          Text(
            "Mode",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.s),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FocusMode.values.map((mode) {
              final isSelected = vm.selectedMode == mode;
              return ChoiceChip(
                label: Text(mode.displayName),
                selected: isSelected,
                selectedColor: ThemeColors.primaryAccentSubtle,
                backgroundColor: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightElevatedSurface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? ThemeColors.primaryAccent
                      : (isDark
                          ? ThemeColors.darkTextSecondary
                          : ThemeColors.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected
                      ? ThemeColors.primaryAccent
                      : (isDark
                          ? ThemeColors.darkBorder
                          : ThemeColors.lightBorder),
                ),
                onSelected: (val) {
                  if (val) vm.selectMode(mode);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Duration selection
          Text(
            "Duration",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.s),
          Row(
            children: _presetDurations.map((duration) {
              final isSelected = vm.targetMinutes == duration;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => vm.selectDuration(duration),
                    borderRadius: ThemeRadius.radiusM,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ThemeColors.primaryAccentSubtle
                            : (isDark
                                ? ThemeColors.darkSurface
                                : ThemeColors.lightElevatedSurface),
                        borderRadius: ThemeRadius.radiusM,
                        border: Border.all(
                          color: isSelected
                              ? ThemeColors.primaryAccent
                              : (isDark
                                  ? ThemeColors.darkBorder
                                  : ThemeColors.lightBorder),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$duration m",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? ThemeColors.primaryAccent
                              : (isDark
                                  ? ThemeColors.darkTextPrimary
                                  : ThemeColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Optional Intention / Goal Note
          Text(
            "What will you accomplish?",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.s),
          TextField(
            controller: _goalController,
            onChanged: vm.setGoalNote,
            decoration: InputDecoration(
              hintText: "e.g. Finish API integration, Read Chapter 4",
              prefixIcon: const Icon(Icons.outlined_flag_rounded, size: 20),
              suffixIcon: _goalController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _goalController.clear();
                        vm.setGoalNote('');
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Ambient Background Sound
          Text(
            "Ambient Atmosphere",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.s),
          Wrap(
            spacing: 8,
            children: AmbientSound.values.map((sound) {
              final isSelected = vm.ambientSound == sound;
              return ChoiceChip(
                label: Text(sound.displayName),
                selected: isSelected,
                selectedColor: ThemeColors.primaryAccentSubtle,
                backgroundColor: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightElevatedSurface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? ThemeColors.primaryAccent
                      : (isDark
                          ? ThemeColors.darkTextSecondary
                          : ThemeColors.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected
                      ? ThemeColors.primaryAccent
                      : (isDark
                          ? ThemeColors.darkBorder
                          : ThemeColors.lightBorder),
                ),
                onSelected: (val) {
                  if (val) vm.setAmbientSound(sound);
                },
              );
            }).toList(),
          ),

          // App Shield & Blocker Card
          Consumer<AppBlockerService>(
            builder: (context, blockerService, _) {
              return Container(
                margin: const EdgeInsets.only(top: ThemeSpacing.m),
                padding: const EdgeInsets.all(ThemeSpacing.m),
                decoration: BoxDecoration(
                  color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
                  borderRadius: ThemeRadius.radiusM,
                  border: Border.all(
                    color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeColors.primaryAccentSubtle,
                        borderRadius: ThemeRadius.radiusSm,
                      ),
                      child: const Icon(Icons.shield_rounded, color: ThemeColors.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: ThemeSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Focus Shield Armed",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            "${blockerService.blockedApps.length} apps will be restricted during session",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppBlockerScreen()),
                        );
                      },
                      child: const Text("Configure"),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: ThemeSpacing.l),

          // Start Button
          PrimaryButton(
            label: "Enter Focus",
            icon: Icons.play_arrow_rounded,
            onPressed: () => vm.startSession(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionView(
    BuildContext context,
    FocusViewModel vm,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ringSize = (constraints.maxHeight * 0.35).clamp(180.0, 250.0);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSpacing.l,
            vertical: ThemeSpacing.m,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryAccentSubtle,
                      borderRadius: ThemeRadius.radiusFull,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: vm.isActive
                                ? ThemeColors.success
                                : ThemeColors.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vm.selectedMode.displayName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: ThemeColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Consumer<AppBlockerService>(
                        builder: (context, blocker, _) {
                          return InkWell(
                            borderRadius: ThemeRadius.radiusFull,
                            onTap: () {
                              final app = blocker.blockedApps.isNotEmpty
                                  ? blocker.blockedApps.first
                                  : (blocker.installedApps.isNotEmpty
                                      ? blocker.installedApps.first
                                      : BlockedApp(
                                          id: 'app_active',
                                          name: 'Distracting App',
                                          packageName: 'com.distraction',
                                          icon: Icons.shield_rounded,
                                        ));
                              FocusShieldOverlay.show(
                                context: context,
                                appName: app.name,
                                appIcon: app.icon,
                                remainingSeconds: vm.remainingSeconds,
                                onReturnToFocus: () {},
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: ThemeColors.primaryAccentSubtle,
                                borderRadius: ThemeRadius.radiusFull,
                                border: Border.all(color: ThemeColors.primaryAccent.withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_rounded, size: 14, color: ThemeColors.primaryAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${blocker.blockedApps.length} Shielded",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ThemeColors.primaryAccent),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (vm.ambientSound != AmbientSound.none) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? ThemeColors.darkElevatedSurface
                                : ThemeColors.lightElevatedSurface,
                            borderRadius: ThemeRadius.radiusFull,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.headphones_rounded, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                vm.ambientSound.displayName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Central Timer Ring
              Column(
                children: [
                  ProgressRing(
                    progress: vm.progressRatio,
                    size: ringSize,
                    strokeWidth: (ringSize * 0.065).clamp(10.0, 16.0),
                progressColor: ThemeColors.primaryAccent,
                centerChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vm.formattedRemainingTime,
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isDark
                            ? ThemeColors.darkTextPrimary
                            : ThemeColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: ThemeSpacing.xs),
                    Text(
                      vm.isPaused ? "PAUSED" : "FOCUS REMAINING",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: isDark
                            ? ThemeColors.darkTextMuted
                            : ThemeColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: ThemeSpacing.xl),

              // Motivational calming quote
              Text(
                vm.isPaused
                    ? "Rest your eyes. Press resume whenever you're ready."
                    : (vm.goalNote.isNotEmpty
                        ? "“${vm.goalNote}”"
                        : "“You're doing great. Stay with it.”"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? ThemeColors.darkTextSecondary
                      : ThemeColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),

          // Bottom Controls
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: vm.isActive ? vm.pauseSession : vm.resumeSession,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            vm.isActive
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(vm.isActive ? "Pause" : "Resume"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: ThemeSpacing.m),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: vm.endSession,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_rounded, size: 20),
                          SizedBox(width: 8),
                          Text("Finish"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  },
);
  }
}
