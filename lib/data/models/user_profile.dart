class UserProfile {
  final String id;
  final String name;
  final String email;
  final String title;
  final int dailyFocusGoalMinutes;
  final int currentStreakDays;
  final bool voiceEnabled;
  final bool autoSpeakResponses;
  final bool voiceAnnouncementsEnabled;
  final double speechRate;
  final double speechPitch;
  final bool notificationsEnabled;
  final bool isDarkMode;
  final String? geminiApiKey;
  final Map<String, String> customAppCategories;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.title = 'Deep Work Practitioner',
    this.dailyFocusGoalMinutes = 240,
    this.currentStreakDays = 1,
    this.voiceEnabled = true,
    this.autoSpeakResponses = true,
    this.voiceAnnouncementsEnabled = true,
    this.speechRate = 1.0,
    this.speechPitch = 1.0,
    this.notificationsEnabled = true,
    this.isDarkMode = true,
    this.geminiApiKey,
    this.customAppCategories = const {},
  });

  bool get hasGeminiKey => geminiApiKey != null && geminiApiKey!.trim().isNotEmpty;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? title,
    int? dailyFocusGoalMinutes,
    int? currentStreakDays,
    bool? voiceEnabled,
    bool? autoSpeakResponses,
    bool? voiceAnnouncementsEnabled,
    double? speechRate,
    double? speechPitch,
    bool? notificationsEnabled,
    bool? isDarkMode,
    String? geminiApiKey,
    Map<String, String>? customAppCategories,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      title: title ?? this.title,
      dailyFocusGoalMinutes:
          dailyFocusGoalMinutes ?? this.dailyFocusGoalMinutes,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      autoSpeakResponses: autoSpeakResponses ?? this.autoSpeakResponses,
      voiceAnnouncementsEnabled:
          voiceAnnouncementsEnabled ?? this.voiceAnnouncementsEnabled,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      customAppCategories: customAppCategories ?? this.customAppCategories,
    );
  }
}
