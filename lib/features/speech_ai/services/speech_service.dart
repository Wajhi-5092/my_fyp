import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool get isListening => _speech.isListening;

  Future<bool> init({Function(String)? onStatus}) async {
    return await _speech.initialize(
      onStatus: (status) {
        debugPrint("Speech status: $status");
        if (onStatus != null) onStatus(status);
      },
      onError: (error) {
        debugPrint("Speech error: $error");
      },
      debugLogging: true,
    );
  }

  Future<void> listen(Function(String) onResult) async {
    if (!_speech.isAvailable) {
      debugPrint("Speech not available");
      return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation, // Smoother for continuous speech
      ),
      pauseFor: const Duration(seconds: 30), // Increased from 5s
      listenFor: const Duration(minutes: 5),
      localeId: 'en_US',
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
