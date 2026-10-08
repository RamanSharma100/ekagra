import 'package:flutter/material.dart';

enum InsightType {
  peakProductivity,
  distractionReduction,
  sessionLength,
  bestDay,
  routineAdherence,
}

class Insight {
  final String id;
  final String headline;
  final String description;
  final String metricHighlight;
  final InsightType type;
  final IconData icon;
  final DateTime generatedAt;
  final bool isAiGenerated;
  final String? actionLabel;
  final String? actionType;
  final Color? accentColor;

  const Insight({
    required this.id,
    required this.headline,
    required this.description,
    required this.metricHighlight,
    required this.type,
    required this.icon,
    required this.generatedAt,
    this.isAiGenerated = true,
    this.actionLabel,
    this.actionType,
    this.accentColor,
  });
}
