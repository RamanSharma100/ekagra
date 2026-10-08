import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/activity.dart';
import '../../data/models/productivity_score.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/repositories/user_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductivityRepository productivityRepository;
  final UserRepository userRepository;

  bool _isLoading = true;
  UserProfile? _user;
  ProductivityScore? _score;
  List<Activity> _timeline = [];
  String _aiStatusMessage = "You've had a focused morning. Keep the momentum going.";

  StreamSubscription? _activitySubscription;
  StreamSubscription? _scoreSubscription;
  StreamSubscription? _userSubscription;

  HomeViewModel({
    required this.productivityRepository,
    required this.userRepository,
  }) {
    _init();
  }

  bool get isLoading => _isLoading;
  UserProfile? get user => _user;
  ProductivityScore? get score => _score;
  List<Activity> get timeline => _timeline;
  String get aiStatusMessage => _aiStatusMessage;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _init() {
    loadData();

    _userSubscription = userRepository.userStream.listen((updatedUser) {
      _user = updatedUser;
      notifyListeners();
    });

    _activitySubscription = productivityRepository.activitiesStream.listen((updatedActivities) {
      _timeline = updatedActivities;
      notifyListeners();
    });

    _scoreSubscription = productivityRepository.scoreStream.listen((updatedScore) {
      _score = updatedScore;
      _updateAiStatus();
      notifyListeners();
    });
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await userRepository.getUser();
      _score = await productivityRepository.getTodayScore();
      _timeline = await productivityRepository.getTodayActivities();
      _updateAiStatus();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

    await productivityRepository.recordActivity(activity);
  }

  Future<void> deleteActivity(String activityId) async {
    await productivityRepository.deleteActivity(activityId);
  }

  Future<void> clearAllActivities() async {
    await productivityRepository.clearAllActivities();
  }

  void _updateAiStatus() {
    if (_score == null || (_score!.productiveMinutes == 0 && _score!.distractedMinutes == 0)) {
      _aiStatusMessage = "Ready for your first session today. Let's make it count.";
      return;
    }
    if (_score!.progressToGoal >= 0.8) {
      _aiStatusMessage = "You're exceptionally close to your goal. ${_score!.remainingMinutes} minutes left.";
    } else if (_score!.distractedMinutes > 60) {
      _aiStatusMessage = "A short break could help reset your focus before the next block.";
    } else {
      _aiStatusMessage = "You've logged ${_score!.formattedProductive} of focus so far. Keep the momentum going.";
    }
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    _scoreSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
