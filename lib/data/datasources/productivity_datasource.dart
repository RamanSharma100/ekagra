import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/focus_session.dart';
import '../models/goal.dart';
import '../models/insight.dart';
import '../models/productivity_score.dart';
import '../models/routine.dart';
import '../models/user_profile.dart';

/// Contract defining productivity data operations.
/// Follows Interface Segregation and Dependency Inversion principles.
abstract class ProductivityDataSource {
  UserProfile getInitialUser();
  ProductivityScore getTodayScore();
  List<FocusSession> getFocusSessions();
  List<Activity> getTodayActivities();
  List<Goal> getGoals();
  List<Routine> getRoutines();
  List<Insight> getInsights();
}

/// Offline-first local data source providing seed baselines and default states.
class LocalProductivityDataSource implements ProductivityDataSource {
  const LocalProductivityDataSource();

  @override
  UserProfile getInitialUser() {
    return const UserProfile(
      id: 'usr_1',
      name: '',
      email: '',
      dailyFocusGoalMinutes: 240,
      currentStreakDays: 1,
      voiceEnabled: true,
      autoSpeakResponses: true,
      speechRate: 1.0,
      speechPitch: 1.0,
      notificationsEnabled: true,
      isDarkMode: true,
    );
  }

  @override
  ProductivityScore getTodayScore() {
    return ProductivityScore(
      date: DateTime.now(),
      score: 0,
      productiveMinutes: 0,
      distractedMinutes: 0,
      neutralMinutes: 0,
      goalMinutes: 240,
    );
  }

  @override
  List<FocusSession> getFocusSessions() {
    return [];
  }

  @override
  List<Activity> getTodayActivities() {
    return [];
  }

  @override
  List<Goal> getGoals() {
    final now = DateTime.now();
    return [
      Goal(
        id: 'g_1',
        title: 'Focus 4 hours daily',
        targetMinutes: 240,
        currentMinutes: 0,
        deadline: DateTime(now.year, now.month, now.day, 23, 59),
        category: 'Daily Focus',
        isCompleted: false,
      ),
      Goal(
        id: 'g_2',
        title: 'Study & Skill Building',
        targetMinutes: 120,
        currentMinutes: 0,
        deadline: now.add(const Duration(days: 2)),
        category: 'Skill Building',
        isCompleted: false,
      ),
      Goal(
        id: 'g_3',
        title: 'Keep YouTube under 35m',
        targetMinutes: 35,
        currentMinutes: 0,
        deadline: DateTime(now.year, now.month, now.day, 23, 59),
        category: 'Limiting Distraction',
        isCompleted: false,
      ),
      Goal(
        id: 'g_4',
        title: 'Read 20 pages of Deep Work',
        targetMinutes: 45,
        currentMinutes: 0,
        deadline: DateTime(now.year, now.month, now.day, 21, 0),
        category: 'Mindset',
        isCompleted: false,
      ),
    ];
  }

  @override
  List<Routine> getRoutines() {
    return [
      const Routine(
        id: 'r_morning',
        title: 'Morning Focus Alignment',
        description: 'Set attention clarity before touching notifications',
        steps: [
          RoutineStep(
            id: 'rs_1',
            title: 'Wake up, hydrate & sunlight exposure',
            time: '07:00 AM',
            isCompleted: true,
          ),
          RoutineStep(
            id: 'rs_2',
            title: 'Review today’s 3 primary outcomes',
            time: '07:30 AM',
            isCompleted: true,
          ),
          RoutineStep(
            id: 'rs_3',
            title: '90m Deep Work Block 1 (No tabs/phone)',
            time: '08:30 AM',
            isCompleted: true,
          ),
          RoutineStep(
            id: 'rs_4',
            title: 'Intentional reset & physical stretch',
            time: '10:00 AM',
            isCompleted: false,
          ),
        ],
      ),
      const Routine(
        id: 'r_evening',
        title: 'Shutdown & Reflection',
        description: 'Close work loops to protect mental restoration',
        steps: [
          RoutineStep(
            id: 'rs_5',
            title: 'Clear inbox and note lingering tasks',
            time: '05:30 PM',
            isCompleted: false,
          ),
          RoutineStep(
            id: 'rs_6',
            title: 'Review focus metrics & celebrate wins',
            time: '06:00 PM',
            isCompleted: false,
          ),
          RoutineStep(
            id: 'rs_7',
            title: 'Screen-off transition hour',
            time: '09:30 PM',
            isCompleted: false,
          ),
        ],
      ),
    ];
  }

  @override
  List<Insight> getInsights() {
    final now = DateTime.now();
    return [
      Insight(
        id: 'ins_1',
        headline: 'Focus Intelligence Active',
        description: 'Complete focus sessions and log activities to discover your cognitive flow windows.',
        metricHighlight: 'Ready',
        type: InsightType.peakProductivity,
        icon: Icons.bolt_rounded,
        generatedAt: now,
        isAiGenerated: true,
      ),
      Insight(
        id: 'ins_2',
        headline: 'Shield Protection Ready',
        description: 'Turn on Focus Mode to block distracting apps and stay immersed in your primary tasks.',
        metricHighlight: 'Shield Active',
        type: InsightType.distractionReduction,
        icon: Icons.shield_outlined,
        generatedAt: now,
        isAiGenerated: true,
      ),
    ];
  }
}
