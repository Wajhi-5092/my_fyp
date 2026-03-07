import 'package:flutter/material.dart';

class ChatDrawer extends StatelessWidget {
  final List<dynamic> chats;
  final String? activeChatId;
  final String userEmail;
  final Function(String) onChatSelected;
  final VoidCallback onNewChat;
  final VoidCallback onLogout;
  final VoidCallback onClearChats;

  const ChatDrawer({
    super.key,
    required this.chats,
    required this.activeChatId,
    required this.userEmail,
    required this.onChatSelected,
    required this.onNewChat,
    required this.onLogout,
    required this.onClearChats,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simplified Profile Header
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
                            color: Colors.black87,
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

            // New Chat Button - Prominent but clean
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
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

            // Chat List
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
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            selected: isSelected,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            selectedTileColor: Colors.blue.withOpacity(0.08),
                            leading: Icon(
                              Icons.chat_outlined,
                              size: 20,
                              color: isSelected ? Colors.blue : Colors.black54,
                            ),
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
                            onTap: () => onChatSelected(chat['chat_id']),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            // Clear Chats
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Color.fromARGB(229, 234, 17, 17),
                size: 20,
                fontWeight: FontWeight.bold,
              ),
              title: const Text(
                "Delete Chats",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _showClearConfirmation(context),
            ),

            // Logout Action
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              title: const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }

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
}
