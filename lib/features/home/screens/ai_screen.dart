import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../widgets/ai/message_bubble.dart';
import '../widgets/ai/style_dialog.dart';
import '../widgets/ai/chat_input.dart';
import '../../../core/services/style_service.dart';
import '../widgets/ai/chat_drawer.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/ai/ai_empty_state.dart';

class AiAssistantScreen extends StatefulWidget {
  final String? initialPrompt;
  final String? lectureId;
  final bool persistInitialResponseToLecture;
  final bool autoSendInitialPrompt;
  final String? initialChatId;

  const AiAssistantScreen({
    super.key,
    this.initialPrompt,
    this.lectureId,
    this.persistInitialResponseToLecture = false,
    this.autoSendInitialPrompt = true,
    this.initialChatId,
  });
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
  bool isLoadingHistory = false;
  bool _savedInitialLectureResponse = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    if (userEmail == null) return;

    await fetchUserChats();

    if (widget.initialChatId != null && widget.initialChatId!.isNotEmpty) {
      await loadChatHistory(widget.initialChatId!);
      return;
    }

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      if (widget.autoSendInitialPrompt) {
        await createNewChat(initialText: widget.initialPrompt);
      } else {
        await createNewChat();
        if (mounted) {
          setState(() {
            controller.text = widget.initialPrompt!;
          });
        }
      }
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
      isLoadingHistory = true;
    });
    try {
      final res = await ApiService.getChatHistory(chatId);
      if (res["success"] && mounted) {
        setState(() {
          // Reverse because list is reverse: true
          // Filter out 'system' messages and then map 'content' (backend) to 'text' (frontend)
          messages = (res["data"]["messages"] as List)
              .where((m) => m["role"] != "system")
              .toList()
              .reversed
              .map((m) {
                return {
                  "role": m["role"],
                  "text": m["text"] ?? m["content"] ?? "",
                };
              })
              .toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingHistory = false);
      }
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

  Future<void> deleteChat(String chatId) async {
    final res = await ApiService.deleteChat(chatId);
    if (res["success"]) {
      await fetchUserChats();
      if (currentChatId == chatId) {
        if (userChats.isNotEmpty) {
          loadChatHistory(userChats.first['chat_id']);
        } else {
          await createNewChat();
        }
      }
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
        .where((m) => (m["text"] ?? m["content"] ?? "").toString().isNotEmpty)
        .map(
          (m) => {
            "role": m["role"].toString(),
            "content": (m["text"] ?? m["content"] ?? "").toString(),
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
        if (widget.persistInitialResponseToLecture &&
            !_savedInitialLectureResponse &&
            widget.lectureId != null &&
            widget.initialPrompt != null &&
            text == widget.initialPrompt) {
          final saveRes = await ApiService.updateLectureAiResponse(
            lectureId: widget.lectureId!,
            aiResponse: fullReply,
            lecturePrompt: widget.initialPrompt,
            chatId: currentChatId,
          );
          if (saveRes["success"] == true) {
            _savedInitialLectureResponse = true;
          }
        }
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_open_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        title: const Text(
          "AI Assistant",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color.fromARGB(255, 0, 0, 0)),
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
              onDeleteChat: (id) {
                deleteChat(id);
              },
              onLogout: () async {
                await StyleService.logout();
                if (context.mounted) {
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
            child: isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  )
                : messages.isEmpty && !isTyping
                ? const AiEmptyState()
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
