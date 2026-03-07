import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/tomorrow-night.dart';

class MessageBubble extends StatefulWidget {
  final Map msg;
  const MessageBubble({super.key, required this.msg});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    bool isUser = widget.msg["role"] == "user";

    final String text = (widget.msg["text"] ?? "").toString();
    if (text.isEmpty) return const SizedBox.shrink();

    // Detect code blocks
    final regex = RegExp(r'```(\w*)\n([\s\S]*?)```');
    final matches = regex.allMatches(text);

    List<Widget> children = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        children.add(
          Text(
            widget.msg["text"].substring(lastEnd, match.start).trim(),
            style: TextStyle(
              color: isUser
                  ? const Color(0xFF0F111A)
                  : Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
        );
      }
      final code = match.group(2) ?? '';
      final lang = match.group(1)?.toLowerCase() ?? 'text';

      children.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser
                ? const Color(0xFFFF8F00)
                : const Color(0xFF0F111A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              code.trim(),
              language: lang.isEmpty ? 'text' : lang,
              theme: tomorrowNightTheme,
              textStyle: const TextStyle(
                fontFamily: 'SourceCodePro',
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      children.add(
        Text(
          text.substring(lastEnd).trim(),
          style: TextStyle(
            color: isUser
                ? const Color(0xFF0F111A)
                : Colors.white.withOpacity(0.9),
            fontSize: 15,
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF1B1F32),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...children,
                      if (!isUser && hovering)
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.msg["text"]),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Copied"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                isUser ? "You" : "AI Assistant",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
