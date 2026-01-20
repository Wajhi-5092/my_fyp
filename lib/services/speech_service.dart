import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    return await _speech.initialize(
      onStatus: (status) {
        print("Speech status: $status");
      },
      onError: (error) {
        print("Speech error: $error");
      },
      debugLogging: true,
    );
  }

  Future<void> listen(Function(String) onResult) async {
    if (!_speech.isAvailable) {
      print("Speech not available");
      return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
      ),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
