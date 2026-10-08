import 'dart:async';
import 'package:flutter/material.dart';
import '../datasources/productivity_datasource.dart';
import '../models/activity.dart';
import '../models/focus_session.dart';
import '../models/goal.dart';
import '../models/insight.dart';
import '../models/productivity_score.dart';
import '../models/routine.dart';

abstract class ProductivityRepository {
  Future<ProductivityScore> getTodayScore();
  Stream<ProductivityScore> get scoreStream;
  Future<List<FocusSession>> getFocusSessions();
  Future<void> saveFocusSession(FocusSession session);
  Future<List<Activity>> getTodayActivities();
  Stream<List<Activity>> get activitiesStream;
  Future<void> recordActivity(Activity activity);
  Future<void> deleteActivity(String activityId);
  Future<void> clearAllActivities();
  Future<List<Goal>> getGoals();
  Future<void> saveGoal(Goal goal);
  Future<void> toggleGoalCompletion(String goalId);
  Future<List<Routine>> getRoutines();
  Future<void> toggleRoutineStep(String routineId, String stepId);
  Future<List<Insight>> getInsights();
}

class DefaultProductivityRepository implements ProductivityRepository {
  final ProductivityDataSource _dataSource;

  final _activitiesStreamController = StreamController<List<Activity>>.broadcast();
  final _scoreStreamController = StreamController<ProductivityScore>.broadcast();

  ProductivityScore? _cachedScore;
  List<FocusSession>? _cachedSessions;
  List<Activity>? _cachedActivities;
  List<Goal>? _cachedGoals;
  List<Routine>? _cachedRoutines;
  List<Insight>? _cachedInsights;

  DefaultProductivityRepository({ProductivityDataSource? dataSource})
      : _dataSource = dataSource ?? const LocalProductivityDataSource();

  @override
  Stream<List<Activity>> get activitiesStream => _activitiesStreamController.stream;

  @override
  Stream<ProductivityScore> get scoreStream => _scoreStreamController.stream;

  @override
  Future<ProductivityScore> getTodayScore() async {
    if (_cachedScore != null) return _cachedScore!;
    _cachedActivities ??= _dataSource.getTodayActivities();
    _cachedScore = _calculateScoreForActivities(_cachedActivities!, 240);
    return _cachedScore!;
  }

  ProductivityScore _calculateScoreForActivities(List<Activity> activities, int goalMinutes) {
    if (activities.isEmpty) {
      return ProductivityScore(
        date: DateTime.now(),
        score: 0,
        productiveMinutes: 0,
        distractedMinutes: 0,
        neutralMinutes: 0,
        goalMinutes: goalMinutes,
      );
    }

    int prodMins = 0;
    int distMins = 0;
    int neutMins = 0;

    for (final act in activities) {
      switch (act.category) {
        case ActivityCategory.productive:
          prodMins += act.duration.inMinutes;
          break;
        case ActivityCategory.distracting:
          distMins += act.duration.inMinutes;
          break;
        case ActivityCategory.neutral:
          neutMins += act.duration.inMinutes;
          break;
      }
    }

    // If no productive time has been logged yet, score is strictly 0
    if (prodMins <= 0) {
      return ProductivityScore(
        date: DateTime.now(),
        score: 0,
        productiveMinutes: 0,
        distractedMinutes: distMins,
        neutralMinutes: neutMins,
        goalMinutes: goalMinutes,
      );
    }

    final target = goalMinutes > 0 ? goalMinutes : 240;

    // 1. Goal completion factor: up to 60 points based on progress toward target
    final volumeRatio = (prodMins / target).clamp(0.0, 1.0);
    final volumePoints = volumeRatio * 60.0;

    // 2. Attention purity factor: up to 40 points based on ratio of productive to distracted time
    final totalActiveTime = prodMins + distMins;
    final purityRatio = totalActiveTime > 0 ? (prodMins / totalActiveTime) : 1.0;
    final purityPoints = purityRatio * 40.0;

    // 3. Gentle penalty for heavy distraction duration
    final distractionPenalty = (distMins / 60.0) * 4.0;

    final computedScore = ((volumePoints + purityPoints) - distractionPenalty).clamp(5.0, 100.0).round();

    return ProductivityScore(
      date: DateTime.now(),
      score: computedScore,
      productiveMinutes: prodMins,
      distractedMinutes: distMins,
      neutralMinutes: neutMins,
      goalMinutes: goalMinutes,
    );
  }

  @override
  Future<List<FocusSession>> getFocusSessions() async {
    _cachedSessions ??= _dataSource.getFocusSessions();
    return List.unmodifiable(_cachedSessions!);
  }

