import 'package:flutter/foundation.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/productivity_repository.dart';

class RoutinesViewModel extends ChangeNotifier {
  final ProductivityRepository repository;
  bool _isLoading = true;
  List<Routine> _routines = [];

  RoutinesViewModel({required this.repository}) {
    loadRoutines();
  }

  bool get isLoading => _isLoading;
  List<Routine> get routines => _routines;

  Future<void> loadRoutines() async {
    _isLoading = true;
    notifyListeners();
    try {
      _routines = await repository.getRoutines();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleStep(String routineId, String stepId) async {
    await repository.toggleRoutineStep(routineId, stepId);
    await loadRoutines();
  }
}
