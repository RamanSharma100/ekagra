import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/app_blocker_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/voice_service.dart';
import '../../data/models/ai_message.dart';
import '../../data/models/voice_command.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../voice/voice_command_handler.dart';
import '../voice/voice_command_parser.dart';

class AiCompanionViewModel extends ChangeNotifier {
  final AiService aiService;
  final VoiceService voiceService;
  final SpeechRecognitionService speechService;
  final VoiceCommandParser commandParser;
  final VoiceCommandHandler commandHandler;
  final UserRepository userRepository;
  final ProductivityRepository? productivityRepository;
  AppBlockerService? appBlockerService;

  final List<AiMessage> _messages = [];
  VoiceState _voiceState = VoiceState.idle;
  String _currentStatusText = "Tap the microphone to speak";
  String _liveTranscript = "";
  String? _lastSpokenResponse;
  bool _isAutoSpeakEnabled = true;

  StreamSubscription? _voiceStateSub;

  AiCompanionViewModel({
    required this.aiService,
    required this.voiceService,
    required this.speechService,
    required this.commandParser,
    required this.commandHandler,
    required this.userRepository,
    this.productivityRepository,
    this.appBlockerService,
  }) {
    _initialize();
  }

  List<AiMessage> get messages => List.unmodifiable(_messages);
  VoiceState get voiceState => _voiceState;
  String get currentStatusText => _currentStatusText;
  String get liveTranscript => _liveTranscript;
  String? get lastSpokenResponse => _lastSpokenResponse;
  bool get isAutoSpeakEnabled => _isAutoSpeakEnabled;

  void _initialize() {
    // Initial welcome message
    final user = userRepository.currentUserSync;
    final userName = user?.name.trim().isNotEmpty == true ? user!.name.trim() : null;
    final greeting = userName != null ? "Hello $userName." : "Greetings.";

    _messages.add(
      AiMessage(
        id: 'msg_init',
        text: "$greeting I'm your focus companion. How can I help you protect your attention today?",
        isUser: false,
        timestamp: DateTime.now(),
        suggestedActions: [
          "How did I do today?",
          "Start 45m focus",
          "Plan my afternoon",
        ],
      ),
    );

    _voiceStateSub = voiceService.stateStream.listen((state) {
      _voiceState = state;
      if (state == VoiceState.speaking) {
        _currentStatusText = "Speaking...";
      } else if (state == VoiceState.idle && _voiceState != VoiceState.listening) {
        _currentStatusText = "Ready to listen";
      }
      notifyListeners();
    });

    userRepository.getUser().then((u) {
      _isAutoSpeakEnabled = u.autoSpeakResponses;
      notifyListeners();
    });
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _currentStatusText = "Reflecting...";
    notifyListeners();

    try {
      // Check if it's a voice/text actionable command first
      final parsed = await commandParser.parse(text);
      if (parsed.intent != VoiceIntent.unknown) {
        final result = await commandHandler.handle(parsed);
        final aiMsg = AiMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: result.speechResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(aiMsg);
        _lastSpokenResponse = result.speechResponse;
        if (_isAutoSpeakEnabled) {
          await voiceService.speak(result.speechResponse);
        }
      } else {
        Map<String, dynamic>? contextData;
        if (productivityRepository != null) {
          try {
            final score = await productivityRepository!.getTodayScore();
            final user = await userRepository.getUser();
            final activities = await productivityRepository!.getTodayActivities();
            final blocked = appBlockerService?.totalBlockedAttempts ?? 0;

            String? topApp;
            int topAppMins = 0;
            if (activities.isNotEmpty) {
              final sorted = List.of(activities)..sort((a, b) => b.duration.compareTo(a.duration));
              topApp = sorted.first.name;
              topAppMins = sorted.first.duration.inMinutes;
            }

            contextData = {
              'userName': user.name,
              'craft': user.title,
              'productiveMinutes': score.productiveMinutes,
              'distractedMinutes': score.distractedMinutes,
              'goalMinutes': user.dailyFocusGoalMinutes,
              'flowScore': score.score,
              'blockedCount': blocked,
              ?topApp: topApp,
              if (topAppMins > 0) 'topAppMinutes': topAppMins,
            };
          } catch (_) {}
        }

        final aiMsg = await aiService.sendMessage(text, context: contextData);
        _messages.add(aiMsg);
        _lastSpokenResponse = aiMsg.text;
        if (_isAutoSpeakEnabled) {
          await voiceService.speak(aiMsg.text);
        }
      }
    } finally {
      _currentStatusText = "Ready to listen";
      notifyListeners();
    }
  }

  Future<void> toggleVoiceInteraction() async {
    if (_voiceState == VoiceState.listening) {
      await stopListeningAndProcess();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    await voiceService.stop();
    _voiceState = VoiceState.listening;
    _currentStatusText = "Listening...";
    _liveTranscript = "";
    notifyListeners();

    await speechService.startListening();
  }

  Future<void> processVoiceInput(String phrase) async {
    _liveTranscript = phrase;
    _voiceState = VoiceState.processing;
    _currentStatusText = "Understanding...";
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    await sendTextMessage(phrase);
  }

  Future<void> stopListeningAndProcess([String? mockPhrase]) async {
    final transcript = await speechService.stopListening();
    final phrase = (transcript.isNotEmpty)
        ? transcript
        : (mockPhrase ?? "How did I do today?");

    await processVoiceInput(phrase);
  }

  Future<void> stopSpeaking() async {
    await voiceService.stop();
    _voiceState = VoiceState.idle;
    _currentStatusText = "Ready to listen";
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceStateSub?.cancel();
    super.dispose();
  }
}