  @override
  Future<void> saveFocusSession(FocusSession session) async {
    _cachedSessions ??= _dataSource.getFocusSessions();
    final index = _cachedSessions!.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _cachedSessions![index] = session;
    } else {
      _cachedSessions!.insert(0, session);
    }

    // Automatically record an Activity when focus session finishes
    if (session.isCompleted && session.actualMinutes > 0) {
      IconData icon;
      switch (session.mode) {
        case FocusMode.coding:
          icon = Icons.code_rounded;
          break;
        case FocusMode.reading:
          icon = Icons.menu_book_rounded;
          break;
        case FocusMode.study:
          icon = Icons.school_rounded;
          break;
        case FocusMode.deepWork:
        case FocusMode.custom:
          icon = Icons.bolt_rounded;
          break;
      }

      final activity = Activity(
        id: 'act_${session.id}',
        name: session.title.isNotEmpty ? session.title : session.mode.displayName,
        category: ActivityCategory.productive,
        duration: Duration(minutes: session.actualMinutes),
        timestamp: session.startedAt,
        icon: icon,
      );

      await recordActivity(activity);
    }
  }

  @override
  Future<List<Activity>> getTodayActivities() async {
    _cachedActivities ??= _dataSource.getTodayActivities();
    return List.unmodifiable(_cachedActivities!);
  }

  @override
  Future<void> recordActivity(Activity activity) async {
    _cachedActivities ??= _dataSource.getTodayActivities();
    final existingIndex = _cachedActivities!.indexWhere((a) => a.id == activity.id);
    if (existingIndex >= 0) {
      _cachedActivities![existingIndex] = activity;
    } else {
      _cachedActivities!.insert(0, activity);
    }
    _activitiesStreamController.add(List.unmodifiable(_cachedActivities!));

    final currentScore = await getTodayScore();
    _cachedScore = _calculateScoreForActivities(_cachedActivities!, currentScore.goalMinutes);
    _scoreStreamController.add(_cachedScore!);
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    _cachedActivities ??= _dataSource.getTodayActivities();
    _cachedActivities!.removeWhere((a) => a.id == activityId);
    _activitiesStreamController.add(List.unmodifiable(_cachedActivities!));

    final currentScore = await getTodayScore();
    _cachedScore = _calculateScoreForActivities(_cachedActivities!, currentScore.goalMinutes);
    _scoreStreamController.add(_cachedScore!);
  }

  @override
  Future<void> clearAllActivities() async {
    _cachedActivities = [];
    _activitiesStreamController.add(List.unmodifiable(_cachedActivities!));

    final currentScore = await getTodayScore();
    _cachedScore = _calculateScoreForActivities(_cachedActivities!, currentScore.goalMinutes);
    _scoreStreamController.add(_cachedScore!);
  }

  @override
  Future<List<Goal>> getGoals() async {
    _cachedGoals ??= _dataSource.getGoals();
    return List.unmodifiable(_cachedGoals!);
  }

  @override
  Future<void> saveGoal(Goal goal) async {
    _cachedGoals ??= _dataSource.getGoals();
    final index = _cachedGoals!.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      _cachedGoals![index] = goal;
    } else {
      _cachedGoals!.add(goal);
    }
  }

  @override
  Future<void> toggleGoalCompletion(String goalId) async {
    _cachedGoals ??= _dataSource.getGoals();
    final index = _cachedGoals!.indexWhere((g) => g.id == goalId);
    if (index >= 0) {
      final item = _cachedGoals![index];
      _cachedGoals![index] = item.copyWith(isCompleted: !item.isCompleted);
    }
  }

  @override
  Future<List<Routine>> getRoutines() async {
    _cachedRoutines ??= _dataSource.getRoutines();
    return List.unmodifiable(_cachedRoutines!);
  }

  @override
  Future<void> toggleRoutineStep(String routineId, String stepId) async {
    _cachedRoutines ??= _dataSource.getRoutines();
    final rIndex = _cachedRoutines!.indexWhere((r) => r.id == routineId);
    if (rIndex >= 0) {
      final routine = _cachedRoutines![rIndex];
      final newSteps = routine.steps.map((step) {
        if (step.id == stepId) {
          return step.copyWith(isCompleted: !step.isCompleted);
        }
        return step;
      }).toList();
      _cachedRoutines![rIndex] = routine.copyWith(steps: newSteps);
    }
  }

  @override
  Future<List<Insight>> getInsights() async {
    _cachedInsights ??= _dataSource.getInsights();
    return List.unmodifiable(_cachedInsights!);
  }
}
