class AiMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isVoiceGenerated;
  final List<String>? suggestedActions;

  const AiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isVoiceGenerated = false,
    this.suggestedActions,
  });

  AiMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isVoiceGenerated,
    List<String>? suggestedActions,
  }) {
    return AiMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isVoiceGenerated: isVoiceGenerated ?? this.isVoiceGenerated,
      suggestedActions: suggestedActions ?? this.suggestedActions,
    );
  }
}
