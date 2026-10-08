import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/activity.dart';
import '../../data/models/blocked_app.dart';
import '../../data/repositories/productivity_repository.dart';

class AppBlockerService extends ChangeNotifier {
  static const MethodChannel _appsChannel = MethodChannel('com.ekagra.app/device_apps');
  static const MethodChannel _shieldChannel = MethodChannel('com.ekagra.app/app_shield');

  final ProductivityRepository? repository;
  StreamSubscription<List<Activity>>? _activitySub;

  bool _shieldActive = false;
  bool _isScanning = false;
  int _totalBlockedAttempts = 0;

  // Applications discovered on the device. Only apps where `isInstalled == true` are shown to the user.
  final List<BlockedApp> _apps = [
    const BlockedApp(
      id: 'app_yt',
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      icon: Icons.play_circle_fill_rounded,
      category: 'Entertainment',
      isBlocked: true,
      isInstalled: true,
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    ),
    const BlockedApp(
      id: 'app_ig',
      name: 'Instagram',
      packageName: 'com.instagram.android',
      icon: Icons.camera_alt_rounded,
      category: 'Social Media',
      isBlocked: true,
      isInstalled: true,
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    ),
    const BlockedApp(
      id: 'app_x',
      name: 'X (Twitter)',
      packageName: 'com.twitter.android',
      icon: Icons.alternate_email_rounded,
      category: 'Social Media',
      isBlocked: true,
      isInstalled: true,
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    ),
    const BlockedApp(
      id: 'app_reddit',
      name: 'Reddit',
      packageName: 'com.reddit.frontpage',
      icon: Icons.forum_rounded,
      category: 'News & Forums',
      isBlocked: true,
      isInstalled: true,
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    ),
    const BlockedApp(
      id: 'app_tiktok',
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      icon: Icons.music_video_rounded,
      category: 'Entertainment',
      isBlocked: true,
      isInstalled: false, // Not installed -> hidden
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    ),
    const BlockedApp(
      id: 'app_netflix',
      name: 'Netflix',
      packageName: 'com.netflix.mediaclient',
      icon: Icons.movie_creation_rounded,
      category: 'Entertainment',
      isBlocked: false,
      isInstalled: false, // Not installed -> hidden
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    ),
    const BlockedApp(
      id: 'app_discord',
      name: 'Discord',
      packageName: 'com.discord',
      icon: Icons.headset_mic_rounded,
      category: 'Messaging',
      isBlocked: false,
      isInstalled: true,
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    ),
  ];

  final Map<String, ActivityCategory> _userCategoryOverrides = {};

  AppBlockerService({this.repository}) {
    _initLiveTimeSync();
    scanInstalledApps();
    startStandbyBackgroundService();
  }

  bool get isShieldActive => _shieldActive;
  bool get isScanning => _isScanning;
  int get totalBlockedAttempts => _totalBlockedAttempts;

  /// Returns ONLY applications that are installed on the device.
  List<BlockedApp> get installedApps =>
      _apps.where((a) => a.isInstalled).toList();

  /// Returns only blocked applications that are installed.
  List<BlockedApp> get blockedApps =>
      _apps.where((a) => a.isInstalled && a.isBlocked).toList();

  void _initLiveTimeSync() {
    if (repository != null) {
      _activitySub = repository!.activitiesStream.listen((activities) {
        _recalculateUsageFromActivities(activities);
      });
      repository!.getTodayActivities().then((activities) {
        _recalculateUsageFromActivities(activities);
      });
    }
  }

  void _recalculateUsageFromActivities(List<Activity> activities) {
    for (int i = 0; i < _apps.length; i++) {
      final app = _apps[i];
      int mins = 0;
      for (final act in activities) {
        if (act.name.toLowerCase().contains(app.name.toLowerCase()) ||
            app.name.toLowerCase().contains(act.name.toLowerCase())) {
          mins += act.duration.inMinutes;
        }
      }
      _apps[i] = app.copyWith(todayMinutes: mins);
    }
    notifyListeners();
  }

