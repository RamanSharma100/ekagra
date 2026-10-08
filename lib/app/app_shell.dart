import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/app_blocker_service.dart';
import '../core/services/notification_service.dart';
import '../core/widgets/voice_sheet.dart';
import '../features/activity/activity_screen.dart';
import '../features/ai_companion/ai_companion_screen.dart';
import '../features/ai_companion/ai_companion_view_model.dart';
import '../features/focus/focus_screen.dart';
import '../features/focus/focus_view_model.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/insights/insights_view_model.dart';
import '../features/insights/widgets/midday_digest_sheet.dart';
import '../features/profile/profile_screen.dart';
import 'theme/theme_colors.dart';
import 'theme/theme_radius.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    state?._onTabSelected(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  StreamSubscription<AppNotification>? _notifSub;
  AppNotification? _activeNudge;
  Timer? _nudgeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to real-time notifications & check pending midday digest from notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingMiddayDigest();
      final notifService = context.read<NotificationService>();
      _notifSub = notifService.notificationStream.listen((notif) {
        _showInAppNudge(notif);
      });
    });
  }


  Future<void> _checkPendingMiddayDigest() async {
    try {
      final blocker = context.read<AppBlockerService>();
      final isPending = await blocker.checkPendingDigestAction();
      if (isPending && mounted) {
        final insightsVm = context.read<InsightsViewModel>();
        if (insightsVm.middayDigest != null) {
          MiddayDigestSheet.show(context, insightsVm.middayDigest!);
        } else {
          setState(() {
            _currentIndex = 3; // Navigate to Insights
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    _nudgeTimer?.cancel();
    super.dispose();
  }

  void _showInAppNudge(AppNotification notif) {
    _nudgeTimer?.cancel();
    setState(() {
      _activeNudge = notif;
    });

    _nudgeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _activeNudge = null;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final focusVm = context.read<FocusViewModel>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // User minimized or switched to another app
      if (focusVm.isActive) {
        focusVm.notifyAppSwitchAway();
      }
    } else if (state == AppLifecycleState.resumed) {
      // User returned to Ekagra - sync real device app usage from SQLite database
      final blocker = context.read<AppBlockerService>();
      blocker.fetchDailyAppUsageFromDatabase();
      _checkPendingMiddayDigest();
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openVoiceSheet() {
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
                  setState(() => _currentIndex = 1); // Switch to Focus tab
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      HomeScreen(
        onNavigateToFocus: () => _onTabSelected(1),
        onNavigateToAI: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiCompanionScreen()),
          );
        },
        onOpenVoice: _openVoiceSheet,
      ),
      const FocusScreen(),
      const ActivityScreen(),
      const InsightsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: pages,
            ),

            // Real-Time Floating AI Nudge Banner
            if (_activeNudge != null)
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: -50, end: 0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, val, child) => Transform.translate(
                    offset: Offset(0, val),
                    child: child,
                  ),
                  child: Material(
                    elevation: 8,
                    borderRadius: ThemeRadius.radiusL,
                    color: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightSurface,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: ThemeRadius.radiusL,
                        border: Border.all(
                          color: _activeNudge!.type == AppNotificationType.stepAwayAlert
                              ? ThemeColors.error
                              : ThemeColors.primaryAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _activeNudge!.type == AppNotificationType.stepAwayAlert
                                  ? ThemeColors.errorSubtle
                                  : ThemeColors.primaryAccentSubtle,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _activeNudge!.type == AppNotificationType.stepAwayAlert
                                  ? Icons.warning_rounded
                                  : _activeNudge!.type == AppNotificationType.completed
                                      ? Icons.emoji_events_rounded
                                      : Icons.auto_awesome_rounded,
                              size: 18,
                              color: _activeNudge!.type == AppNotificationType.stepAwayAlert
                                  ? ThemeColors.error
                                  : ThemeColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _activeNudge!.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _activeNudge!.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _activeNudge = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
