import 'package:flutter/material.dart';

class AppConsumptionItem {
  final String appName;
  final String packageName;
  final int minutes;
  final double percentage;
  final String category;
  final IconData icon;
  final bool isShielded;

  const AppConsumptionItem({
    required this.appName,
    required this.packageName,
    required this.minutes,
    required this.percentage,
    required this.category,
    required this.icon,
    this.isShielded = false,
  });

  String get formattedDuration {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

class MiddayDigest {
  final DateTime generatedAt;
  final int totalMinutes;
  final int productiveMinutes;
  final int distractedMinutes;
  final int neutralMinutes;
  final List<AppConsumptionItem> topApps;
  final AppConsumptionItem? mostTimeConsumingApp;
  final String headline;
  final String recommendation;

  const MiddayDigest({
    required this.generatedAt,
    required this.totalMinutes,
    required this.productiveMinutes,
    required this.distractedMinutes,
    required this.neutralMinutes,
    required this.topApps,
    required this.mostTimeConsumingApp,
    required this.headline,
    required this.recommendation,
  });

  int get focusScore {
    if (totalMinutes <= 0) return 85;
    final score = ((productiveMinutes / totalMinutes) * 100).round();
    return score.clamp(10, 100);
  }

  String get formattedTotalTime {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
