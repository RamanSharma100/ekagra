import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/app_blocker_service.dart';
import '../../core/services/voice_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/repositories/user_repository.dart';

class CognitiveBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final String progressLabel;
  final double progress;

  const CognitiveBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progressLabel,
    required this.progress,
  });
}

class ProfileViewModel extends ChangeNotifier {
  final UserRepository userRepository;
  final ProductivityRepository productivityRepository;
  final VoiceService voiceService;
  final AiService? aiService;
  AppBlockerService? _appBlockerService;

  StreamSubscription<VoiceState>? _voiceSub;
  StreamSubscription<UserProfile>? _userSub;

  bool _isLoading = true;
  bool _isSpeakingSample = false;
  UserProfile? _user;

  int _totalFocusMinutes = 0;
  int _totalSessionsCompleted = 0;
  int _todayFocusMinutes = 0;
  int _totalDeflections = 0;
  List<CognitiveBadge> _badges = [];

  ProfileViewModel({
    required this.userRepository,
    required this.productivityRepository,
    required this.voiceService,
    this.aiService,
  }) {
    loadUser();
    _userSub = userRepository.userStream.listen((updatedUser) {
      _user = updatedUser;
      _recalculateStats();
      notifyListeners();
    });
    _voiceSub = voiceService.stateStream.listen((state) {
      final speaking = state == VoiceState.speaking;
      if (_isSpeakingSample != speaking) {
        _isSpeakingSample = speaking;
        notifyListeners();
      }
    });
  }

  void setAppBlockerService(AppBlockerService? service) {
    if (_appBlockerService != service) {
      _appBlockerService = service;
      _recalculateStats();
    }
  }

  bool get isLoading => _isLoading;
  bool get isSpeakingSample => _isSpeakingSample;
  UserProfile? get user => _user;
  bool get hasGeminiApiKey => _user?.hasGeminiKey ?? false;
  String? get geminiApiKey => _user?.geminiApiKey;
  int get totalFocusMinutes => _totalFocusMinutes;
  int get totalSessionsCompleted => _totalSessionsCompleted;
  int get todayFocusMinutes => _todayFocusMinutes;
  int get totalDeflections => _totalDeflections;
  List<CognitiveBadge> get badges => _badges;

  Future<bool> verifyGeminiApiKey(String apiKey) async {
    if (aiService == null) return false;
    return await aiService!.testApiKey(apiKey);
  }

  Future<void> saveGeminiApiKey(String? key) async {
    await userRepository.setGeminiApiKey(key);
    _user = userRepository.currentUserSync;
    notifyListeners();
  }

