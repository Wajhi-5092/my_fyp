import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:my_fyp/services/gemini.dart';
import 'package:my_fyp/services/speech_service.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechService _speechService = SpeechService();
  String _text = 'Tap the microphone to start listening...';
  bool _isListening = false;

  Future<void> _toggleListening() async {
    if (!_isListening) {
      final available = await _speechService.init();
      if (!available) return;

      setState(() => _isListening = true);

      _speechService.listen((words) {
        if (!mounted) return;
        setState(() => _text = words);
      });
    } else {
      _speechService.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Voice Assistant",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Response Container (Glassmorphism)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _text,
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.5,
                        color: _isListening ? Colors.white : Colors.white54,
                        fontWeight: _isListening
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
              if (_text.isNotEmpty &&
                  !_isListening &&
                  _text != 'Tap the microphone to start listening...')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retry Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _text = 'Tap the microphone to start listening...';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: const Text(
                          "RETRY",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    // Proceed Button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GeminiScreen(initialPrompt: _text),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF007AFF)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00E5FF,
                              ).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Text(
                          "PROCEED",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    AvatarGlow(
                      animate: _isListening,
                      glowColor: const Color(0xFF00E5FF),
                      duration: const Duration(milliseconds: 2000),
                      repeat: true,
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [
                                      const Color(0xFF00E5FF),
                                      const Color(0xFF007AFF),
                                    ]
                                  : [
                                      Colors.grey.shade800,
                                      Colors.grey.shade900,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isListening
                                    ? const Color(
                                        0xFF00E5FF,
                                      ).withValues(alpha: 0.4)
                                    : Colors.black26,
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isListening ? "Listening..." : "Tap to Speak",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
