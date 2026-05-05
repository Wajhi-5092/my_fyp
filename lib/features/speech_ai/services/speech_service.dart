import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audio_session/audio_session.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _shouldListen = false;
  bool _isManuallyStopped = false;

  Function(String)? _onResultCallback;

  String _finalText = "";
  String _lastPartial = "";

  Timer? _restartTimer;

  bool get isListening => _speech.isListening;

  /// Initialize speech
  Future<bool> init() async {
    return await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        debugPrint("Speech error: $error");
        _restartSafely();
      },
      debugLogging: true,
    );
  }

  /// Configure audio session (noise cancellation)
  Future<void> configureAudioSession(bool enableNoiseCancel) async {
    final session = await AudioSession.instance;

    if (enableNoiseCancel) {
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
        ),
      );
    } else {
      await session.configure(const AudioSessionConfiguration.speech());
    }
  }

  /// Start listening
  Future<void> startListening(
    Function(String) onResult, {
    String locale = 'en_US',
  }) async {
    _shouldListen = true;
    _isManuallyStopped = false;
    _onResultCallback = onResult;

    _finalText = "";
    _lastPartial = "";

    await _startListeningInternal(locale);
  }

  /// Internal listening logic
  Future<void> _startListeningInternal(String locale) async {
    if (!_speech.isAvailable) {
      debugPrint("Speech not available");
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (_onResultCallback == null) return;

          if (result.finalResult) {
            // Append final result
            _finalText += " ${result.recognizedWords}";
            _lastPartial = "";
            _onResultCallback!(_finalText.trim());
          } else {
            // Partial result
            _lastPartial = result.recognizedWords;
            _onResultCallback!(("$_finalText $_lastPartial").trim());
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
        pauseFor: const Duration(seconds: 60),
        listenFor: const Duration(minutes: 30),
        localeId: locale,
      );
    } catch (e) {
      debugPrint("Listen error: $e");
      _restartSafely();
    }
  }

  /// Handle status updates
  void _handleStatus(String status) {
    debugPrint("Speech status: $status");

    if (_isManuallyStopped) return;

    if (_shouldListen && (status == "done" || status == "notListening")) {
      _restartSafely();
    }
  }

  /// Smart restart (debounced)
  void _restartSafely() {
    _restartTimer?.cancel();

    _restartTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!_shouldListen || _isManuallyStopped) return;

      try {
        await _speech.stop();
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 200));

      if (_shouldListen) {
        debugPrint("Restarting listening...");
        _startListeningInternal('en_US');
      }
    });
  }

  /// Stop listening
  Future<void> stopListening() async {
    _shouldListen = false;
    _isManuallyStopped = true;

    _restartTimer?.cancel();

    try {
      await _speech.stop();
    } catch (_) {}
  }
}