  String get formattedTotalFocus {
    final h = _totalFocusMinutes ~/ 60;
    final m = _totalFocusMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  int get currentLevelNumber {
    // 1 Level for every 60 minutes of focus, min 1, max 10
    final lvl = (_totalFocusMinutes / 60).floor() + 1;
    return lvl.clamp(1, 10);
  }

  String get focusLevelTitle {
    switch (currentLevelNumber) {
      case 1:
        return 'Cognitive Initiate';
      case 2:
        return 'Focused Apprentice';
      case 3:
        return 'Deep Work Adept';
      case 4:
        return 'Flow Architect';
      case 5:
        return 'Attention Master';
      default:
        return 'Zen Transcendent';
    }
  }

  double get levelProgress {
    final minsInCurrentLevel = _totalFocusMinutes % 60;
    return (minsInCurrentLevel / 60.0).clamp(0.0, 1.0);
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await userRepository.getUser();
      await _recalculateStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _recalculateStats() async {
    try {
      final score = await productivityRepository.getTodayScore();
      final sessions = await productivityRepository.getFocusSessions();
      final activities = await productivityRepository.getTodayActivities();

      _todayFocusMinutes = score.productiveMinutes;
      _totalSessionsCompleted = sessions.where((s) => s.isCompleted).length;

      // Sum all completed session durations + today's productive activity minutes
      final sessionMins = sessions.fold<int>(0, (acc, s) => acc + s.actualMinutes);
      final actMins = activities.fold<int>(0, (acc, a) => acc + a.duration.inMinutes);
      final combinedMins = sessionMins > actMins ? sessionMins : actMins;
      _totalFocusMinutes = combinedMins > _todayFocusMinutes ? combinedMins : _todayFocusMinutes;

      _totalDeflections = _appBlockerService?.totalBlockedAttempts ?? 0;

      // Dynamically compute badges
      final streak = _user?.currentStreakDays ?? 1;
      final goalMins = _user?.dailyFocusGoalMinutes ?? 240;

      _badges = [
        CognitiveBadge(
          id: 'badge_first_session',
          title: 'First Flow',
          description: 'Completed your first deep focus immersion',
          icon: Icons.bolt_rounded,
          color: const Color(0xFF6366F1),
          isUnlocked: _totalSessionsCompleted >= 1 || _totalFocusMinutes >= 15,
          progressLabel: _totalSessionsCompleted >= 1 ? 'Unlocked' : '$_totalSessionsCompleted/1 Session',
          progress: (_totalSessionsCompleted / 1).clamp(0.0, 1.0),
        ),
        CognitiveBadge(
          id: 'badge_iron_shield',
          title: 'Iron Shield',
          description: 'Deflect 5+ digital distractions from stealing attention',
          icon: Icons.shield_rounded,
          color: const Color(0xFF10B981),
          isUnlocked: _totalDeflections >= 5,
          progressLabel: _totalDeflections >= 5 ? 'Unlocked' : '$_totalDeflections/5 Deflections',
          progress: (_totalDeflections / 5.0).clamp(0.0, 1.0),
        ),
        CognitiveBadge(
          id: 'badge_two_hours',
          title: 'Deep Horizon',
          description: 'Channel 2+ hours into uninterrupted focus work',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFF8B5CF6),
          isUnlocked: _totalFocusMinutes >= 120,
          progressLabel: _totalFocusMinutes >= 120 ? 'Unlocked' : '$_totalFocusMinutes/120m',
          progress: (_totalFocusMinutes / 120.0).clamp(0.0, 1.0),
        ),
        CognitiveBadge(
          id: 'badge_streak_7',
          title: 'Consistency Beacon',
          description: 'Maintain a 7-day active mindfulness & focus streak',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFF59E0B),
          isUnlocked: streak >= 7,
          progressLabel: streak >= 7 ? 'Unlocked' : '$streak/7 Days',
          progress: (streak / 7.0).clamp(0.0, 1.0),
        ),
        CognitiveBadge(
          id: 'badge_daily_target',
          title: 'Target Smasher',
          description: 'Fulfill 100% of your configured daily focus commitment',
          icon: Icons.track_changes_rounded,
          color: const Color(0xFF06B6D4),
          isUnlocked: _todayFocusMinutes >= goalMins && goalMins > 0,
          progressLabel: _todayFocusMinutes >= goalMins ? 'Unlocked' : '$_todayFocusMinutes/${goalMins}m',
          progress: goalMins > 0 ? (_todayFocusMinutes / goalMins).clamp(0.0, 1.0) : 0.0,
        ),
      ];
    } catch (e) {
      debugPrint('Error recalculating profile stats: $e');
    }
  }

  Future<void> testVoiceSample() async {
    final rate = _user?.speechRate ?? 1.0;
    final displayName = _user?.name.trim().isNotEmpty == true ? _user!.name.trim() : 'there';
    await voiceService.speak(
      "Greetings $displayName. Your cognitive shield and calm companion are active at speed ${rate}x.",
    );
  }

  Future<void> toggleDarkMode(bool isDark) async {
    if (_user == null) return;
    _user = _user!.copyWith(isDarkMode: isDark);
    notifyListeners();
    await userRepository.toggleDarkMode(isDark);
  }

  Future<void> toggleVoiceEnabled(bool enabled) async {
    if (_user == null) return;
    _user = _user!.copyWith(voiceEnabled: enabled);
    notifyListeners();
    await userRepository.toggleVoice(enabled);
  }

