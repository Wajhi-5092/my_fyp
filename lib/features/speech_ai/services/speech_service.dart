import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _shouldListen = false;
  Function(String)? _onResultCallback;

  bool get isListening => _speech.isListening;

  /// Initialize speech
  Future<bool> init() async {
    return await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        debugPrint("Speech error: $error");
      },
      debugLogging: true,
    );
  }

  /// Start listening (with auto-restart)
  Future<void> startListening(
    Function(String) onResult, {
    String locale = 'en_US',
  }) async {
    _shouldListen = true;
    _onResultCallback = onResult;

    await _startListeningInternal(locale);
  }

  /// Internal listen method
  Future<void> _startListeningInternal(String locale) async {
    if (!_speech.isAvailable) {
      debugPrint("Speech not available");
      return;
    }

    await _speech.listen(
      onResult: (result) {
        if (_onResultCallback != null) {
          _onResultCallback!(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
      pauseFor: const Duration(seconds: 30),
      listenFor: const Duration(minutes: 40),
      localeId: locale,
    );
  }

  /// Handle status changes (auto-restart logic)
  void _handleStatus(String status) {
    debugPrint("Speech status: $status");

    if (_shouldListen && (status == "done" || status == "notListening")) {
      debugPrint("Restarting listening...");
      _startListeningInternal('en_US');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    _shouldListen = false;
    await _speech.stop();
  }
}
