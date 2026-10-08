import 'package:flutter/foundation.dart';
import '../../data/models/goal.dart';
import '../../data/repositories/productivity_repository.dart';

class GoalsViewModel extends ChangeNotifier {
  final ProductivityRepository repository;
  bool _isLoading = true;
  List<Goal> _goals = [];

  GoalsViewModel({required this.repository}) {
    loadGoals();
  }

  bool get isLoading => _isLoading;
  List<Goal> get goals => _goals;

  int get completedGoalsCount => _goals.where((g) => g.isCompleted).length;

  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();
    try {
      _goals = await repository.getGoals();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleGoal(String goalId) async {
    await repository.toggleGoalCompletion(goalId);
    await loadGoals();
  }

  Future<void> addGoal({
    required String title,
    required int targetMinutes,
    required String category,
  }) async {
    final newGoal = Goal(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetMinutes: targetMinutes,
      currentMinutes: 0,
      deadline: DateTime.now().add(const Duration(days: 1)),
      category: category,
      isCompleted: false,
    );
    await repository.saveGoal(newGoal);
    await loadGoals();
  }
}
