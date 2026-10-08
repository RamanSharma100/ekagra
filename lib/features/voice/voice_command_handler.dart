import '../../data/models/voice_command.dart';
import '../../data/repositories/productivity_repository.dart';

class VoiceCommandResult {
  final String speechResponse;
  final VoiceCommand command;
  final bool didPerformAction;

  const VoiceCommandResult({
    required this.speechResponse,
    required this.command,
    required this.didPerformAction,
  });
}

abstract class VoiceCommandHandler {
  Future<VoiceCommandResult> handle(VoiceCommand command);
}

class DefaultVoiceCommandHandler implements VoiceCommandHandler {
  final ProductivityRepository productivityRepository;
  final Function(int durationMinutes, String mode)? onStartFocusRequested;
  final Function()? onEndFocusRequested;
  final Function()? onPauseFocusRequested;
  final Function()? onResumeFocusRequested;

  DefaultVoiceCommandHandler({
    required this.productivityRepository,
    this.onStartFocusRequested,
    this.onEndFocusRequested,
    this.onPauseFocusRequested,
    this.onResumeFocusRequested,
  });

  @override
  Future<VoiceCommandResult> handle(VoiceCommand command) async {
    switch (command.intent) {
      case VoiceIntent.startFocus:
        final duration = command.parameters['duration'] as int? ?? 25;
        final mode = command.parameters['mode'] as String? ?? 'Deep Work';
        if (onStartFocusRequested != null) {
          onStartFocusRequested!(duration, mode);
        }
        return VoiceCommandResult(
          speechResponse: "Starting a $duration minute $mode session. Protecting your focus.",
          command: command,
          didPerformAction: true,
        );

      case VoiceIntent.endFocus:
        if (onEndFocusRequested != null) {
          onEndFocusRequested!();
        }
        return VoiceCommandResult(
          speechResponse: "Your focus session has ended. Well done taking time to concentrate.",
          command: command,
          didPerformAction: true,
        );

      case VoiceIntent.pauseFocus:
        if (onPauseFocusRequested != null) {
          onPauseFocusRequested!();
        }
        return VoiceCommandResult(
          speechResponse: "Session paused. Take a deep breath.",
          command: command,
          didPerformAction: true,
        );

      case VoiceIntent.resumeFocus:
        if (onResumeFocusRequested != null) {
          onResumeFocusRequested!();
        }
        return VoiceCommandResult(
          speechResponse: "Resuming session. Let's get back into the zone.",
          command: command,
          didPerformAction: true,
        );

      case VoiceIntent.getProductivitySummary:
        final score = await productivityRepository.getTodayScore();
        return VoiceCommandResult(
          speechResponse:
              "You focused for ${score.formattedProductive} today, with a focus score of ${score.score}. You're on track for your goal.",
          command: command,
          didPerformAction: true,
        );

      case VoiceIntent.getAppUsage:
        final app = command.parameters['app'] as String? ?? 'YouTube';
        final activities = await productivityRepository.getTodayActivities();
        final matched = activities.firstWhere(
          (a) => a.name.toLowerCase().contains(app.toLowerCase()),
          orElse: () => activities.first,
        );
        return VoiceCommandResult(
          speechResponse: "You spent ${matched.formattedDuration} on ${matched.name} today.",
          command: command,
          didPerformAction: true,
        );

      case VoiceIntent.planDay:
        return VoiceCommandResult(
          speechResponse:
              "I recommend starting with a 45-minute deep focus block now, followed by a 15-minute break and email wrap-up.",
          command: command,
          didPerformAction: true,
        );

      case VoiceIntent.setGoal:
      case VoiceIntent.unknown:
        return VoiceCommandResult(
          speechResponse:
              "I'm here. You can say 'start a 45 minute focus session', 'how productive was I today', or 'plan my day'.",
          command: command,
          didPerformAction: false,
        );
    }
  }
}
