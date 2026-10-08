import 'dart:async';

enum AppNotificationType {
  focusStarted,
  nudge,
  stepAwayAlert,
  halfwayPace,
  completed,
  goalMilestone,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final AppNotificationType type;
  final bool isDelivered;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.type = AppNotificationType.nudge,
    this.isDelivered = false,
  });
}

abstract class NotificationService {
  Stream<AppNotification> get notificationStream;
  Future<void> sendNotification({
    required String title,
    required String body,
    AppNotificationType type = AppNotificationType.nudge,
  });
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required Duration delay,
    AppNotificationType type = AppNotificationType.nudge,
  });
  Future<void> cancelAll();
}

class DefaultNotificationService implements NotificationService {
  final _notificationController = StreamController<AppNotification>.broadcast();
  final List<Timer> _activeTimers = [];

  @override
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  @override
  Future<void> sendNotification({
    required String title,
    required String body,
    AppNotificationType type = AppNotificationType.nudge,
  }) async {
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      scheduledTime: DateTime.now(),
      type: type,
      isDelivered: true,
    );
    _notificationController.add(notif);
  }

  @override
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required Duration delay,
    AppNotificationType type = AppNotificationType.nudge,
  }) async {
    final timer = Timer(delay, () {
      sendNotification(title: title, body: body, type: type);
    });
    _activeTimers.add(timer);
  }

  @override
  Future<void> cancelAll() async {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  void dispose() {
    cancelAll();
    _notificationController.close();
  }
}
