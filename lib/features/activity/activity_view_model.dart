import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/app_blocker_service.dart';
import '../../data/models/activity.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/repositories/user_repository.dart';

class ActivityCategorySummary {
  final ActivityCategory category;
  final Duration totalDuration;
  final double percentage;

  const ActivityCategorySummary({
    required this.category,
    required this.totalDuration,
    required this.percentage,
  });

  String get formattedDuration {
    final h = totalDuration.inHours;
    final m = totalDuration.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}

class ActivityViewModel extends ChangeNotifier {
  final ProductivityRepository repository;
  final UserRepository? userRepository;
  AppBlockerService? appBlockerService;
  bool _isLoading = true;
  List<Activity> _activities = [];
  ActivityCategory? _selectedFilter;
  StreamSubscription? _subscription;

  ActivityViewModel({
    required this.repository,
    this.userRepository,
    this.appBlockerService,
  }) {
    _init();
  }

  bool get isLoading => _isLoading;
  List<Activity> get activities => _activities;
  ActivityCategory? get selectedFilter => _selectedFilter;

  List<Activity> get filteredActivities {
    if (_selectedFilter == null) return _activities;
    return _activities.where((a) => a.category == _selectedFilter).toList();
  }

  Duration get totalDuration {
    return _activities.fold(
      Duration.zero,
      (prev, curr) => prev + curr.duration,
    );
  }

  Duration durationFor(ActivityCategory category) {
    return _activities
        .where((a) => a.category == category)
        .fold(Duration.zero, (prev, curr) => prev + curr.duration);
  }

  List<ActivityCategorySummary> get categorySummaries {
    final totalMins = totalDuration.inMinutes;
    if (totalMins <= 0) return [];

    return ActivityCategory.values.map((cat) {
      final catDuration = durationFor(cat);
      final percent = (catDuration.inMinutes / totalMins).clamp(0.0, 1.0);
      return ActivityCategorySummary(
        category: cat,
        totalDuration: catDuration,
        percentage: percent,
      );
    }).toList();
  }

  void _init() {
    loadActivities();
    _subscription = repository.activitiesStream.listen((updated) {
      _activities = updated;
      notifyListeners();
    });
  }

  void setFilter(ActivityCategory? category) {
    _selectedFilter = category;
    notifyListeners();
  }

  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();
    try {
      _activities = await repository.getTodayActivities();
      await syncFromDeviceUsageDatabase();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncFromDeviceUsageDatabase() async {
    if (appBlockerService == null) return;
    try {
      final usageList = await appBlockerService!.fetchDailyAppUsageFromDatabase();
      final customCats = userRepository?.currentUserSync?.customAppCategories ?? {};

      for (final appMap in usageList) {
        final name = appMap['appName']?.toString() ?? '';
        final mins = (appMap['totalMinutes'] as num?)?.toInt() ?? 0;
        final pkg = appMap['packageName']?.toString() ?? '';
        if (mins > 0 && name.isNotEmpty) {
          ActivityCategory category;
          final userCat = customCats[pkg] ?? customCats[name];

          if (userCat == 'productive') {
            category = ActivityCategory.productive;
          } else if (userCat == 'distracting') {
            category = ActivityCategory.distracting;
          } else if (userCat == 'neutral') {
            category = ActivityCategory.neutral;
          } else {
            final lowerPkg = pkg.toLowerCase();
            final lowerName = name.toLowerCase();

            final isDistracting = lowerPkg.contains('youtube') ||
                lowerPkg.contains('instagram') ||
                lowerPkg.contains('twitter') ||
                lowerPkg.contains('facebook') ||
                lowerPkg.contains('tiktok') ||
                lowerPkg.contains('reddit');

            final isProductive = lowerPkg.contains('ekagra') ||
                lowerPkg.contains('nyayasetu') ||
                lowerName.contains('nyayasetu') ||
                lowerPkg.contains('code') ||
                lowerPkg.contains('dev') ||
                lowerPkg.contains('study') ||
                lowerPkg.contains('docs') ||
                lowerPkg.contains('office') ||
                lowerPkg.contains('drive') ||
                lowerPkg.contains('notion') ||
                lowerPkg.contains('slack');

            if (isDistracting) {
              category = ActivityCategory.distracting;
            } else if (isProductive) {
              category = ActivityCategory.productive;
            } else {
              category = ActivityCategory.neutral;
            }
          }

          IconData icon;
          if (category == ActivityCategory.productive) {
            icon = Icons.check_circle_outline_rounded;
          } else if (category == ActivityCategory.distracting) {
            icon = Icons.warning_amber_rounded;
          } else {
            icon = Icons.apps_rounded;
          }

          final act = Activity(
            id: 'dev_act_${pkg.hashCode}',
            name: name,
            category: category,
            duration: Duration(minutes: mins),
            timestamp: DateTime.now(),
            icon: icon,
          );
          await repository.recordActivity(act);
        }
      }
    } catch (_) {}
  }

  Future<void> logActivity({
    required String name,
    required ActivityCategory category,
    required int durationMinutes,
    IconData? icon,
  }) async {
    final activity = Activity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      duration: Duration(minutes: durationMinutes),
      timestamp: DateTime.now(),
      icon: icon ??
          (category == ActivityCategory.productive
              ? Icons.check_circle_outline_rounded
              : category == ActivityCategory.distracting
                  ? Icons.warning_amber_rounded
                  : Icons.public_rounded),
    );

    await repository.recordActivity(activity);
  }

  Future<void> updateActivity(Activity activity, {String? packageName}) async {
    await repository.recordActivity(activity);
    if (userRepository != null) {
      final catKey = activity.category == ActivityCategory.productive
          ? 'productive'
          : activity.category == ActivityCategory.distracting
              ? 'distracting'
              : 'neutral';
      await userRepository!.setAppCategory(packageName ?? activity.name, catKey);
    }
  }

  Future<void> deleteActivity(String activityId) async {
    await repository.deleteActivity(activityId);
  }

  Future<void> clearAllActivities() async {
    await repository.clearAllActivities();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
