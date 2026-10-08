import 'dart:async';
import 'package:flutter/services.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
}

abstract class VoiceService {
  VoiceState get currentState;
  Stream<VoiceState> get stateStream;

  Future<void> speak(String text);
  Future<void> playAlertTone();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setVolume(double volume);
}

/// Robust built-in VoiceService implementation that manages voice playback states,
/// simulated natural voice timing, and hooks for platform TTS plugins.
class DefaultVoiceService implements VoiceService {
  static const MethodChannel _shieldChannel = MethodChannel('com.ekagra.app/app_shield');

  final _stateController = StreamController<VoiceState>.broadcast();
  VoiceState _state = VoiceState.idle;
  Timer? _speakingTimer;
  double _rate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;

  @override
  VoiceState get currentState => _state;

  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;

  @override
  Stream<VoiceState> get stateStream => _stateController.stream;

  void _updateState(VoiceState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> speak(String text) async {
    _speakingTimer?.cancel();
    _updateState(VoiceState.speaking);

    try {
      await _shieldChannel.invokeMethod('speak', {'text': text});
    } catch (_) {}

    // Approximate natural speech duration based on word count and speech rate
    final wordCount = text.split(RegExp(r'\s+')).length;
    final durationSeconds = (wordCount / (2.6 * _rate)).clamp(2.0, 15.0);

    _speakingTimer = Timer(Duration(milliseconds: (durationSeconds * 1000).toInt()), () {
      if (_state == VoiceState.speaking) {
        _updateState(VoiceState.idle);
      }
    });
  }

  @override
  Future<void> playAlertTone() async {
    try {
      await _shieldChannel.invokeMethod('playAlertTone');
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    _speakingTimer?.cancel();
    _updateState(VoiceState.idle);
  }

  @override
  Future<void> resume() async {
    _updateState(VoiceState.speaking);
  }

  @override
  Future<void> stop() async {
    _speakingTimer?.cancel();
    _updateState(VoiceState.idle);
  }

  @override
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  void dispose() {
    _speakingTimer?.cancel();
    _stateController.close();
  }
}
