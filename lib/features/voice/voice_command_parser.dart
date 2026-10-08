import '../../core/services/ai_service.dart';
import '../../data/models/voice_command.dart';

abstract class VoiceCommandParser {
  Future<VoiceCommand> parse(String transcript);
}

class DefaultVoiceCommandParser implements VoiceCommandParser {
  final AiService aiService;

  DefaultVoiceCommandParser({required this.aiService});

  @override
  Future<VoiceCommand> parse(String transcript) async {
    return aiService.interpretVoiceCommand(transcript);
  }
}
