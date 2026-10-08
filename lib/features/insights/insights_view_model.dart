import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/app_blocker_service.dart';
import '../../data/models/activity.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/insight.dart';
import '../../data/models/midday_digest.dart';
import '../../data/models/productivity_score.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/repositories/user_repository.dart';

enum InsightTimeframe {
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case InsightTimeframe.daily:
        return 'Daily';
      case InsightTimeframe.weekly:
        return 'Weekly';
      case InsightTimeframe.monthly:
        return 'Monthly';
    }
  }
}

class ChartBarData {
  final String label;
  final int productiveMinutes;
  final int distractedMinutes;
  final bool isHighlight;

  const ChartBarData({
    required this.label,
    required this.productiveMinutes,
    required this.distractedMinutes,
    this.isHighlight = false,
  });
}

class TimeframeSummary {
  final String title;
  final String subtitle;
  final int totalFocusMinutes;
  final int totalDistractedMinutes;
  final int goalMinutes;
  final int flowScore;
  final int blockedAttempts;
  final String efficiencyRatio;
  final List<ChartBarData> chartBars;

  const TimeframeSummary({
    required this.title,
    required this.subtitle,
    required this.totalFocusMinutes,
    required this.totalDistractedMinutes,
    required this.goalMinutes,
    required this.flowScore,
    required this.blockedAttempts,
    required this.efficiencyRatio,
    required this.chartBars,
  });

