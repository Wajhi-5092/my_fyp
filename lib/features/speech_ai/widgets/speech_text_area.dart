import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpeechTextArea extends StatelessWidget {
  final TextEditingController textController;
  final ScrollController scrollController;
  final bool isListening;

  const SpeechTextArea({
    super.key,
    required this.textController,
    required this.scrollController,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              103,
              39,
              46,
              63,
            ).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: textController,
            scrollController: scrollController,
            maxLines: null,
            expands: true,
            style: TextStyle(
              fontSize: 20,
              height: 1.6,
              color: isListening ? Colors.white : Colors.white,
              fontWeight: isListening ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Speak something...',
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
        ),
        if (textController.text.isNotEmpty &&
            textController.text != 'Tap the microphone to start listening...')
          Positioned(
            top: 20,
            right: 30,
            child: IconButton(
              icon: const Icon(
                Icons.copy_rounded,
                color: Colors.white70,
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: textController.text),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Text copied to clipboard!"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
