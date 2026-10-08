import 'package:flutter/material.dart';

class BlockedApp {
  final String id;
  final String name;
  final String packageName;
  final IconData icon;
  final String category;
  final bool isBlocked;
  final bool isInstalled;
  final int todayMinutes;
  final int blockedAttemptsToday;

  const BlockedApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.icon,
    this.category = 'Social & Media',
    this.isBlocked = true,
    this.isInstalled = true,
    this.todayMinutes = 0,
    this.blockedAttemptsToday = 0,
  });

  BlockedApp copyWith({
    String? id,
    String? name,
    String? packageName,
    IconData? icon,
    String? category,
    bool? isBlocked,
    bool? isInstalled,
    int? todayMinutes,
    int? blockedAttemptsToday,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isBlocked: isBlocked ?? this.isBlocked,
      isInstalled: isInstalled ?? this.isInstalled,
      todayMinutes: todayMinutes ?? this.todayMinutes,
      blockedAttemptsToday: blockedAttemptsToday ?? this.blockedAttemptsToday,
    );
  }
}
