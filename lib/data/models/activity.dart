import 'package:flutter/material.dart';
import '../../app/theme/theme_colors.dart';

enum ActivityCategory {
  productive,
  neutral,
  distracting;

  String get displayName {
    switch (this) {
      case ActivityCategory.productive:
        return 'Productive';
      case ActivityCategory.neutral:
        return 'Neutral';
      case ActivityCategory.distracting:
        return 'Distracting';
    }
  }

  Color get color {
    switch (this) {
      case ActivityCategory.productive:
        return ThemeColors.categoryProductive;
      case ActivityCategory.neutral:
        return ThemeColors.categoryNeutral;
      case ActivityCategory.distracting:
        return ThemeColors.categoryDistracting;
    }
  }
}

class Activity {
  final String id;
  final String name;
  final ActivityCategory category;
  final Duration duration;
  final DateTime timestamp;
  final IconData icon;
  final String? description;
  final String? subcategory;

  const Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.duration,
    required this.timestamp,
    required this.icon,
    this.description,
    this.subcategory,
  });

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Activity copyWith({
    String? id,
    String? name,
    ActivityCategory? category,
    Duration? duration,
    DateTime? timestamp,
    IconData? icon,
    String? description,
    String? subcategory,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      subcategory: subcategory ?? this.subcategory,
    );
  }
}
