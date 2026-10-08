import 'dart:async';

abstract class SpeechRecognitionService {
  bool get isListening;
  Stream<String> get transcriptStream;
  Stream<bool> get listeningStateStream;

  Future<void> startListening();
  Future<String> stopListening();
  Future<void> cancel();
}

class DefaultSpeechRecognitionService implements SpeechRecognitionService {
  final _transcriptController = StreamController<String>.broadcast();
  final _listeningController = StreamController<bool>.broadcast();
  bool _isListening = false;
  String _currentBuffer = '';
  Timer? _mockSpeechTimer;

  @override
  bool get isListening => _isListening;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<bool> get listeningStateStream => _listeningController.stream;

  @override
  Future<void> startListening() async {
    _isListening = true;
    _currentBuffer = '';
    _listeningController.add(true);
  }

  void simulateSpeechInput(String phrase) {
    if (!_isListening) return;
    _currentBuffer = phrase;
    _transcriptController.add(phrase);
  }

  @override
  Future<String> stopListening() async {
    _mockSpeechTimer?.cancel();
    _isListening = false;
    _listeningController.add(false);
    return _currentBuffer;
  }

  @override
  Future<void> cancel() async {
    _mockSpeechTimer?.cancel();
    _isListening = false;
    _currentBuffer = '';
    _listeningController.add(false);
  }

  void dispose() {
    _mockSpeechTimer?.cancel();
    _transcriptController.close();
    _listeningController.close();
  }
}