  /// Starts the Android Foreground Service for system-wide background app blocking and live notification.
  Future<void> startBackgroundFocusService({
    required String sessionTitle,
    required int remainingSeconds,
    List<String>? targetBlockedPackages,
    bool voiceAnnouncementsEnabled = true,
  }) async {
    _shieldActive = true;
    notifyListeners();

    try {
      final pkgs = targetBlockedPackages ?? blockedApps.map((a) => a.packageName).toList();
      if (pkgs.isEmpty) {
        pkgs.addAll([
          'com.google.android.youtube',
          'com.instagram.android',
          'com.twitter.android',
          'com.reddit.frontpage',
        ]);
      }

      await _shieldChannel.invokeMethod('startFocusService', {
        'sessionTitle': sessionTitle,
        'remainingSeconds': remainingSeconds,
        'blockedPackages': pkgs,
        'voiceAnnouncementsEnabled': voiceAnnouncementsEnabled,
      });

      await updateWidget(
        sessionTitle: sessionTitle,
        remainingSeconds: remainingSeconds,
        isPaused: false,
      );
    } catch (e) {
      debugPrint('Failed to start native focus background service: $e');
    }
  }

  /// Starts background standby service that continuously monitors app usage into SQLite
  Future<void> startStandbyBackgroundService() async {
    try {
      await _shieldChannel.invokeMethod('startStandbyService');
    } catch (e) {
      debugPrint('Failed to start standby service: $e');
    }
  }

  /// Updates live countdown in notification panel and widget
  Future<void> updateBackgroundFocusService({
    required int remainingSeconds,
    bool isPaused = false,
    String? sessionTitle,
    bool? voiceAnnouncementsEnabled,
  }) async {
    try {
      final Map<String, dynamic> args = {
        'remainingSeconds': remainingSeconds,
        'isPaused': isPaused,
      };
      if (sessionTitle != null) {
        args['sessionTitle'] = sessionTitle;
      }
      if (voiceAnnouncementsEnabled != null) {
        args['voiceAnnouncementsEnabled'] = voiceAnnouncementsEnabled;
      }

      await _shieldChannel.invokeMethod('updateFocusService', args);

      await updateWidget(
        sessionTitle: sessionTitle ?? 'Deep Work',
        remainingSeconds: remainingSeconds,
        isPaused: isPaused,
      );
    } catch (_) {}
  }

  /// Sends updated voice announcement preference to the active native service
  Future<void> updateVoiceAnnouncements(bool enabled) async {
    try {
      await _shieldChannel.invokeMethod('updateFocusService', {
        'voiceAnnouncementsEnabled': enabled,
      });
    } catch (_) {}
  }

  /// Stops Android Foreground Service and removes notification
  Future<void> stopBackgroundFocusService() async {
    _shieldActive = false;
    notifyListeners();

    try {
      await _shieldChannel.invokeMethod('stopFocusService');
      await updateWidget(
        sessionTitle: 'Ready to Focus',
        remainingSeconds: 0,
        isPaused: false,
      );
    } catch (_) {}
  }

  /// Updates the Android Home Screen AppWidget
  Future<void> updateWidget({
    required String sessionTitle,
    required int remainingSeconds,
    bool isPaused = false,
  }) async {
    try {
      await _shieldChannel.invokeMethod('updateWidget', {
        'sessionTitle': sessionTitle,
        'remainingSeconds': remainingSeconds,
        'isPaused': isPaused,
      });
    } catch (_) {}
  }

