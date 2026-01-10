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
    );
    isListening = true;
  }

  void stop() {
    _speech.stop();
    isListening = false;
  }
}
