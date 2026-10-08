enum FocusMode {
  deepWork,
  study,
  coding,
  reading,
  custom;

  String get displayName {
    switch (this) {
      case FocusMode.deepWork:
        return 'Deep Work';
      case FocusMode.study:
        return 'Study';
      case FocusMode.coding:
        return 'Coding';
      case FocusMode.reading:
        return 'Reading';
      case FocusMode.custom:
        return 'Custom Focus';
    }
  }

  static FocusMode fromString(String val) {
    final lower = val.toLowerCase();
    if (lower.contains('deep')) return FocusMode.deepWork;
    if (lower.contains('study')) return FocusMode.study;
    if (lower.contains('cod')) return FocusMode.coding;
    if (lower.contains('read')) return FocusMode.reading;
    return FocusMode.custom;
  }
}

class FocusSession {
  final String id;
  final String title;
  final FocusMode mode;
  final int targetMinutes;
  final int actualMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? rating; // 1 to 5
  final String? note;
  final bool isCompleted;

  const FocusSession({
    required this.id,
    required this.title,
    required this.mode,
    required this.targetMinutes,
    required this.actualMinutes,
    required this.startedAt,
    this.endedAt,
    this.rating,
    this.note,
    this.isCompleted = false,
  });

  FocusSession copyWith({
    String? id,
    String? title,
    FocusMode? mode,
    int? targetMinutes,
    int? actualMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    int? rating,
    String? note,
    bool? isCompleted,
  }) {
    return FocusSession(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
