import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/app_blocker_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/voice_service.dart';
import '../../data/models/focus_session.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/repositories/user_repository.dart';

enum FocusSessionState {
  idle,
  active,
  paused,
  completed,
}

enum AmbientSound {
  none,
  rain,
  whiteNoise,
  forest;

  String get displayName {
    switch (this) {
      case AmbientSound.none:
        return 'Mute';
      case AmbientSound.rain:
        return 'Rain';
      case AmbientSound.whiteNoise:
        return 'White Noise';
      case AmbientSound.forest:
        return 'Forest';
    }
  }
}

class FocusViewModel extends ChangeNotifier {
  final ProductivityRepository repository;
  final NotificationService? notificationService;
  final VoiceService? voiceService;
  final UserRepository? userRepository;
  AppBlockerService? _appBlockerService;

  AppBlockerService? get appBlockerService => _appBlockerService;

  void setAppBlockerService(AppBlockerService service) {
    _appBlockerService = service;
  }

  FocusSessionState _state = FocusSessionState.idle;
  FocusMode _selectedMode = FocusMode.deepWork;
  int _targetMinutes = 45;
  String _goalNote = '';
  int _remainingSeconds = 45 * 60;
  int _elapsedSeconds = 0;
  AmbientSound _ambientSound = AmbientSound.none;
  Timer? _ticker;
  FocusSession? _currentSession;
  int _rating = 5;

  FocusViewModel({
    required this.repository,
    this.notificationService,
    this.voiceService,
    this.userRepository,
  });

  FocusSessionState get state => _state;
  FocusMode get selectedMode => _selectedMode;
  int get targetMinutes => _targetMinutes;
  String get goalNote => _goalNote;
  int get remainingSeconds => _remainingSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  AmbientSound get ambientSound => _ambientSound;
  FocusSession? get currentSession => _currentSession;
  int get rating => _rating;

