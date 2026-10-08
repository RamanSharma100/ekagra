import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_shell.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/services/app_blocker_service.dart';
import '../../core/services/voice_service.dart';
import '../../data/repositories/user_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Personalization fields
  final TextEditingController _nameController = TextEditingController();
  String _selectedCraft = 'Software Engineer';
  int _selectedDailyGoalMinutes = 240;
  bool _voiceAnnouncementsEnabled = true;

  final List<Map<String, dynamic>> _craftOptions = const [
    {
      'title': 'Software Engineer',
      'icon': Icons.code_rounded,
      'color': Color(0xFF6366F1),
      'desc': 'Coding, architecture & bug fixing',
    },
    {
      'title': 'Student & Academics',
      'icon': Icons.school_rounded,
      'color': Color(0xFF3B82F6),
      'desc': 'Lectures, exam prep & study blocks',
    },
    {
      'title': 'Writer & Creator',
      'icon': Icons.edit_note_rounded,
      'color': Color(0xFFF59E0B),
      'desc': 'Drafting, design & deep creativity',
    },
    {
      'title': 'Founder & Builder',
      'icon': Icons.rocket_launch_rounded,
      'color': Color(0xFFEC4899),
      'desc': 'High-impact execution & strategy',
    },
    {
      'title': 'Deep Work Practitioner',
      'icon': Icons.self_improvement_rounded,
      'color': Color(0xFF10B981),
      'desc': 'Distraction-free focus & pure flow',
    },
  ];

  // Permission statuses
  bool _usageGranted = false;
  bool _overlayGranted = false;
  bool _notificationGranted = false;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    if (_isCheckingPermissions) return;
    _isCheckingPermissions = true;
    try {
      final blocker = context.read<AppBlockerService>();
      final usage = await blocker.checkUsagePermission();
      final overlay = await blocker.checkOverlayPermission();
      final notif = await blocker.checkNotificationPermission();

      if (mounted) {
        setState(() {
          _usageGranted = usage;
          _overlayGranted = overlay;
          _notificationGranted = notif;
        });
      }
    } finally {
      _isCheckingPermissions = false;
    }
  }

  void _finishOnboarding() async {
    final blocker = context.read<AppBlockerService>();
    final userRepo = context.read<UserRepository>();
    final voiceService = context.read<VoiceService>();

    await blocker.setOnboardingCompleted(true);

    try {
      final current = await userRepo.getUser();
      final enteredName = _nameController.text.trim();
      final updated = current.copyWith(
        name: enteredName.isNotEmpty ? enteredName : 'Focus Practitioner',
        title: _selectedCraft,
        dailyFocusGoalMinutes: _selectedDailyGoalMinutes,
        voiceAnnouncementsEnabled: _voiceAnnouncementsEnabled,
      );
      await userRepo.updateUser(updated);

      await blocker.updateVoiceAnnouncements(_voiceAnnouncementsEnabled);

      if (_voiceAnnouncementsEnabled) {
        final greetingTarget = updated.name.isNotEmpty ? updated.name : "friend";
        voiceService.speak(
          "Welcome to Ekagra, $greetingTarget. Your flow protection is active.",
        );
      }
    } catch (_) {}

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage == 3 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your name so Ekagra can personalize your experience."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_currentPage < 4) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ThemeColors.darkBackground : ThemeColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Logo & Skip)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.m, vertical: ThemeSpacing.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ThemeColors.primaryAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.center_focus_strong_rounded,
                          color: ThemeColors.primaryAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EKAGRA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 4)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          4,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Skip to Setup',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // Carousel Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  if (page == 4) {
                    _refreshPermissions();
                  }
                },
                children: [
                  _buildSlide(
                    context: context,
                    icon: Icons.psychology_rounded,
                    accentColor: const Color(0xFF6366F1),
                    badgeText: "DEEP FOCUS & FLOW",
                    title: "Reclaim Your Attention",
                    description:
                        "Transform fragmented screen time into structured, productive flow states. Set daily focus targets and build long-term momentum.",
                    features: [
                      "Pomodoro & customizable focus timers",
                      "Daily focus streaks and productivity score",
                      "Hands-free voice companion for instant sessions",
                    ],
                  ),
                  _buildSlide(
                    context: context,
                    icon: Icons.shield_rounded,
                    accentColor: const Color(0xFFEF4444),
                    badgeText: "DISTRACTION SHIELD",
                    title: "Active Distraction Blocker",
                    description:
                        "Protect your flow from dopamine traps. Ekagra automatically shields you from addictive social media and entertainment apps while you work.",
                    features: [
                      "Real-time overlay blocking during focus",
                      "Standby watchdog runs quietly in background",
                      "Zero temptation — customize your blocked apps",
                    ],
                  ),
                  _buildSlide(
                    context: context,
                    icon: Icons.insights_rounded,
                    accentColor: const Color(0xFF10B981),
                    badgeText: "100% PRIVATE & ON-DEVICE",
                    title: "Granular Time Analytics",
                    description:
                        "Understand exactly where every minute went with battery-friendly background logging. Stored strictly in your local device SQLite database.",
                    features: [
                      "Live app breakdown (Productive vs Distracting)",
                      "Midday and evening automated digests",
                      "Privacy first — no trackers, zero cloud upload",
                    ],
                  ),
                  _buildPersonalizationSlide(context),
                  _buildPermissionsSlide(context),
                ],
              ),
            ),

            // Bottom Navigation Footer (Dots & Continue Button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.l, vertical: ThemeSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Smooth Animated Dots Indicator
                  Row(
                    children: List.generate(5, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: isActive ? 24 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? ThemeColors.primaryAccent
                              : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  // Action Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: ThemeColors.primaryAccent,
                    ),
                    onPressed: _nextPage,
                    icon: Icon(
                      _currentPage == 4 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentPage == 4 ? "Get Started" : "Next",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required String title,
    required String description,
    required List<String> features,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.l, vertical: ThemeSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Hero Illustration / Icon Container
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withAlpha(25),
                border: Border.all(color: accentColor.withAlpha(60), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(30),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 68, color: accentColor),
            ),
          ),

          const SizedBox(height: 32),

          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withAlpha(80), width: 1),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: accentColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Feature highlights
          Container(
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
              children: features.map((feat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: accentColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationSlide(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.l, vertical: ThemeSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeColors.primaryAccent.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ThemeColors.primaryAccent.withAlpha(80), width: 1),
            ),
            child: const Text(
              "PERSONALIZATION & PREFERENCES",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ThemeColors.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tailor Your Experience",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ekagra adapts its sprints, UI suggestions, and vocal reminders to your craft and daily targets.",
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // 1. User Name Input
          Text(
            "What should Ekagra call you?",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
              borderRadius: ThemeRadius.radiusM,
              border: Border.all(
                color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
              ),
            ),
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: ThemeColors.primaryAccent),
                hintText: "Enter your name (e.g. Alex, Maya)",
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. What are you currently doing? (Role / Craft)
          Text(
            "What is your primary craft?",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: _craftOptions.map((craft) {
              final isSelected = _selectedCraft == craft['title'];
              final color = craft['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCraft = craft['title'] as String;
                    });
                  },
                  borderRadius: ThemeRadius.radiusM,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(28)
                          : (isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface),
                      borderRadius: ThemeRadius.radiusM,
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(craft['icon'] as IconData, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                craft['title'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                craft['desc'] as String,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, size: 20, color: color),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 3. Daily Target
          Text(
            "Daily Deep Work Target",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildGoalChip(120, "2h Focus"),
              const SizedBox(width: 8),
              _buildGoalChip(180, "3h Focus"),
              const SizedBox(width: 8),
              _buildGoalChip(240, "4h Focus"),
              const SizedBox(width: 8),
              _buildGoalChip(360, "6h Flow"),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Voice Announcements Switch & Preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightElevatedSurface,
              borderRadius: ThemeRadius.radiusL,
              border: Border.all(
                color: _voiceAnnouncementsEnabled
                    ? ThemeColors.primaryAccent.withAlpha(100)
                    : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeColors.primaryAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.record_voice_over_rounded, size: 18, color: ThemeColors.primaryAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Spoken Voice & Sound Alerts",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Speaks focus start/end & chimes when restricted apps are deflected",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _voiceAnnouncementsEnabled,
                      activeTrackColor: ThemeColors.primaryAccent,
                      onChanged: (val) {
                        setState(() {
                          _voiceAnnouncementsEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
                if (_voiceAnnouncementsEnabled) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up_rounded, size: 15),
                        label: const Text("Test Spoken Alert", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          foregroundColor: ThemeColors.primaryAccent,
                          side: BorderSide(color: ThemeColors.primaryAccent.withAlpha(100)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final voice = context.read<VoiceService>();
                          voice.playAlertTone();
                          voice.speak("Focus session started. Protecting your attention.");
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGoalChip(int mins, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedDailyGoalMinutes == mins;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDailyGoalMinutes = mins),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? ThemeColors.primaryAccent
                : (isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? ThemeColors.primaryAccent
                  : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.black
                  : (isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsSlide(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocker = context.read<AppBlockerService>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.l, vertical: ThemeSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeColors.primaryAccent.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ThemeColors.primaryAccent.withAlpha(80), width: 1),
            ),
            child: const Text(
              "FIRST-TIME SETUP & PERMISSIONS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ThemeColors.primaryAccent,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Enable App Capabilities",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "In compliance with Google Play guidelines, Ekagra requires the following permissions to log usage and shield you from distractions. All data remains 100% on this device.",
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
            ),
          ),

          const SizedBox(height: 18),

          // Permission Item 1: Usage Access
          _buildPermissionCard(
            context: context,
            icon: Icons.timeline_rounded,
            title: "Usage Access",
            description:
                "Allows Ekagra to calculate how many minutes you spend on productive vs distracting apps.",
            isGranted: _usageGranted,
            actionLabel: "Grant Access",
            onAction: () async {
              await blocker.requestUsagePermission();
            },
          ),

          const SizedBox(height: 10),

          // Permission Item 2: Display Over Other Apps
          _buildPermissionCard(
            context: context,
            icon: Icons.layers_rounded,
            title: "Display Over Other Apps",
            description:
                "Needed to present the full-screen Focus Shield deterrence whenever an addictive app is opened.",
            isGranted: _overlayGranted,
            actionLabel: "Enable Overlay",
            onAction: () async {
              await blocker.requestOverlayPermission();
            },
          ),

          const SizedBox(height: 10),

          // Permission Item 3: Post Notifications
          _buildPermissionCard(
            context: context,
            icon: Icons.notifications_active_rounded,
            title: "Notification Companion",
            description:
                "Keeps your live focus timer visible in the notification drawer and delivers daily digests.",
            isGranted: _notificationGranted,
            actionLabel: "Enable Notifications",
            onAction: () async {
              await blocker.requestNotificationPermission();
            },
          ),

          const SizedBox(height: 18),

          // First Time Run Guide Tips
          Container(
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
                    const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      "Quick Tips for First-Time Users",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTipRow(isDark, "1. Tap 'Activity' tab to categorize your apps as Productive or Distracting."),
                _buildTipRow(isDark, "2. Add the Ekagra Widget to your phone's home screen for instant focus starts."),
                _buildTipRow(isDark, "3. You can revisit this guide anytime in the Profile tab."),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTipRow(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          height: 1.4,
          color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
        borderRadius: ThemeRadius.radiusM,
        border: Border.all(
          color: isGranted
              ? const Color(0xFF10B981).withAlpha(120)
              : (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF10B981).withAlpha(30)
                  : ThemeColors.primaryAccent.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : icon,
              size: 20,
              color: isGranted ? const Color(0xFF10B981) : ThemeColors.primaryAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                      ),
                    ),
                    if (isGranted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "✓ Enabled",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: ThemeColors.primaryAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onAction,
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ThemeColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
