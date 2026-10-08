class ProductivityScore {
  final DateTime date;
  final int score; // 0-100
  final int productiveMinutes;
  final int distractedMinutes;
  final int neutralMinutes;
  final int goalMinutes;

  const ProductivityScore({
    required this.date,
    required this.score,
    required this.productiveMinutes,
    required this.distractedMinutes,
    required this.neutralMinutes,
    required this.goalMinutes,
  });

  String get formattedProductive {
    final h = productiveMinutes ~/ 60;
    final m = productiveMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String get formattedDistracted {
    final h = distractedMinutes ~/ 60;
    final m = distractedMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String get formattedGoal {
    final h = goalMinutes ~/ 60;
    final m = goalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  double get progressToGoal {
    if (goalMinutes <= 0) return 0.0;
    return (productiveMinutes / goalMinutes).clamp(0.0, 1.0);
  }

  int get remainingMinutes => (goalMinutes - productiveMinutes).clamp(0, goalMinutes);

  double get flowPurity {
    final total = productiveMinutes + distractedMinutes;
    if (total == 0) return 1.0;
    return (productiveMinutes / total).clamp(0.0, 1.0);
  }

  String get formattedPurity {
    if (productiveMinutes + distractedMinutes == 0) return "100%";
    return "${(flowPurity * 100).round()}%";
  }

  String get qualityLabel {
    if (score == 0) return "Ready to Begin";
    if (score < 40) return "Building Momentum";
    if (score < 70) return "Steady Focus";
    if (score < 85) return "High Immersion";
    return "Peak Flow";
  }

  String get qualityDescription {
    if (score == 0) return "Start a focus sprint to establish today's flow score.";
    if (score < 40) return "Initial focus logged. Continue sprints to elevate flow.";
    if (score < 70) return "Consistent deep attention. Advancing toward daily goal.";
    if (score < 85) return "Exceptional focus depth with minimal distractions.";
    return "Master-tier attention. Peak cognitive productivity reached.";
  }
}