  bool get isActive => _state == FocusSessionState.active;
  bool get isPaused => _state == FocusSessionState.paused;
  bool get isCompleted => _state == FocusSessionState.completed;

  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedElapsedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progressRatio {
    final totalSeconds = _targetMinutes * 60;
    if (totalSeconds <= 0) return 0.0;
    return (_elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  void selectMode(FocusMode mode) {
    if (_state != FocusSessionState.idle) return;
    _selectedMode = mode;
    notifyListeners();
  }

  void selectDuration(int minutes) {
    if (_state != FocusSessionState.idle) return;
    _targetMinutes = minutes;
    _remainingSeconds = minutes * 60;
    notifyListeners();
  }

  void setGoalNote(String note) {
    _goalNote = note;
    notifyListeners();
  }

  void setAmbientSound(AmbientSound sound) {
    _ambientSound = sound;
    notifyListeners();
  }

  void setRating(int value) {
    _rating = value.clamp(1, 5);
    notifyListeners();
  }

  void startSession({int? durationMinutes, FocusMode? mode, String? note}) {
    if (durationMinutes != null) {
      _targetMinutes = durationMinutes;
      _remainingSeconds = durationMinutes * 60;
    }
    if (mode != null) {
      _selectedMode = mode;
    }
    if (note != null) {
      _goalNote = note;
    }

    _elapsedSeconds = 0;
    _remainingSeconds = _targetMinutes * 60;

    _currentSession = FocusSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: _goalNote.isNotEmpty ? _goalNote : _selectedMode.displayName,
      mode: _selectedMode,
      targetMinutes: _targetMinutes,
      actualMinutes: 0,
      startedAt: DateTime.now(),
      note: _goalNote,
      isCompleted: false,
    );

    _state = FocusSessionState.active;
    _startTicker();

    final title = _goalNote.isNotEmpty ? _goalNote : _selectedMode.displayName;
    final voiceEnabled = userRepository?.currentUserSync?.voiceAnnouncementsEnabled ?? true;

    appBlockerService?.startBackgroundFocusService(
      sessionTitle: title,
      remainingSeconds: _remainingSeconds,
      voiceAnnouncementsEnabled: voiceEnabled,
    );

    if (voiceEnabled) {
      voiceService?.speak("Focus session started. Protecting your attention for $_targetMinutes minutes.");
    }

    notificationService?.sendNotification(
      title: "Focus Session Started",
      body: "${_selectedMode.displayName} (${_targetMinutes}m) active. Distractions are shielded.",
      type: AppNotificationType.focusStarted,
    );
    notifyListeners();
  }

  void pauseSession() {
    if (_state == FocusSessionState.active) {
      _ticker?.cancel();
      _state = FocusSessionState.paused;
      final voiceEnabled = userRepository?.currentUserSync?.voiceAnnouncementsEnabled ?? true;
      appBlockerService?.updateBackgroundFocusService(
        remainingSeconds: _remainingSeconds,
        isPaused: true,
        voiceAnnouncementsEnabled: voiceEnabled,
      );
      if (voiceEnabled) {
        voiceService?.speak("Focus session paused.");
      }
      notifyListeners();
    }
  }

  void resumeSession() {
    if (_state == FocusSessionState.paused) {
      _state = FocusSessionState.active;
      _startTicker();
      final voiceEnabled = userRepository?.currentUserSync?.voiceAnnouncementsEnabled ?? true;
      appBlockerService?.updateBackgroundFocusService(
        remainingSeconds: _remainingSeconds,
        isPaused: false,
        voiceAnnouncementsEnabled: voiceEnabled,
      );
      if (voiceEnabled) {
        voiceService?.speak("Resuming focus session. Stay in the zone.");
      }
      notifyListeners();
    }
  }

  void notifyAppSwitchAway() {
    if (isActive) {
      notificationService?.sendNotification(
        title: "⚠️ Stepped Away from Focus Session",
        body: "Your session is running ($formattedRemainingTime left). App Shield is active — return to stay focused.",
        type: AppNotificationType.stepAwayAlert,
      );
    }
  }

  void endSession() {
    _ticker?.cancel();
    final actualMins = (_elapsedSeconds / 60).ceil();

    appBlockerService?.stopBackgroundFocusService();

    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        actualMinutes: actualMins,
        endedAt: DateTime.now(),
        isCompleted: true,
      );
    }

    _state = FocusSessionState.completed;
    final voiceEnabled = userRepository?.currentUserSync?.voiceAnnouncementsEnabled ?? true;
    if (voiceEnabled) {
      voiceService?.speak("Focus session complete. Well done!");
    }

    notificationService?.sendNotification(
      title: "Focus Session Complete!",
      body: "Well done! You dedicated $actualMins minutes to deep attention.",
      type: AppNotificationType.completed,
    );
    notifyListeners();
  }

  Future<void> submitCompletionRating(int rating) async {
    _rating = rating;
    if (_currentSession != null) {
      final finished = _currentSession!.copyWith(
        rating: rating,
        isCompleted: true,
      );
      await repository.saveFocusSession(finished);
    }
    resetToIdle();
  }

  void resetToIdle() {
    _ticker?.cancel();
    appBlockerService?.stopBackgroundFocusService();
    _state = FocusSessionState.idle;
    _elapsedSeconds = 0;
    _remainingSeconds = _targetMinutes * 60;
    _currentSession = null;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _elapsedSeconds++;

        // Keep background service & widget in sync periodically
        if (_remainingSeconds % 10 == 0) {
          appBlockerService?.updateBackgroundFocusService(
            remainingSeconds: _remainingSeconds,
            isPaused: false,
          );
        }

        // Halfway point nudge
        if (_elapsedSeconds == (_targetMinutes * 60) ~/ 2) {
          notificationService?.sendNotification(
            title: "Halfway Momentum Nudge",
            body: "You're halfway through! ${_remainingSeconds ~/ 60}m remaining. Keep flow state.",
            type: AppNotificationType.halfwayPace,
          );
        }
        notifyListeners();
      } else {
        _elapsedSeconds++;
        endSession();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
