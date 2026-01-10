import 'package:flutter/material.dart';
import 'package:my_fyp/services/speech_service.dart';
import '../widgets/speech_text_box.dart';
import '../widgets/mic_button.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechService _speechService = SpeechService();
  String _text = 'Tap the mic and start speaking';

  Future<void> _toggleListening() async {
    if (!_speechService.isListening) {
      final available = await _speechService.init();
      if (!available) return;

      _speechService.listen((words) {
        if (!mounted) return;
        setState(() => _text = words);
      });
    } else {
      _speechService.stop();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Speech to Text', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              Expanded(child: SpeechTextBox(text: _text)),
              const SizedBox(height: 20),
              MicButton(
                isListening: _speechService.isListening,
                canClear: _text.isNotEmpty,
                onMicPressed: _toggleListening,
                onClearPressed: () {
                  _speechService.stop();
                  setState(() => _text = '');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