  Future<void> toggleAutoSpeak(bool autoSpeak) async {
    if (_user == null) return;
    _user = _user!.copyWith(autoSpeakResponses: autoSpeak);
    notifyListeners();
    await userRepository.toggleAutoSpeak(autoSpeak);
  }

  Future<void> setSpeechRate(double rate) async {
    if (_user == null) return;
    _user = _user!.copyWith(speechRate: rate);
    notifyListeners();
    await userRepository.setSpeechRate(rate);
    await voiceService.setRate(rate);
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (_user == null) return;
    _user = _user!.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await userRepository.toggleNotifications(enabled);
  }

  Future<void> toggleVoiceAnnouncements(bool enabled) async {
    if (_user == null) return;
    _user = _user!.copyWith(voiceAnnouncementsEnabled: enabled);
    notifyListeners();
    await userRepository.toggleVoiceAnnouncements(enabled);
  }

  Future<void> updateDailyGoal(int minutes) async {
    if (_user == null) return;
    _user = _user!.copyWith(dailyFocusGoalMinutes: minutes);
    await _recalculateStats();
    notifyListeners();
    await userRepository.updateGoalMinutes(minutes);
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? title,
  }) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      name: name,
      email: email,
      title: title ?? _user!.title,
    );
    notifyListeners();
    await userRepository.updateUser(_user!);
  }

  /// Exports complete device attention database as formatted JSON backup
  Future<Map<String, dynamic>> exportBackupData() async {
    final activities = await productivityRepository.getTodayActivities();
    final sessions = await productivityRepository.getFocusSessions();
    final goals = await productivityRepository.getGoals();
    final routines = await productivityRepository.getRoutines();
    final score = await productivityRepository.getTodayScore();

    return {
      'exported_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'user_profile': {
        'name': _user?.name,
        'email': _user?.email,
        'title': _user?.title,
        'daily_goal_minutes': _user?.dailyFocusGoalMinutes,
        'streak_days': _user?.currentStreakDays,
        'speech_rate': _user?.speechRate,
        'dark_mode': _user?.isDarkMode,
      },
      'statistics_summary': {
        'total_focus_minutes': _totalFocusMinutes,
        'today_productive_minutes': score.productiveMinutes,
        'today_distracted_minutes': score.distractedMinutes,
        'total_sessions_completed': _totalSessionsCompleted,
        'total_deflections': _totalDeflections,
        'flow_score': score.score,
      },
      'today_activities_count': activities.length,
      'today_activities': activities.map((a) => {
        'id': a.id,
        'name': a.name,
        'category': a.category.displayName,
        'duration_minutes': a.duration.inMinutes,
        'timestamp': a.timestamp.toIso8601String(),
        'description': a.description,
      }).toList(),
      'focus_sessions': sessions.map((s) => {
        'id': s.id,
        'title': s.title,
        'mode': s.mode.displayName,
        'actual_minutes': s.actualMinutes,
        'target_minutes': s.targetMinutes,
        'is_completed': s.isCompleted,
        'started_at': s.startedAt.toIso8601String(),
      }).toList(),
      'goals': goals.map((g) => {
        'id': g.id,
        'title': g.title,
        'target_minutes': g.targetMinutes,
        'current_minutes': g.currentMinutes,
        'is_completed': g.isCompleted,
      }).toList(),
      'routines': routines.map((r) => {
        'id': r.id,
        'title': r.title,
        'description': r.description,
        'total_steps': r.steps.length,
        'completed_steps': r.completedStepsCount,
      }).toList(),
      'shield_blocked_apps': _appBlockerService?.blockedApps.map((b) => {
        'name': b.name,
        'package': b.packageName,
        'today_minutes': b.todayMinutes,
        'blocked_attempts': b.blockedAttemptsToday,
      }).toList() ?? [],
    };
  }

  Future<String> exportBackupJson() async {
    final data = await exportBackupData();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<void> clearActivityCache() async {
    await productivityRepository.clearAllActivities();
    await _recalculateStats();
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
