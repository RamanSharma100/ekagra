enum VoiceIntent {
  startFocus,
  endFocus,
  pauseFocus,
  resumeFocus,
  getProductivitySummary,
  getAppUsage,
  planDay,
  setGoal,
  unknown;

  static VoiceIntent fromString(String str) {
    switch (str.toLowerCase()) {
      case 'start_focus':
        return VoiceIntent.startFocus;
      case 'end_focus':
        return VoiceIntent.endFocus;
      case 'pause_focus':
        return VoiceIntent.pauseFocus;
      case 'resume_focus':
        return VoiceIntent.resumeFocus;
      case 'get_productivity_summary':
        return VoiceIntent.getProductivitySummary;
      case 'get_app_usage':
        return VoiceIntent.getAppUsage;
      case 'plan_day':
        return VoiceIntent.planDay;
      case 'set_goal':
        return VoiceIntent.setGoal;
      default:
        return VoiceIntent.unknown;
    }
  }
}

class VoiceCommand {
  final String rawTranscript;
  final VoiceIntent intent;
  final Map<String, dynamic> parameters;
  final double confidence;

  const VoiceCommand({
    required this.rawTranscript,
    required this.intent,
    required this.parameters,
    this.confidence = 1.0,
  });
}
