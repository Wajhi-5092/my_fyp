import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/style_dialog.dart';
import '../widgets/chat_input.dart';
import '../../../core/services/style_service.dart';
import '../widgets/chat_drawer.dart';
import '../../auth/screens/login_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  final String? initialPrompt;
  const AiAssistantScreen({super.key, this.initialPrompt});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  List<String> selectedStyles = StyleService.selectedStyles;
  List<dynamic> userChats = [];
  String? currentChatId;
  String? userEmail = StyleService.currentUserEmail;

  bool isTyping = false;
  bool stopTyping = false;
  bool isLoadingChats = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    if (userEmail == null) return;

    await fetchUserChats();

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      await createNewChat(initialText: widget.initialPrompt);
    } else if (userChats.isNotEmpty) {
      loadChatHistory(userChats.first['chat_id']);
    } else {
      await createNewChat();
    }
  }

  Future<void> fetchUserChats() async {
    if (userEmail == null) return;
    setState(() => isLoadingChats = true);
    try {
      final res = await ApiService.getChats(userEmail!);
      if (res["success"]) {
        setState(() {
          userChats = res["data"];
        });
      }
    } finally {
      setState(() => isLoadingChats = false);
    }
  }

  Future<void> loadChatHistory(String chatId) async {
    setState(() {
      currentChatId = chatId;
      messages = [];
    });
    final res = await ApiService.getChatHistory(chatId);
    if (res["success"] && mounted) {
      setState(() {
        // Reverse because list is reverse: true
        messages = List.from(res["data"]["messages"].reversed);
      });
    }
  }

  Future<void> createNewChat({String? initialText}) async {
    if (userEmail == null) return;
    final res = await ApiService.newChat(userEmail!);
    if (res["success"]) {
      final newChatId = res["data"]["chat_id"];
      await fetchUserChats();
      setState(() {
        currentChatId = newChatId;
        messages = [];
      });
      if (initialText != null) {
        sendMessage(initialText);
      }
    }
  }

  Future<void> clearAllChats() async {
    if (userEmail == null) return;
    final res = await ApiService.clearChats(userEmail!);
    if (res["success"]) {
      await fetchUserChats();
      await createNewChat();
    }
  }

  Future<void> sendMessage(String text) async {
    if (isTyping || userEmail == null || currentChatId == null) return;

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
        email: userEmail!,
        chatId: currentChatId!,
        styles: selectedStyles,
        history: history,
      );

      if (result["success"]) {
        String fullReply = result["data"]["response"];
        await animateTyping(fullReply);
        fetchUserChats(); // Refresh list to update last message
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
        onApply: (newStyles) async {
          final updated = newStyles.isEmpty ? ["short"] : newStyles;
          await StyleService.saveStyles(updated);
          if (mounted) {
            setState(() {
              selectedStyles = updated;
            });
          }
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
      drawer: userEmail == null
          ? null
          : ChatDrawer(
              chats: userChats,
              activeChatId: currentChatId,
              userEmail: userEmail!,
              onChatSelected: (id) {
                Navigator.pop(context);
                loadChatHistory(id);
              },
              onNewChat: () {
                Navigator.pop(context);
                createNewChat();
              },
              onClearChats: () {
                Navigator.pop(context);
                clearAllChats();
              },
              onLogout: () async {
                await StyleService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty && !isTyping
                ? Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 100,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Start a conversation...",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ask me anything you want!",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
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
