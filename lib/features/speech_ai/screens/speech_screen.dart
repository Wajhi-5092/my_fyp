import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../home/screens/ai_screen.dart';
import '../services/speech_service.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechService _speechService = SpeechService();
  final TextEditingController _textController = TextEditingController(
    text: 'Tap the microphone to start listening...',
  );
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _manuallyStopped = false;
  bool _isRestarting = false;
  String _previousText = '';

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startListening() async {
    if (_isRestarting && _isListening) return;
    _isRestarting = true;

    final available = await _speechService.init(
      onStatus: (status) {
        debugPrint("Status changed: $status");
        if (status == 'done') {
          if (!_manuallyStopped && mounted) {
            debugPrint("Auto-restarting listening...");
            _previousText = _textController.text.trim();
            _startListening();
          } else {
            setState(() {
              _isListening = false;
              _isRestarting = false;
            });
          }
        }
      },
    );

    if (available && mounted) {
      setState(() {
        _isListening = true;
        _manuallyStopped = false;
        _isRestarting = false;
        if (_textController.text ==
            'Tap the microphone to start listening...') {
          _textController.clear();
          _previousText = '';
        } else {
          _previousText = _textController.text.trim();
        }
      });

      await _speechService.listen((words) {
        if (!mounted) return;
        setState(() {
          String separator = _previousText.isNotEmpty && words.isNotEmpty
              ? ' '
              : '';
          _textController.text = _previousText + separator + words;
        });
        _scrollToBottom();
      });
    } else {
      setState(() => _isRestarting = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      await _startListening();
    } else {
      _manuallyStopped = true;
      await _speechService.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      resizeToAvoidBottomInset: true,
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
        child: Column(
          children: [
            // Response Container (Glassmorphism)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F32).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  scrollController: _scrollController,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.6,
                    color: _isListening
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                    fontWeight: _isListening
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Speak something...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ),

            // Bottom Control Area
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_textController.text.isNotEmpty &&
                      !_isListening &&
                      _textController.text !=
                          'Tap the microphone to start listening...')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionBtn(
                            label: "RETRY",
                            color: Colors.redAccent,
                            onTap: () {
                              setState(() {
                                _textController.text =
                                    'Tap the microphone to start listening...';
                                _previousText = '';
                              });
                            },
                            isOutline: true,
                          ),
                          const SizedBox(width: 20),
                          _buildActionBtn(
                            label: "PROCEED",
                            color: const Color(0xFFFFB300),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AiAssistantScreen(
                                    initialPrompt: _textController.text,
                                  ),
                                ),
                              );
                            },
                            isOutline: false,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        AvatarGlow(
                          animate: _isListening,
                          glowColor: const Color(0xFFFFB300),
                          duration: const Duration(milliseconds: 2000),
                          repeat: true,
                          child: GestureDetector(
                            onTap: _toggleListening,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isListening
                                      ? [
                                          const Color(0xFFFFB300),
                                          const Color(0xFFFF8F00),
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
                                            0xFFFFB300,
                                          ).withValues(alpha: 0.4)
                                        : Colors.black45,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _isListening ? "Listening..." : "Tap to Speak",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isOutline,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isOutline ? color.withValues(alpha: 0.1) : null,
            gradient: isOutline
                ? null
                : LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(30),
            border: isOutline ? Border.all(color: color, width: 1.5) : null,
            boxShadow: isOutline
                ? []
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F111A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
