import 'package:flutter/material.dart';

class ChatDrawer extends StatelessWidget {
  final List<dynamic> chats;
  final String? activeChatId;
  final String userEmail;
  final Function(String) onChatSelected;
  final VoidCallback onNewChat;
  final VoidCallback onLogout;
  final VoidCallback onClearChats;
  final Function(String) onDeleteChat;

  const ChatDrawer({
    super.key,
    required this.chats,
    required this.activeChatId,
    required this.userEmail,
    required this.onChatSelected,
    required this.onNewChat,
    required this.onLogout,
    required this.onClearChats,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PROFILE HEADER
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade800,
                    child: Text(
                      userEmail[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userEmail.split('@')[0],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// NEW CHAT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton.icon(
                onPressed: onNewChat,
                icon: const Icon(Icons.add, size: 20),
                label: const Text("New Conversation"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// RECENT CHATS HEADER
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                "RECENT CHATS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),

            /// CHAT LIST
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: Text(
                        "No history yet",
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final isSelected = chat['chat_id'] == activeChatId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isSelected
                                ? Colors.blue.withValues(alpha: 0.08)
                                : Colors.transparent,
                          ),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),

                            /// CHAT ICON
                            leading: Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                              color: isSelected ? Colors.blue : Colors.black54,
                            ),

                            /// CHAT TITLE
                            title: Text(
                              chat['last_message'] ?? "Untitled Chat",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),

                            /// DELETE ICON
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Color.fromARGB(255, 173, 41, 41),
                              ),
                              onPressed: () {
                                _showDeleteConfirmation(
                                  context,
                                  chat['chat_id'],
                                );
                              },
                            ),

                            onTap: () => onChatSelected(chat['chat_id']),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            /// CLEAR ALL CHATS
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
              title: const Text(
                "Delete All Chats",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onTap: () => _showClearConfirmation(context),
            ),

            ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(left: 3),
                child: Icon(Icons.logout_rounded, color: Colors.red, size: 20),
              ),
              title: const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  /// DELETE SINGLE CHAT
  void _showDeleteConfirmation(BuildContext context, String chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Chat?"),
        content: const Text("This conversation will be permanently deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteChat(chatId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// CLEAR ALL CHATS
  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History?"),
        content: const Text("This will permanently delete all your chats."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClearChats();
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// LOGOUT CONFIRMATION
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out?"),
        content: const Text(
          "Are you sure you want to sign out of your account?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onLogout(); // Execute logout
            },
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
