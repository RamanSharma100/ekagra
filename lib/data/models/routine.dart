class RoutineStep {
  final String id;
  final String title;
  final String time; // e.g. "07:00 AM"
  final bool isCompleted;

  const RoutineStep({
    required this.id,
    required this.title,
    required this.time,
    this.isCompleted = false,
  });

  RoutineStep copyWith({
    String? id,
    String? title,
    String? time,
    bool? isCompleted,
  }) {
    return RoutineStep(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Routine {
  final String id;
  final String title;
  final String description;
  final List<RoutineStep> steps;

  const Routine({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  int get completedStepsCount => steps.where((s) => s.isCompleted).length;
  double get completionProgress =>
      steps.isEmpty ? 0.0 : completedStepsCount / steps.length;
  bool get isFullyCompleted =>
      steps.isNotEmpty && completedStepsCount == steps.length;

  Routine copyWith({
    String? id,
    String? title,
    String? description,
    List<RoutineStep>? steps,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
    );
  }
}