  String get formattedFocus {
    final h = totalFocusMinutes ~/ 60;
    final m = totalFocusMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String get formattedDistracted {
    final h = totalDistractedMinutes ~/ 60;
    final m = totalDistractedMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String get formattedGoal {
    final h = goalMinutes ~/ 60;
    return '${h}h';
  }

  double get goalProgress {
    if (goalMinutes <= 0) return 0.0;
    return (totalFocusMinutes / goalMinutes).clamp(0.0, 1.0);
  }
}

class InsightsViewModel extends ChangeNotifier {
  final ProductivityRepository repository;
  final UserRepository? userRepository;
  final AiService? aiService;
  AppBlockerService? _appBlockerService;
  StreamSubscription<List<Activity>>? _activitySub;
  StreamSubscription<ProductivityScore>? _scoreSub;

  bool _isLoading = true;
  bool _isSyncing = false;
  InsightTimeframe _selectedTimeframe = InsightTimeframe.daily;
  List<Insight> _insights = [];
  MiddayDigest? _middayDigest;
  TimeframeSummary? _timeframeSummary;

  InsightsViewModel({
    required this.repository,
    this.userRepository,
    this.aiService,
  }) {
    loadInsights(syncUsage: false);
    _activitySub = repository.activitiesStream.listen((_) {
      if (!_isSyncing) {
        _recomputeFromData();
      }
    });
    _scoreSub = repository.scoreStream.listen((_) {
      if (!_isSyncing) {
        _recomputeFromData();
      }
    });
  }

  set appBlockerService(AppBlockerService? service) {
    if (_appBlockerService != service) {
      _appBlockerService = service;
      _recomputeFromData();
    }
  }

  bool get isLoading => _isLoading;
  bool get hasGeminiKey => userRepository?.currentUserSync?.hasGeminiKey ?? false;
  InsightTimeframe get selectedTimeframe => _selectedTimeframe;
  List<Insight> get insights => _insights;
  MiddayDigest? get middayDigest => _middayDigest;
  TimeframeSummary? get timeframeSummary => _timeframeSummary;

  void selectTimeframe(InsightTimeframe timeframe) {
    if (_selectedTimeframe != timeframe) {
      _selectedTimeframe = timeframe;
      _recomputeFromData();
    }
  }

  Future<void> _recomputeFromData() async {
    try {
      final activities = await repository.getTodayActivities();
      final score = await repository.getTodayScore();
      final sessions = await repository.getFocusSessions();
      final blockedCount = _appBlockerService?.totalBlockedAttempts ?? 0;

      switch (_selectedTimeframe) {
        case InsightTimeframe.daily:
          _computeDailyData(activities, score, sessions, blockedCount);
          break;
        case InsightTimeframe.weekly:
          _computeWeeklyData(activities, score, sessions, blockedCount);
          break;
        case InsightTimeframe.monthly:
          _computeMonthlyData(activities, score, sessions, blockedCount);
          break;
      }

      _calculateMiddayDigest(activities, score);

      if (_selectedTimeframe == InsightTimeframe.daily && aiService != null) {
        await _attachAiInsight(activities, score, blockedCount);
      }
    } catch (e) {
      debugPrint('Error recomputing insights: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInsights({bool syncUsage = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    _isLoading = true;
    notifyListeners();

    try {
      if (syncUsage && _appBlockerService != null) {
        try {
          await _appBlockerService!.fetchDailyAppUsageFromDatabase();
        } catch (e) {
          debugPrint('Error syncing usage: $e');
        }
      }

      final activities = await repository.getTodayActivities();
      final score = await repository.getTodayScore();
      final sessions = await repository.getFocusSessions();
      final blockedCount = _appBlockerService?.totalBlockedAttempts ?? 0;

      switch (_selectedTimeframe) {
        case InsightTimeframe.daily:
          _computeDailyData(activities, score, sessions, blockedCount);
          break;
        case InsightTimeframe.weekly:
          _computeWeeklyData(activities, score, sessions, blockedCount);
          break;
        case InsightTimeframe.monthly:
          _computeMonthlyData(activities, score, sessions, blockedCount);
          break;
      }

      _calculateMiddayDigest(activities, score);

      if (_selectedTimeframe == InsightTimeframe.daily && aiService != null) {
        await _attachAiInsight(activities, score, blockedCount);
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
    } finally {
      _isLoading = false;
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _attachAiInsight(
    List<Activity> activities,
    ProductivityScore score,
    int blockedCount,
  ) async {
    try {
      final user = userRepository?.currentUserSync;
      final topAct = activities.isNotEmpty ? activities.first : null;
      final dynamicInsight = await aiService!.generateDynamicInsight(
        productiveMinutes: score.productiveMinutes,
        distractedMinutes: score.distractedMinutes,
        goalMinutes: score.goalMinutes,
        blockedCount: blockedCount,
        craft: user?.title ?? 'Deep Work Practitioner',
        topAppName: topAct?.name,
        topAppMinutes: topAct?.duration.inMinutes,
      );
      _insights.removeWhere((i) => i.id.startsWith('ai_srv_') || i.id.startsWith('dyn_'));
      _insights.insert(0, dynamicInsight);
    } catch (e) {
      debugPrint('Error attaching AI dynamic insight: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DAILY TIMEFRAME COMPUTATION
  // ---------------------------------------------------------------------------
  void _computeDailyData(
    List<Activity> activities,
    ProductivityScore score,
    List<FocusSession> sessions,
    int blockedCount,
  ) {
    final prodMins = score.productiveMinutes;
    final distMins = score.distractedMinutes;
    final totalActiveMins = prodMins + distMins;
    final flowRatio = totalActiveMins > 0 ? ((prodMins / totalActiveMins) * 100).toInt() : 0;

    // Daily 6-hour distribution buckets (Early 6-9a, Morning 9-12p, Midday 12-3p, Afternoon 3-6p, Evening 6-9p, Night 9p+)
    final buckets = [
      {'label': '6-9 AM', 'prod': 0, 'dist': 0},
      {'label': '9-12 PM', 'prod': 0, 'dist': 0},
      {'label': '12-3 PM', 'prod': 0, 'dist': 0},
      {'label': '3-6 PM', 'prod': 0, 'dist': 0},
      {'label': '6-9 PM', 'prod': 0, 'dist': 0},
      {'label': '9 PM+', 'prod': 0, 'dist': 0},
    ];

    for (final a in activities) {
      final h = a.timestamp.hour;
      int idx = 0;
      if (h < 9) {
        idx = 0;
      } else if (h < 12) {
        idx = 1;
      } else if (h < 15) {
        idx = 2;
      } else if (h < 18) {
        idx = 3;
      } else if (h < 21) {
        idx = 4;
      } else {
        idx = 5;
      }

      if (a.category == ActivityCategory.productive) {
        buckets[idx]['prod'] = (buckets[idx]['prod'] as int) + a.duration.inMinutes;
      } else if (a.category == ActivityCategory.distracting) {
        buckets[idx]['dist'] = (buckets[idx]['dist'] as int) + a.duration.inMinutes;
      }
    }

    // Identify peak flow bucket
    int maxProd = -1;
    int peakIndex = 1;
    for (int i = 0; i < buckets.length; i++) {
      final p = buckets[i]['prod'] as int;
      if (p > maxProd) {
        maxProd = p;
        peakIndex = i;
      }
    }

    final chartBars = List.generate(buckets.length, (i) {
      final b = buckets[i];
      return ChartBarData(
        label: b['label'] as String,
        productiveMinutes: b['prod'] as int,
        distractedMinutes: b['dist'] as int,
        isHighlight: i == peakIndex && (b['prod'] as int) > 0,
      );
    });

    _timeframeSummary = TimeframeSummary(
      title: "Today's Attention Architecture",
      subtitle: totalActiveMins > 0
          ? "Deep flow tracking based on real-time device engagement."
          : "Start a focus sprint to establish today's attention baseline.",
      totalFocusMinutes: prodMins,
      totalDistractedMinutes: distMins,
      goalMinutes: score.goalMinutes > 0 ? score.goalMinutes : 240,
      flowScore: score.score,
      blockedAttempts: blockedCount,
      efficiencyRatio: "$flowRatio% Flow",
      chartBars: chartBars,
    );

    // Dynamic Daily Insights
    final generated = <Insight>[];

    // 1. Attention Flow Ratio
    if (totalActiveMins > 0) {
      generated.add(
        Insight(
          id: 'daily_flow_ratio',
          headline: 'Attention Flow Ratio: $flowRatio%',
          description:
              'Out of ${score.formattedProductive} active focus, $flowRatio% was spent productively with ${score.formattedDistracted} on competing distractors.',
          metricHighlight: '$flowRatio% Flow',
          type: InsightType.distractionReduction,
          icon: Icons.trending_up_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Start Focus Sprint',
          actionType: 'start_focus',
          accentColor: const Color(0xFF6366F1),
        ),
      );
    } else {
      generated.add(
        Insight(
          id: 'daily_flow_baseline',
          headline: 'Attention Baseline: Ready to Calibrate',
          description:
              'Launch a 25-minute Pomodoro sprint or categorize newly opened apps to begin charting today’s cognitive flow.',
          metricHighlight: 'Calibrating',
          type: InsightType.peakProductivity,
          icon: Icons.bolt_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Launch Sprint',
          actionType: 'start_focus',
          accentColor: const Color(0xFF6366F1),
        ),
      );
    }

    // 2. Peak Cognitive Window
    final peakLabel = buckets[peakIndex]['label'] as String;
    final peakMins = buckets[peakIndex]['prod'] as int;
    generated.add(
      Insight(
        id: 'daily_peak_window',
        headline: peakMins > 0
            ? 'Peak Cognitive Window: $peakLabel'
            : 'Prime Cognitive Window: Morning (9:00 AM – 12:00 PM)',
        description: peakMins > 0
            ? 'Your highest concentration block occurred during $peakLabel with ${peakMins}m of uninterrupted work. Schedule critical tasks here tomorrow.'
            : 'Human circadian studies show cognitive clarity peaks 2-4 hours after waking. Protect your upcoming morning block from meetings and notifications.',
        metricHighlight: peakMins > 0 ? '${peakMins}m Flow' : 'Golden Hour',
        type: InsightType.peakProductivity,
        icon: Icons.wb_sunny_rounded,
        generatedAt: DateTime.now(),
        actionLabel: 'Schedule Session',
        actionType: 'start_focus',
        accentColor: const Color(0xFF10B981),
      ),
    );

    // 3. Shield Interceptions & Focus Shield Status
    if (blockedCount > 0) {
      final savedMinutes = blockedCount * 4;
      generated.add(
        Insight(
          id: 'daily_shield_impact',
          headline: '$blockedCount Distraction Attempts Intercepted',
          description:
              'Ekagra actively intervened $blockedCount times when tempting apps were opened, saving an estimated $savedMinutes minutes of flow disruption.',
          metricHighlight: '$blockedCount Deflected',
          type: InsightType.distractionReduction,
          icon: Icons.shield_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Manage Shielded Apps',
          actionType: 'view_activity',
          accentColor: const Color(0xFFEF4444),
        ),
      );
    } else {
      generated.add(
        Insight(
          id: 'daily_shield_armed',
          headline: 'Digital Distraction Shield Armed',
          description:
              'Background monitoring is active. Whenever a distracting app is launched during focus sessions, Ekagra displays the full-screen barrier.',
          metricHighlight: 'Shield Active',
          type: InsightType.distractionReduction,
          icon: Icons.shield_outlined,
          generatedAt: DateTime.now(),
          actionLabel: 'Configure Blocked Apps',
          actionType: 'view_activity',
          accentColor: const Color(0xFF3B82F6),
        ),
      );
    }

    // 4. Top Cognitive Driver or Leak
    final productiveActs = activities
        .where((a) => a.category == ActivityCategory.productive)
        .toList();
    if (productiveActs.isNotEmpty) {
      productiveActs.sort((a, b) => b.duration.compareTo(a.duration));
      final top = productiveActs.first;
      generated.add(
        Insight(
          id: 'daily_top_tool',
          headline: 'Top Cognitive Flow Driver: ${top.name}',
          description:
              'You dedicated ${top.formattedDuration} to ${top.name} today, accounting for your highest concentrated attention block.',
          metricHighlight: top.formattedDuration,
          type: InsightType.peakProductivity,
          icon: top.icon,
          generatedAt: DateTime.now(),
          actionLabel: 'View Activity Timeline',
          actionType: 'view_activity',
          accentColor: const Color(0xFF8B5CF6),
        ),
      );
    }

    // 5. Daily Progress AI Recommendation
    final goalProgress = score.goalMinutes > 0 ? prodMins / score.goalMinutes : 0.0;
    if (goalProgress >= 1.0) {
      generated.add(
        Insight(
          id: 'daily_ai_recommendation',
          headline: 'Daily Focus Target Accomplished!',
          description:
              'You hit 100% of your daily focus goal. Transition into wind-down to allow neurological memory consolidation and mental recovery.',
          metricHighlight: 'Target Reached',
          type: InsightType.routineAdherence,
          icon: Icons.emoji_events_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Review Goals',
          actionType: 'view_goals',
          accentColor: const Color(0xFFF59E0B),
        ),
      );
    } else {
      final remainingMins = (score.goalMinutes - prodMins).clamp(0, score.goalMinutes);
      final sprintsNeeded = (remainingMins / 25).ceil();
      generated.add(
        Insight(
          id: 'daily_ai_recommendation',
          headline: 'Pacing Calibration: $sprintsNeeded Sprints to Target',
          description:
              'You are ${remainingMins}m away from today’s commitment. Splitting this into $sprintsNeeded structured sprints keeps mental resistance low.',
          metricHighlight: '$remainingMins mins left',
          type: InsightType.sessionLength,
          icon: Icons.flag_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Start Sprint',
          actionType: 'start_focus',
          accentColor: const Color(0xFFEC4899),
        ),
      );
    }

    _insights = generated;
  }

  // ---------------------------------------------------------------------------
  // WEEKLY TIMEFRAME COMPUTATION (100% Real Logged Data)
  // ---------------------------------------------------------------------------
  void _computeWeeklyData(
    List<Activity> activities,
    ProductivityScore score,
    List<FocusSession> sessions,
    int blockedCount,
  ) {
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Track 7 individual days ending today [now - 6 days ... now]
    final days = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final isToday = i == 0;
      final label = isToday ? '${dayNames[date.weekday - 1]} (Today)' : dayNames[date.weekday - 1];

      int dayProd = 0;
      int dayDist = 0;

      if (isToday) {
        dayProd = score.productiveMinutes;
        dayDist = score.distractedMinutes;
      } else {
        for (final act in activities) {
          if (act.timestamp.year == date.year &&
              act.timestamp.month == date.month &&
              act.timestamp.day == date.day) {
            if (act.category == ActivityCategory.productive) {
              dayProd += act.duration.inMinutes;
            } else if (act.category == ActivityCategory.distracting) {
              dayDist += act.duration.inMinutes;
            }
          }
        }
        for (final sess in sessions) {
          if (sess.startedAt.year == date.year &&
              sess.startedAt.month == date.month &&
              sess.startedAt.day == date.day &&
              sess.isCompleted) {
            dayProd += sess.actualMinutes;
          }
        }
      }

      days.add({
        'day': label,
        'prod': dayProd,
        'dist': dayDist,
        'isToday': isToday,
      });
    }

    int weeklyTotalProd = 0;
    int weeklyTotalDist = 0;
    int maxDayProd = -1;
    int bestDayIndex = 6;

    for (int i = 0; i < days.length; i++) {
      final p = days[i]['prod'] as int;
      final d = days[i]['dist'] as int;
      weeklyTotalProd += p;
      weeklyTotalDist += d;
      if (p > maxDayProd) {
        maxDayProd = p;
        bestDayIndex = i;
      }
    }

    final dailyTarget = score.goalMinutes > 0 ? score.goalMinutes : 240;
    final weeklyGoalMinutes = dailyTarget * 7;
    final weeklyAvgHours = (weeklyTotalProd / (7 * 60)).toStringAsFixed(1);
    final weeklyProgressPct = weeklyGoalMinutes > 0
        ? ((weeklyTotalProd / weeklyGoalMinutes) * 100).toInt().clamp(0, 100)
        : 0;
    final weeklyBlocked = blockedCount;

    final chartBars = List.generate(days.length, (i) {
      final d = days[i];
      return ChartBarData(
        label: d['day'] as String,
        productiveMinutes: d['prod'] as int,
        distractedMinutes: d['dist'] as int,
        isHighlight: i == bestDayIndex && (d['prod'] as int) > 0,
      );
    });

    final weeklyActive = weeklyTotalProd + weeklyTotalDist;
    final weeklyFlowScore = weeklyActive > 0
        ? ((weeklyTotalProd / weeklyActive) * 100).round().clamp(0, 100)
        : (weeklyTotalProd > 0 ? 100 : 0);

    final bestDayName = days[bestDayIndex]['day'] as String;
    final bestDayHours = ((days[bestDayIndex]['prod'] as int) / 60).toStringAsFixed(1);

    _timeframeSummary = TimeframeSummary(
      title: "7-Day Attention Trajectory",
      subtitle: weeklyTotalProd > 0
          ? "$weeklyProgressPct% of weekly ${(weeklyGoalMinutes / 60).round()}h focus goal recorded ($weeklyTotalProd min total)."
          : "Day 1 of 7-Day Cycle. Complete focus sprints to build your weekly trajectory.",
      totalFocusMinutes: weeklyTotalProd,
      totalDistractedMinutes: weeklyTotalDist,
      goalMinutes: weeklyGoalMinutes,
      flowScore: weeklyFlowScore,
      blockedAttempts: weeklyBlocked,
      efficiencyRatio: "$weeklyAvgHours h/day",
      chartBars: chartBars,
    );

    _insights = [
      if (weeklyTotalProd > 0)
        Insight(
          id: 'weekly_momentum',
          headline: 'Weekly Flow Velocity: ${(weeklyTotalProd / 60).toStringAsFixed(1)}h Dedicated',
          description:
              'You logged $weeklyTotalProd minutes of deep immersion this week across your active focus sessions. Daily average is $weeklyAvgHours hours.',
          metricHighlight: '$weeklyProgressPct% Goal',
          type: InsightType.peakProductivity,
          icon: Icons.trending_up_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Review Commitments',
          actionType: 'view_goals',
          accentColor: const Color(0xFF6366F1),
        )
      else
        Insight(
          id: 'weekly_momentum',
          headline: 'Weekly Flow Trajectory: Cycle Initiated',
          description:
              'No completed focus sessions logged yet this week. Complete a 25-minute Pomodoro sprint to kickstart your trajectory.',
          metricHighlight: '0h Recorded',
          type: InsightType.peakProductivity,
          icon: Icons.flag_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Start Sprint',
          actionType: 'start_focus',
          accentColor: const Color(0xFF6366F1),
        ),
      if (maxDayProd > 0)
        Insight(
          id: 'weekly_best_day',
          headline: 'Peak Performance: $bestDayName ($bestDayHours h)',
          description:
              'On $bestDayName, you achieved your longest sustained flow blocks. Replicate that environment for consistent rhythm.',
          metricHighlight: 'Best: $bestDayName',
          type: InsightType.bestDay,
          icon: Icons.star_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Start Sprint',
          actionType: 'start_focus',
          accentColor: const Color(0xFF10B981),
        )
      else
        Insight(
          id: 'weekly_best_day',
          headline: 'Calibrating Peak Performance Day',
          description:
              'Your peak day will be identified once you log multiple daily focus blocks throughout the week.',
          metricHighlight: 'Calibrating',
          type: InsightType.bestDay,
          icon: Icons.calendar_today_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Start Sprint',
          actionType: 'start_focus',
          accentColor: const Color(0xFF10B981),
        ),
      if (weeklyBlocked > 0)
        Insight(
          id: 'weekly_shield_summary',
          headline: 'Focus Shield: $weeklyBlocked Distraction Attempts Deflected',
          description:
              'The active overlay deflected $weeklyBlocked impulsive app switches this week, preserving your cognitive state.',
          metricHighlight: '$weeklyBlocked Deflections',
          type: InsightType.distractionReduction,
          icon: Icons.shield_rounded,
          generatedAt: DateTime.now(),
          actionLabel: 'Inspect Shield Logs',
          actionType: 'view_activity',
          accentColor: const Color(0xFFEF4444),
        )
      else
        Insight(
          id: 'weekly_shield_summary',
          headline: 'Focus Shield: Standing Guard',
          description:
              'No distracting app breaches detected during focus blocks. The shield activates automatically when you start focus.',
          metricHighlight: '0 Breaches',
          type: InsightType.distractionReduction,
          icon: Icons.shield_outlined,
          generatedAt: DateTime.now(),
          actionLabel: 'Shield Settings',
          actionType: 'view_activity',
          accentColor: const Color(0xFF10B981),
        ),
      Insight(
        id: 'weekly_fragmentation',
        headline: weeklyTotalProd > 0
            ? 'Attention Quality: Grounded Deep Focus'
            : 'Single-Tasking Baseline',
        description: weeklyTotalProd > 0
            ? 'Your tracked attention blocks demonstrate purposeful engagement with low context-switching penalties.'
            : 'Focusing on one single task for 25 continuous minutes doubles retention and reduces mental fatigue.',
        metricHighlight: weeklyTotalProd > 0 ? '$weeklyFlowScore% Flow' : 'Single-Task',
        type: InsightType.sessionLength,
        icon: Icons.all_inclusive_rounded,
        generatedAt: DateTime.now(),
        actionLabel: 'View Activities',
        actionType: 'view_activity',
        accentColor: const Color(0xFF8B5CF6),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // MONTHLY TIMEFRAME COMPUTATION (100% Real Logged Data)
  // ---------------------------------------------------------------------------
  void _computeMonthlyData(
    List<Activity> activities,
    ProductivityScore score,
    List<FocusSession> sessions,
    int blockedCount,
  ) {
    final now = DateTime.now();

    // 4 7-day windows ending today
    final weeks = <Map<String, dynamic>>[];
    for (int w = 3; w >= 0; w--) {
      final startDay = now.subtract(Duration(days: (w + 1) * 7 - 1));
      final endDay = now.subtract(Duration(days: w * 7));
      final label = w == 0 ? 'Current Week' : 'Week ${4 - w}';

      int wProd = 0;
      int wDist = 0;

      if (w == 0) {
        wProd += score.productiveMinutes;
        wDist += score.distractedMinutes;
      }

      for (final act in activities) {
        if (act.timestamp.isAfter(startDay.subtract(const Duration(seconds: 1))) &&
            act.timestamp.isBefore(endDay.add(const Duration(days: 1)))) {
          if (w == 0 && act.timestamp.day == now.day && act.timestamp.month == now.month) {
            continue;
          }
          if (act.category == ActivityCategory.productive) {
            wProd += act.duration.inMinutes;
          } else if (act.category == ActivityCategory.distracting) {
            wDist += act.duration.inMinutes;
          }
        }
      }

      for (final sess in sessions) {
        if (sess.startedAt.isAfter(startDay.subtract(const Duration(seconds: 1))) &&
            sess.startedAt.isBefore(endDay.add(const Duration(days: 1))) &&
            sess.isCompleted) {
          if (w == 0 && sess.startedAt.day == now.day && sess.startedAt.month == now.month) {
            continue;
          }
          wProd += sess.actualMinutes;
        }
      }

      weeks.add({
        'label': label,
        'prod': wProd,
        'dist': wDist,
        'isCurrent': w == 0,
      });
    }

    int monthlyTotalProd = 0;
    int monthlyTotalDist = 0;
    for (final w in weeks) {
      monthlyTotalProd += w['prod'] as int;
      monthlyTotalDist += w['dist'] as int;
    }

    final dailyTarget = score.goalMinutes > 0 ? score.goalMinutes : 240;
    final monthlyGoalMinutes = dailyTarget * 28;
    final monthlyHours = (monthlyTotalProd / 60).toStringAsFixed(1);
    final monthlyBlocked = blockedCount;

    final chartBars = List.generate(weeks.length, (i) {
      final w = weeks[i];
      return ChartBarData(
        label: w['label'] as String,
        productiveMinutes: w['prod'] as int,
        distractedMinutes: w['dist'] as int,
        isHighlight: i == 3,
      );
    });

    final monthlyActive = monthlyTotalProd + monthlyTotalDist;
    final monthlyFlowScore = monthlyActive > 0
        ? ((monthlyTotalProd / monthlyActive) * 100).round().clamp(0, 100)
        : (monthlyTotalProd > 0 ? 100 : 0);

    _timeframeSummary = TimeframeSummary(
      title: "30-Day Attention Trajectory",
      subtitle: monthlyTotalProd > 0
          ? "$monthlyHours hours of deep work recorded across this 30-day window."
          : "Month 1 Attention Baseline. Keep logging focus sessions to build your 30-day architecture.",
      totalFocusMinutes: monthlyTotalProd,
      totalDistractedMinutes: monthlyTotalDist,
      goalMinutes: monthlyGoalMinutes,
      flowScore: monthlyFlowScore,
      blockedAttempts: monthlyBlocked,
      efficiencyRatio: "$monthlyHours h Total",
      chartBars: chartBars,
    );

    _insights = [
      Insight(
        id: 'monthly_macro_volume',
        headline: monthlyTotalProd > 0
            ? 'Macro Attention Volume: ${monthlyHours}h Logged'
            : '30-Day Attention Architecture Initiated',
        description: monthlyTotalProd > 0
            ? 'You have logged $monthlyTotalProd minutes of focused immersion over this 30-day tracking window.'
            : 'Establish a daily 45-minute deep focus habit to build a resilient long-term attention foundation.',
        metricHighlight: '${monthlyHours}h Logged',
        type: InsightType.peakProductivity,
        icon: Icons.psychology_rounded,
        generatedAt: DateTime.now(),
        actionLabel: 'Review Goals',
        actionType: 'view_goals',
        accentColor: const Color(0xFF6366F1),
      ),
      Insight(
        id: 'monthly_shield_aggregate',
        headline: monthlyBlocked > 0
            ? '$monthlyBlocked Distractions Blocked This Month'
            : 'Focus Shield: 100% Guard Active',
        description: monthlyBlocked > 0
            ? 'The Focus Shield deflected $monthlyBlocked distracting launches, preserving valuable deep focus time.'
            : 'Zero app breaches recorded. The shield protects your attention whenever you run focus sessions.',
        metricHighlight: '$monthlyBlocked Interceptions',
        type: InsightType.distractionReduction,
        icon: Icons.shield_rounded,
        generatedAt: DateTime.now(),
        actionLabel: 'Shield Settings',
        actionType: 'view_activity',
        accentColor: const Color(0xFFEF4444),
      ),
      Insight(
        id: 'monthly_consistency_pattern',
        headline: 'Cognitive Rhythm: Steady Foundation',
        description:
            'Focus blocks scheduled at consistent hours produce up to 2.5x less mental friction. Protect your prime hours.',
        metricHighlight: 'Grounded Rhythm',
        type: InsightType.routineAdherence,
        icon: Icons.auto_awesome_rounded,
        generatedAt: DateTime.now(),
        actionLabel: 'Start Sprint',
        actionType: 'start_focus',
        accentColor: const Color(0xFFF59E0B),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // MIDDAY DIGEST COMPUTATION
  // ---------------------------------------------------------------------------
  void _calculateMiddayDigest(List<Activity> activities, dynamic score) {
    try {
      final items = <AppConsumptionItem>[];
      final apps = _appBlockerService?.installedApps ?? [];
      final customCats = userRepository?.currentUserSync?.customAppCategories ?? {};

      if (apps.isNotEmpty) {
        final totalMins = apps.fold<int>(0, (acc, a) => acc + a.todayMinutes);

        for (final app in apps) {
          if (app.todayMinutes > 0) {
            final pct = totalMins > 0 ? (app.todayMinutes / totalMins) * 100 : 0.0;
            
            // Check custom categorization first
            final userCat = customCats[app.packageName] ?? customCats[app.name];
            String categoryDisplay;
            if (userCat == 'productive') {
              categoryDisplay = 'Productive/Tool';
            } else if (userCat == 'distracting') {
              categoryDisplay = 'Distracting';
            } else if (userCat == 'neutral') {
              categoryDisplay = 'Neutral';
            } else {
              final isDist = app.isBlocked || _isDistractingPackage(app.packageName);
              final isProd = _isProductivePackage(app.packageName) || _isProductivePackage(app.name);
              if (isDist) {
                categoryDisplay = 'Distracting';
              } else if (isProd) {
                categoryDisplay = 'Productive/Tool';
              } else {
                categoryDisplay = 'Productive/Tool';
              }
            }

            items.add(AppConsumptionItem(
              appName: app.name,
              packageName: app.packageName,
              minutes: app.todayMinutes,
              percentage: pct,
              category: categoryDisplay,
              icon: _resolveIcon(app.packageName),
              isShielded: app.isBlocked,
            ));
          }
        }
      }

      // Fallback to logged activities if database usage is empty
      if (items.isEmpty && activities.isNotEmpty) {
        final totalActMins = activities.fold<int>(0, (acc, a) => acc + a.duration.inMinutes);
        for (final a in activities) {
          final mins = a.duration.inMinutes;
          final pct = totalActMins > 0 ? (mins / totalActMins) * 100 : 0.0;
          items.add(AppConsumptionItem(
            appName: a.name,
            packageName: a.name,
            minutes: mins,
            percentage: pct,
            category: a.category.displayName,
            icon: a.icon,
            isShielded: false,
          ));
        }
      }

      items.sort((a, b) => b.minutes.compareTo(a.minutes));

      final mostTimeConsuming = items.isNotEmpty ? items.first : null;
      final totalMinutes = items.fold<int>(0, (acc, item) => acc + item.minutes);

      final productiveMins = items
          .where((i) => i.category.contains('Productive'))
          .fold<int>(0, (acc, i) => acc + i.minutes);

      final distractingMins = items
          .where((i) => i.category.contains('Distracting'))
          .fold<int>(0, (acc, i) => acc + i.minutes);

      final neutralMins = (totalMinutes - productiveMins - distractingMins).clamp(0, totalMinutes);

      String headline;
      String recommendation;

      if (mostTimeConsuming != null && mostTimeConsuming.category.contains('Distracting')) {
        headline = "Attention Sink: ${mostTimeConsuming.appName} is consuming ${mostTimeConsuming.percentage.round()}% of morning time";
        recommendation = "You spent ${mostTimeConsuming.formattedDuration} on ${mostTimeConsuming.appName}. Arm your Afternoon Shield to prevent midday attention leaks.";
      } else if (mostTimeConsuming != null) {
        headline = "Dominant Tool: ${mostTimeConsuming.appName} leads screen time with ${mostTimeConsuming.formattedDuration}";
        recommendation = "High concentration logged on core tools. Continue prioritizing deep work sprints into the afternoon.";
      } else {
        headline = "Midday Check-In: Clean and balanced screen time so far";
        recommendation = "Log your focused apps or launch a 25m sprint to establish deep flow for the afternoon.";
      }

      _middayDigest = MiddayDigest(
        generatedAt: DateTime.now(),
        totalMinutes: totalMinutes,
        productiveMinutes: productiveMins,
        distractedMinutes: distractingMins,
        neutralMinutes: neutralMins,
        topApps: items,
        mostTimeConsumingApp: mostTimeConsuming,
        headline: headline,
        recommendation: recommendation,
      );
    } catch (_) {}
  }

  Future<void> sendTestMiddayNotification() async {
    await _appBlockerService?.triggerMiddayDigestNotification();
  }

  bool _isDistractingPackage(String pkg) {
    final lower = pkg.toLowerCase();
    return lower.contains('youtube') ||
        lower.contains('instagram') ||
        lower.contains('twitter') ||
        lower.contains('reddit') ||
        lower.contains('tiktok') ||
        lower.contains('facebook') ||
        lower.contains('netflix');
  }

  bool _isProductivePackage(String pkg) {
    final lower = pkg.toLowerCase();
    return lower.contains('ekagra') ||
        lower.contains('nyayasetu') ||
        lower.contains('code') ||
        lower.contains('dev') ||
        lower.contains('docs') ||
        lower.contains('office') ||
        lower.contains('drive') ||
        lower.contains('study') ||
        lower.contains('notion') ||
        lower.contains('slack');
  }

  IconData _resolveIcon(String pkg) {
    final lower = pkg.toLowerCase();
    if (lower.contains('youtube')) return Icons.play_circle_fill_rounded;
    if (lower.contains('chrome') || lower.contains('browser')) return Icons.language_rounded;
    if (lower.contains('instagram') || lower.contains('camera')) return Icons.camera_alt_rounded;
    if (lower.contains('twitter') || lower.contains('social')) return Icons.alternate_email_rounded;
    if (lower.contains('reddit')) return Icons.forum_rounded;
    return Icons.apps_rounded;
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    _scoreSub?.cancel();
    super.dispose();
  }
}
