import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../common/widget.dart';
import '../models/widget.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _selectedMessageId;

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 1,
      'text': 'Hi Sarah, I have a shift on Friday (8am-6pm). Would you be open to swapping with your Saturday shift?',
      'isMe': false,
      'time': '12:00pm',
      'status': 'read',
      'dateDivider': 'May 10, 2026',
    },
    {
      'id': 2,
      'text': 'Hi! I can do that, but only if it\'s confirmed early—I have plans.',
      'isMe': true,
      'time': '12:00pm',
      'status': 'read',
    },
    {
      'id': 3,
      'text': 'That works. I\'ll submit the swap request now.',
      'isMe': false,
      'time': '12:00pm',
      'status': 'read',
    },
    {
      'id': 4,
      'text': 'Hi I added money. I\'ve submitted a leave request for 10-14 June due to a family matter...',
      'isMe': true,
      'time': '12:00pm',
      'status': 'read',
      'dateDivider': 'May 15, 2026',
    },
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isMe': true, 'time': 'now'});
    });
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/chat_background.png"),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A3E), Color(0xFF0D1B3E), Color(0xFF0A1628)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 70,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: widget.user.avatarColor,
            backgroundImage: AssetImage(widget.user.userAvatar),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildActionIcon(icon: Iconsax.cloud, filled: false),
                    const SizedBox(width: 8),
                    _buildActionIcon(icon: Iconsax.home_wifi, filled: false),
                    const SizedBox(width: 8),
                    _buildActionIcon(icon: Iconsax.eye_slash, filled: false),
                  ]
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              navBarVisible.value = true;
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: Colors.white12, shape: BoxShape.circle),
              child: Icon(Iconsax.close_circle, size: 35),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, required bool filled}) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF007AFF) : Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: filled ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final msgId = msg['id'];
    final isSelected = _selectedMessageId == msgId;

    return GestureDetector(
      onLongPress: isMe
          ? () => setState(() => _selectedMessageId = msgId)
          : null,
      onTap: () {
        if (_selectedMessageId != null) {
          setState(() => _selectedMessageId = null);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 4),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // 👇 Faded purple when selected, normal purple otherwise
                color: isMe
                    ? (isSelected
                    ? const Color(0xFF6C47FF).withOpacity(0.35)
                    : const Color(0xFF6C47FF))
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg['text'] as String,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg['time'] as String,
                        style: TextStyle(
                          color: isMe ? Colors.white60 : Colors.black38,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 13, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 👇 Action bar appears below the bubble on long press
          if (isSelected && isMe) _buildMessageActionBar(msgId),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildMessageActionBar(int? msgId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionChip(
            icon: Icons.flash_on,
            label: null,
            iconColor: Colors.white,
            bgColor: const Color(0xFF2A2A2A),
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.flash_on,
            label: 'ASAP',
            iconColor: Colors.white,
            bgColor: const Color(0xFF2A2A2A),
            onTap: () {
              setState(() => _selectedMessageId = null);
              // handle ASAP action
            },
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.info_outline,
            label: 'Urgent',
            iconColor: const Color(0xFFF39C12),
            bgColor: const Color(0xFF2A2A2A),
            onTap: () {
              setState(() => _selectedMessageId = null);
              // handle Urgent action
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    String? label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A45).withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: Colors.white38, size: 20),
          const SizedBox(width: 8),
          const Icon(Icons.emoji_emotions_outlined,
              color: Colors.white38, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 100, // 🔥 max height before scrolling
              ),
              child: TextField(
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline, // ✅ Enter = new line
                minLines: 1,
                maxLines: null, // ✅ allows expansion
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
