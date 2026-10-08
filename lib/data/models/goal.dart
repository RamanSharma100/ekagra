class Goal {
  final String id;
  final String title;
  final int targetMinutes;
  final int currentMinutes;
  final DateTime deadline;
  final String category;
  final bool isCompleted;

  const Goal({
    required this.id,
    required this.title,
    required this.targetMinutes,
    required this.currentMinutes,
    required this.deadline,
    required this.category,
    this.isCompleted = false,
  });

  double get progressPercentage {
    if (targetMinutes <= 0) return 0.0;
    return (currentMinutes / targetMinutes).clamp(0.0, 1.0);
  }

  String get formattedProgress {
    final curH = currentMinutes ~/ 60;
    final curM = currentMinutes % 60;
    final tarH = targetMinutes ~/ 60;
    final tarM = targetMinutes % 60;
    final curStr = curH > 0 ? '${curH}h ${curM}m' : '${curM}m';
    final tarStr = tarH > 0 ? '${tarH}h ${tarM}m' : '${tarM}m';
    return '$curStr / $tarStr';
  }

  Goal copyWith({
    String? id,
    String? title,
    int? targetMinutes,
    int? currentMinutes,
    DateTime? deadline,
    String? category,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      currentMinutes: currentMinutes ?? this.currentMinutes,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
