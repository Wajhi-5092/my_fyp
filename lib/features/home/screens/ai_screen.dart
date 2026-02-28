import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/style_dialog.dart';
import '../widgets/chat_input.dart';

class AiAssistantScreen extends StatefulWidget {
  final String? initialPrompt;
  const AiAssistantScreen({super.key, this.initialPrompt});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  List<String> selectedStyles = ["short"];

  bool isTyping = false; // AI generating response
  bool stopTyping = false; // Stop flag

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sendMessage(widget.initialPrompt!);
      });
    }
  }

  Future<void> sendMessage(String text) async {
    if (isTyping) return;

    setState(() {
      messages.insert(0, {"role": "user", "text": text});
      isTyping = true;
      stopTyping = false;
    });
    _scrollToBottom();

    // Prepare history for backend (chronological order)
    List<Map<String, String>> history = messages.reversed
        .where((m) => m["text"].toString().isNotEmpty)
        .map(
          (m) => {
            "role": m["role"].toString(),
            "content": m["text"].toString(),
          },
        )
        .toList();

    // Remove the latest user message from history as it's sent as 'prompt'
    if (history.isNotEmpty) history.removeLast();

    try {
      final result = await ApiService.chat(
        prompt: text,
        styles: selectedStyles,
        history: history,
      );

      if (result["success"]) {
        String fullReply = result["data"]["response"];
        await animateTyping(fullReply);
      } else {
        throw Exception(result["error"]);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        isTyping = false;
      });
    }
  }

  Future<void> animateTyping(String text) async {
    String currentText = "";
    setState(() {
      messages.insert(0, {"role": "assistant", "text": ""});
    });

    int i = 0;
    while (i < text.length) {
      if (stopTyping) {
        setState(() {
          messages[0]["text"] = currentText + text.substring(i);
        });
        break;
      }

      int batchSize = 3;
      int end = (i + batchSize < text.length) ? i + batchSize : text.length;
      currentText += text.substring(i, end);
      i = end;

      setState(() {
        messages[0]["text"] = currentText;
      });

      await Future.delayed(const Duration(milliseconds: 5));
      _scrollToBottom();
    }
  }

  void stopResponse() {
    if (isTyping) {
      setState(() {
        stopTyping = true;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> showStyleSettings() async {
    await showDialog(
      context: context,
      builder: (context) => StyleDialog(
        initialStyles: selectedStyles,
        onApply: (newStyles) {
          setState(() {
            selectedStyles = newStyles.isEmpty ? ["short"] : newStyles;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "AI Assistant",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: showStyleSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  MessageBubble(msg: messages[index]),
            ),
          ),
          ChatInput(
            controller: controller,
            isTyping: isTyping,
            onSend: () {
              if (controller.text.isNotEmpty) {
                sendMessage(controller.text);
                controller.clear();
              }
            },
            onStop: stopResponse,
          ),
        ],
      ),
    );
  }
}