  /// Requests the Android launcher to pin the Ekagra Focus Widget to the home screen
  Future<bool> pinWidget() async {
    try {
      final res = await _shieldChannel.invokeMethod<bool>('pinWidget');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers 12:00 PM Midday Focus Digest notification immediately
  Future<void> triggerMiddayDigestNotification() async {
    try {
      await _shieldChannel.invokeMethod('triggerMiddayDigestNotification');
    } catch (_) {}
  }

  /// Checks if app was launched via Midday Focus Digest notification
  Future<bool> checkPendingDigestAction() async {
    try {
      final res = await _shieldChannel.invokeMethod<bool>('getPendingDigestAction');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Pulls real per-app time spent from native SQLite database and UsageStats
  Future<List<Map<String, dynamic>>> fetchDailyAppUsageFromDatabase() async {
    try {
      final List<dynamic>? rawList =
          await _appsChannel.invokeMethod<List<dynamic>>('getDailyAppUsage');

      if (rawList != null && rawList.isNotEmpty) {
        final List<Map<String, dynamic>> result = [];
        int totalBlocked = 0;

        for (final item in rawList) {
          final map = Map<String, dynamic>.from(item as Map);
          final pkg = map['packageName']?.toString() ?? '';
          final mins = (map['totalMinutes'] as num?)?.toInt() ?? 0;
          final blocked = (map['blockedAttempts'] as num?)?.toInt() ?? 0;
          totalBlocked += blocked;

          result.add(map);

          // Update matching app in our list
          final index = _apps.indexWhere((a) => a.packageName == pkg);
          if (index >= 0) {
            _apps[index] = _apps[index].copyWith(
              todayMinutes: mins,
              blockedAttemptsToday: blocked,
            );
          }
        }

        _totalBlockedAttempts = totalBlocked;

        // Auto-sync discovered usage into the main ProductivityRepository timeline with smart descriptions
        if (repository != null) {
          for (final item in result) {
            final pkg = item['packageName']?.toString() ?? '';
            final name = item['appName']?.toString() ?? '';
            final mins = (item['totalMinutes'] as num?)?.toInt() ?? 0;
            final lastActiveMillis = (item['lastActive'] as num?)?.toInt() ?? 0;
            final timestamp = lastActiveMillis > 0
                ? DateTime.fromMillisecondsSinceEpoch(lastActiveMillis)
                : DateTime.now();

            if (mins > 0 && name.isNotEmpty && !pkg.contains('com.ekagra.app.ekagra')) {
              final isDistracting = _isDistractingPackage(pkg, name);
              final subcat = _resolveCategory(pkg, name);
              final category = _userCategoryOverrides[name.toLowerCase()] ??
                  _userCategoryOverrides[pkg.toLowerCase()] ??
                  _resolveActivityCategory(pkg, name);
              final desc = _generateSmartDescription(name, pkg, mins, isDistracting);
              final icon = _resolveIcon(pkg, subcat);

              final act = Activity(
                id: 'dev_act_${pkg.hashCode}',
                name: name,
                category: category,
                subcategory: subcat,
                duration: Duration(minutes: mins),
                timestamp: timestamp,
                icon: icon,
                description: desc,
              );
              await repository!.recordActivity(act);
            }
          }
        }

        notifyListeners();
        return result;
      }
    } catch (e) {
      debugPrint('Failed to query app usage database: $e');
    }
    return [];
  }

  /// Scans the host device for installed packages dynamically and syncs database
  Future<void> scanInstalledApps() async {
    _isScanning = true;
    notifyListeners();

    try {
      // 1. Platform channel query for real installed apps on Android (launchable + user apps)
      final List<dynamic>? platformApps =
          await _appsChannel.invokeMethod<List<dynamic>>('getInstalledApps');

      if (platformApps != null && platformApps.isNotEmpty) {
        final Set<String> installedPackageNames = {};

        for (final item in platformApps) {
          final map = Map<String, dynamic>.from(item as Map);
          final pkgName = map['packageName']?.toString() ?? '';
          final appName = map['name']?.toString() ?? '';
          if (pkgName.isEmpty || appName.isEmpty) continue;

          installedPackageNames.add(pkgName);

          final existingIndex = _apps.indexWhere((a) => a.packageName == pkgName);
          if (existingIndex >= 0) {
            _apps[existingIndex] = _apps[existingIndex].copyWith(
              isInstalled: true,
              name: appName,
            );
          } else {
            // New installed application dynamically discovered on device
            final isDistracting = _isDistractingPackage(pkgName, appName);
            final category = _resolveCategory(pkgName, appName);
            final icon = _resolveIcon(pkgName, category);

            _apps.add(
              BlockedApp(
                id: 'app_${pkgName.hashCode.abs()}',
                name: appName,
                packageName: pkgName,
                icon: icon,
                category: category,
                isBlocked: isDistracting,
                isInstalled: true,
                todayMinutes: 0,
                blockedAttemptsToday: 0,
              ),
            );
          }
        }

        // Mark any non-present apps as not installed
        for (int i = 0; i < _apps.length; i++) {
          if (!installedPackageNames.contains(_apps[i].packageName)) {
            _apps[i] = _apps[i].copyWith(isInstalled: false);
          }
        }
      }

      // 2. Query real SQLite usage database and sync timeline
      await fetchDailyAppUsageFromDatabase();
    } catch (_) {
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  bool _isDistractingPackage(String pkg, String name) {
    final lowerPkg = pkg.toLowerCase();
    final lowerName = name.toLowerCase();
    return lowerPkg.contains('youtube') ||
        lowerPkg.contains('instagram') ||
        lowerPkg.contains('twitter') ||
        lowerPkg.contains('reddit') ||
        lowerPkg.contains('tiktok') ||
        lowerPkg.contains('facebook') ||
        lowerPkg.contains('snapchat') ||
        lowerPkg.contains('netflix') ||
        lowerPkg.contains('primevideo') ||
        lowerPkg.contains('twitch') ||
        lowerPkg.contains('game') ||
        lowerPkg.contains('hotstar') ||
        lowerName.contains('reels') ||
        lowerName.contains('shorts');
  }

  bool _isProductivePackage(String pkg, String name) {
    final lowerPkg = pkg.toLowerCase();
    final lowerName = name.toLowerCase();

    return lowerPkg.contains('nyayasetu') ||
        lowerName.contains('nyayasetu') ||
        lowerPkg.contains('expo') ||
        lowerName.contains('expo') ||
        lowerPkg.contains('ekagra') ||
        lowerName.contains('ekagra') ||
        lowerPkg.contains('code') ||
        lowerName.contains('code') ||
        lowerPkg.contains('studio') ||
        lowerName.contains('studio') ||
        lowerPkg.contains('terminal') ||
        lowerName.contains('terminal') ||
        lowerPkg.contains('git') ||
        lowerName.contains('git') ||
        lowerPkg.contains('intellij') ||
        lowerPkg.contains('flutter') ||
        lowerPkg.contains('docs') ||
        lowerName.contains('docs') ||
        lowerPkg.contains('sheets') ||
        lowerName.contains('sheets') ||
        lowerPkg.contains('drive') ||
        lowerName.contains('drive') ||
        lowerPkg.contains('notion') ||
        lowerName.contains('notion') ||
        lowerPkg.contains('slack') ||
        lowerName.contains('slack') ||
        lowerPkg.contains('teams') ||
        lowerName.contains('teams') ||
        lowerPkg.contains('zoom') ||
        lowerName.contains('zoom') ||
        lowerPkg.contains('meet') ||
        lowerName.contains('meet') ||
        lowerPkg.contains('jira') ||
        lowerName.contains('jira') ||
        lowerPkg.contains('linear') ||
        lowerName.contains('linear') ||
        lowerPkg.contains('trello') ||
        lowerName.contains('trello') ||
        lowerPkg.contains('figma') ||
        lowerName.contains('figma') ||
        lowerPkg.contains('canva') ||
        lowerName.contains('canva') ||
        lowerPkg.contains('learn') ||
        lowerName.contains('learn') ||
        lowerPkg.contains('study') ||
        lowerName.contains('study') ||
        lowerPkg.contains('duolingo') ||
        lowerName.contains('duolingo') ||
        lowerPkg.contains('coursera') ||
        lowerName.contains('coursera') ||
        lowerPkg.contains('udemy') ||
        lowerName.contains('udemy') ||
        lowerPkg.contains('khan') ||
        lowerName.contains('khan') ||
        lowerPkg.contains('books') ||
        lowerName.contains('books') ||
        lowerPkg.contains('kindle') ||
        lowerName.contains('anki') ||
        lowerPkg.contains('todo') ||
        lowerName.contains('todo') ||
        lowerPkg.contains('task') ||
        lowerName.contains('task') ||
        lowerPkg.contains('calendar') ||
        lowerName.contains('calendar') ||
        lowerPkg.contains('calculator') ||
        lowerName.contains('calculator') ||
        lowerPkg.contains('gmail') ||
        lowerName.contains('gmail') ||
        lowerPkg.contains('outlook') ||
        lowerName.contains('outlook') ||
        lowerPkg.contains('mail') ||
        lowerName.contains('mail');
  }

  ActivityCategory _resolveActivityCategory(String pkg, String name) {
    if (_isDistractingPackage(pkg, name)) {
      return ActivityCategory.distracting;
    }
    if (_isProductivePackage(pkg, name)) {
      return ActivityCategory.productive;
    }
    return ActivityCategory.neutral;
  }

  String _resolveCategory(String pkg, String name) {
    final lowerPkg = pkg.toLowerCase();
    final lowerName = name.toLowerCase();

    if (lowerPkg.contains('nyayasetu') || lowerName.contains('nyayasetu')) {
      return 'Legal & Research';
    }
    if (lowerPkg.contains('expo') ||
        lowerName.contains('expo') ||
        lowerPkg.contains('code') ||
        lowerName.contains('code') ||
        lowerPkg.contains('studio') ||
        lowerName.contains('studio') ||
        lowerPkg.contains('terminal') ||
        lowerPkg.contains('github') ||
        lowerPkg.contains('git') ||
        lowerPkg.contains('flutter') ||
        lowerPkg.contains('intellij')) {
      return 'Development & Tools';
    }
    if (lowerPkg.contains('ekagra') || lowerName.contains('ekagra')) {
      return 'Focus & Mindfulness';
    }
    if (lowerPkg.contains('youtube') ||
        lowerPkg.contains('netflix') ||
        lowerPkg.contains('video') ||
        lowerPkg.contains('media') ||
        lowerPkg.contains('music') ||
        lowerPkg.contains('spotify') ||
        lowerPkg.contains('hotstar') ||
        lowerPkg.contains('twitch')) {
      return 'Entertainment';
    }
    if (lowerPkg.contains('instagram') ||
        lowerPkg.contains('twitter') ||
        lowerPkg.contains('reddit') ||
        lowerPkg.contains('facebook') ||
        lowerPkg.contains('tiktok') ||
        lowerPkg.contains('snapchat') ||
        lowerName.contains('social')) {
      return 'Social Media';
    }
    if (lowerPkg.contains('whatsapp') ||
        lowerPkg.contains('telegram') ||
        lowerPkg.contains('signal') ||
        lowerPkg.contains('discord') ||
        lowerPkg.contains('message') ||
        lowerPkg.contains('mail') ||
        lowerPkg.contains('gmail') ||
        lowerPkg.contains('outlook')) {
      return 'Messaging & Email';
    }
    if (lowerPkg.contains('chrome') ||
        lowerPkg.contains('browser') ||
        lowerPkg.contains('firefox') ||
        lowerPkg.contains('drive') ||
        lowerPkg.contains('docs') ||
        lowerPkg.contains('sheets') ||
        lowerPkg.contains('notes') ||
        lowerPkg.contains('notion') ||
        lowerPkg.contains('slack') ||
        lowerPkg.contains('teams') ||
        lowerPkg.contains('zoom') ||
        lowerPkg.contains('meet') ||
        lowerPkg.contains('jira') ||
        lowerPkg.contains('linear') ||
        lowerPkg.contains('calendar')) {
      return 'Productivity & Work';
    }
    if (lowerPkg.contains('game') || lowerPkg.contains('play.games')) {
      return 'Gaming';
    }
    if (lowerPkg.contains('launcher') ||
        lowerPkg.contains('permissioncontroller') ||
        lowerPkg.contains('gms') ||
        lowerPkg.contains('systemui') ||
        lowerPkg.contains('settings')) {
      return 'System & Utilities';
    }
    return 'Utilities';
  }

  IconData _resolveIcon(String pkg, String category) {
    final lowerPkg = pkg.toLowerCase();
    if (lowerPkg.contains('youtube')) return Icons.play_circle_fill_rounded;
    if (lowerPkg.contains('chrome') || lowerPkg.contains('browser')) return Icons.public_rounded;
    if (lowerPkg.contains('instagram')) return Icons.camera_alt_rounded;
    if (lowerPkg.contains('twitter')) return Icons.alternate_email_rounded;
    if (lowerPkg.contains('reddit')) return Icons.forum_rounded;
    if (lowerPkg.contains('mail') || lowerPkg.contains('gmail')) return Icons.mail_outline_rounded;
    if (lowerPkg.contains('message') || lowerPkg.contains('whatsapp') || lowerPkg.contains('telegram')) {
      return Icons.chat_bubble_outline_rounded;
    }
    if (lowerPkg.contains('settings')) return Icons.settings_rounded;
    if (lowerPkg.contains('camera')) return Icons.photo_camera_rounded;
    if (lowerPkg.contains('clock')) return Icons.access_time_rounded;
    if (lowerPkg.contains('calculator')) return Icons.calculate_outlined;
    if (lowerPkg.contains('game')) return Icons.sports_esports_rounded;
    if (lowerPkg.contains('music') || lowerPkg.contains('spotify')) return Icons.music_note_rounded;
    if (category == 'Social Media') return Icons.people_alt_outlined;
    if (category == 'Development & Tools') return Icons.terminal_rounded;
    if (category == 'Legal & Research') return Icons.gavel_rounded;
    if (category == 'Focus & Mindfulness') return Icons.self_improvement_rounded;
    if (category == 'Productivity' || category == 'Productivity & Work') return Icons.work_outline_rounded;
    return Icons.apps_rounded;
  }

  String _generateSmartDescription(String name, String pkg, int mins, bool isDistracting) {
    final lowerPkg = pkg.toLowerCase();
    final lowerName = name.toLowerCase();

    if (lowerPkg.contains('nyayasetu') || lowerName.contains('nyayasetu')) {
      return 'Legal research, compliance & case preparation ($mins mins)';
    } else if (lowerPkg.contains('expo') || lowerName.contains('expo')) {
      return 'Mobile application development & debugging ($mins mins)';
    } else if (lowerPkg.contains('ekagra') || lowerName.contains('ekagra')) {
      return 'Deep focus session & calm productivity dashboard ($mins mins)';
    } else if (lowerPkg.contains('youtube')) {
      return 'Watched videos & media playback ($mins mins)';
    } else if (lowerPkg.contains('chrome') || lowerPkg.contains('browser')) {
      return 'Web research & documentation reading ($mins mins)';
    } else if (lowerPkg.contains('gmail') || lowerPkg.contains('mail')) {
      return 'Email triage & inbox organization ($mins mins)';
    } else if (lowerPkg.contains('whatsapp') || lowerPkg.contains('telegram') || lowerPkg.contains('message')) {
      return 'Direct messaging & team coordination ($mins mins)';
    } else if (lowerPkg.contains('instagram') || lowerPkg.contains('tiktok')) {
      return 'Social feeds & video reels ($mins mins)';
    } else if (lowerPkg.contains('twitter')) {
      return 'News feed updates & status timeline ($mins mins)';
    } else if (lowerPkg.contains('reddit')) {
      return 'Community discussions & forum reading ($mins mins)';
    } else if (lowerPkg.contains('docs') || lowerPkg.contains('sheets') || lowerPkg.contains('drive')) {
      return 'Document editing & project drafting ($mins mins)';
    } else if (lowerPkg.contains('settings')) {
      return 'Device configuration & preferences ($mins mins)';
    } else if (lowerPkg.contains('game')) {
      return 'Gaming & recreation ($mins mins)';
    } else if (isDistracting) {
      return 'Attention distracted on entertainment app ($mins mins)';
    } else {
      return 'Application usage & active task ($mins mins)';
    }
  }

  void updateActivityCategory(Activity activity, ActivityCategory newCategory, {String? subcategory}) {
    _userCategoryOverrides[activity.name.toLowerCase()] = newCategory;
    final updated = activity.copyWith(
      category: newCategory,
      subcategory: subcategory ?? activity.subcategory,
    );
    repository?.recordActivity(updated);
    notifyListeners();
  }

  void setShieldActive(bool active) {
    _shieldActive = active;
    notifyListeners();
  }

  bool isAppBlocked(String packageNameOrId) {
    final lower = packageNameOrId.toLowerCase();
    final match = _apps.firstWhere(
      (a) => a.packageName.toLowerCase() == lower || a.id.toLowerCase() == lower,
      orElse: () => const BlockedApp(id: '', name: '', packageName: '', icon: Icons.apps),
    );
    return match.id.isNotEmpty && match.isBlocked;
  }

  void toggleAppBlock(String appIdOrPackage, bool block) {
    final lower = appIdOrPackage.toLowerCase();
    final index = _apps.indexWhere((a) => a.id.toLowerCase() == lower || a.packageName.toLowerCase() == lower);
    if (index >= 0) {
      _apps[index] = _apps[index].copyWith(isBlocked: block);
      notifyListeners();
    }
  }

  void toggleAppInstalled(String appId, bool installed) {
    final index = _apps.indexWhere((a) => a.id == appId);
    if (index >= 0) {
      _apps[index] = _apps[index].copyWith(isInstalled: installed);
      notifyListeners();
    }
  }

  void removeApp(String appId) {
    _apps.removeWhere((a) => a.id == appId);
    notifyListeners();
  }

  void addCustomApp(String name, String category, {String? packageName}) {
    final newApp = BlockedApp(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      packageName: packageName ?? 'com.${name.toLowerCase().replaceAll(' ', '')}.app',
      icon: Icons.apps_rounded,
      category: category,
      isBlocked: true,
      isInstalled: true,
      todayMinutes: 0,
      blockedAttemptsToday: 0,
    );
    _apps.add(newApp);
    notifyListeners();
  }

  void registerBlockedAttempt(String appId) {
    _totalBlockedAttempts++;
    final index = _apps.indexWhere((a) => a.id == appId);
    if (index >= 0) {
      final current = _apps[index];
      _apps[index] = current.copyWith(
        blockedAttemptsToday: current.blockedAttemptsToday + 1,
      );
    }
    notifyListeners();
  }

  // --- Google Play & Permissions Guidance Helpers ---

  Future<bool> checkUsagePermission() async {
    try {
      final res = await _shieldChannel.invokeMethod<bool>('checkUsagePermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await _shieldChannel.invokeMethod('requestUsagePermission');
    } catch (_) {}
  }

  Future<bool> checkOverlayPermission() async {
    try {
      final res = await _shieldChannel.invokeMethod<bool>('checkOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _shieldChannel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  Future<bool> checkNotificationPermission() async {
    try {
      final res = await _shieldChannel.invokeMethod<bool>('checkNotificationPermission');
      return res ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestNotificationPermission() async {
    try {
      await _shieldChannel.invokeMethod('requestNotificationPermission');
    } catch (_) {}
  }

  Future<bool> getOnboardingCompleted() async {
    try {
      final res = await _shieldChannel.invokeMethod<bool>('getOnboardingCompleted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setOnboardingCompleted([bool completed = true]) async {
    try {
      await _shieldChannel.invokeMethod('setOnboardingCompleted', {'completed': completed});
    } catch (_) {}
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    super.dispose();
  }
}
