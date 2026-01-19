import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool isListening = false;

  Future<bool> init() async {
    return await _speech.initialize();
  }

  void listen(Function(String) onResult) {
    _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(partialResults: true),
      pauseFor: const Duration(
        seconds: 10,
      ), // Increased to allow pauses in speech
    );
    isListening = true;
  }

  void stop() {
    _speech.stop();
    isListening = false;
  }
}
