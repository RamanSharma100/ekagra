import 'dart:async';
import '../datasources/productivity_datasource.dart';
import '../models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile> getUser();
  UserProfile? get currentUserSync;
  Stream<UserProfile> get userStream;
  Future<void> updateUser(UserProfile profile);
  Future<void> updateGoalMinutes(int minutes);
  Future<void> toggleDarkMode(bool isDark);
  Future<void> toggleVoice(bool isVoiceEnabled);
  Future<void> toggleAutoSpeak(bool autoSpeak);
  Future<void> setSpeechRate(double rate);
  Future<void> toggleNotifications(bool enabled);
  Future<void> toggleVoiceAnnouncements(bool enabled);
  Future<void> setGeminiApiKey(String? apiKey);
  Future<void> setAppCategory(String packageName, String category);
}

class DefaultUserRepository implements UserRepository {
  final ProductivityDataSource _dataSource;
  UserProfile? _cachedUser;
  final StreamController<UserProfile> _userController = StreamController<UserProfile>.broadcast();

  DefaultUserRepository({ProductivityDataSource? dataSource})
      : _dataSource = dataSource ?? const LocalProductivityDataSource();

  @override
  Stream<UserProfile> get userStream => _userController.stream;

  void _emitUpdate() {
    if (_cachedUser != null && !_userController.isClosed) {
      _userController.add(_cachedUser!);
    }
  }

  @override
  UserProfile? get currentUserSync => _cachedUser ?? _dataSource.getInitialUser();

  @override
  Future<UserProfile> getUser() async {
    _cachedUser ??= _dataSource.getInitialUser();
    return _cachedUser!;
  }

  @override
  Future<void> updateUser(UserProfile profile) async {
    _cachedUser = profile;
    _emitUpdate();
  }

  @override
  Future<void> updateGoalMinutes(int minutes) async {
    final user = await getUser();
    _cachedUser = user.copyWith(dailyFocusGoalMinutes: minutes);
    _emitUpdate();
  }

  @override
  Future<void> toggleDarkMode(bool isDark) async {
    final user = await getUser();
    _cachedUser = user.copyWith(isDarkMode: isDark);
    _emitUpdate();
  }

  @override
  Future<void> toggleVoice(bool isVoiceEnabled) async {
    final user = await getUser();
    _cachedUser = user.copyWith(voiceEnabled: isVoiceEnabled);
    _emitUpdate();
  }

  @override
  Future<void> toggleAutoSpeak(bool autoSpeak) async {
    final user = await getUser();
    _cachedUser = user.copyWith(autoSpeakResponses: autoSpeak);
    _emitUpdate();
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    final user = await getUser();
    _cachedUser = user.copyWith(speechRate: rate);
    _emitUpdate();
  }

  @override
  Future<void> toggleNotifications(bool enabled) async {
    final user = await getUser();
    _cachedUser = user.copyWith(notificationsEnabled: enabled);
    _emitUpdate();
  }

  @override
  Future<void> toggleVoiceAnnouncements(bool enabled) async {
    final user = await getUser();
    _cachedUser = user.copyWith(voiceAnnouncementsEnabled: enabled);
    _emitUpdate();
  }

  @override
  Future<void> setGeminiApiKey(String? apiKey) async {
    final user = await getUser();
    _cachedUser = user.copyWith(geminiApiKey: apiKey?.trim());
    _emitUpdate();
  }

  @override
  Future<void> setAppCategory(String packageName, String category) async {
    final user = await getUser();
    final updatedMap = Map<String, String>.from(user.customAppCategories);
    updatedMap[packageName] = category;
    _cachedUser = user.copyWith(customAppCategories: updatedMap);
    _emitUpdate();
  }
}
