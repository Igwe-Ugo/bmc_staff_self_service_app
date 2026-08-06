import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';
import '../common/widget.dart';
import 'chat_ui_utils.dart';

class ChatScreen extends StatefulWidget {
  /// 1-on-1 target. Mutually exclusive with [group].
  final SocketUser? peer;

  /// Group target. Mutually exclusive with [peer].
  final ChatGroup? group;

  const ChatScreen({super.key, this.peer, this.group})
    : assert(
        (peer != null) != (group != null),
        'ChatScreen needs exactly one of peer or group',
      );

  bool get isGroup => group != null;

  /// Other party's USERNAME for 1-on-1, or the groupId for groups — matches
  /// ChatProvider's conversation keying exactly.
  String get conversationKey => isGroup ? group!.id : peer!.userId;

  /// Display name for the app bar.
  String get title => isGroup ? group!.name : peer!.username;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final ChatProvider _chatProvider;
  String? _selectedMessageId;

  // Set by the ASAP / Urgent action chips on a long-pressed message — applied
  // to the NEXT message sent, then cleared. This is what actually drives the
  // schema's `urgency` and `replyTo` fields; the mock UI had these chips
  // wired to nothing.
  MessageReply? _pendingReplyTo;
  MessageUrgency? _pendingUrgency;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatProvider.openConversation(
      widget.conversationKey,
      isGroup: widget.isGroup,
    );
    _messageController.addListener(_handleTypingChanged);
  }

  void _handleTypingChanged() {
    if (_messageController.text.trim().isEmpty) return;
    _chatProvider.notifyTyping(widget.conversationKey, isGroup: widget.isGroup);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatProvider.stopTypingNow(
      widget.conversationKey,
      isGroup: widget.isGroup,
    );
    _chatProvider.send(
      to: widget.conversationKey,
      content: text,
      isGroup: widget.isGroup,
      urgency: _pendingUrgency ?? MessageUrgency.normal,
      replyTo: _pendingReplyTo,
    );

    _messageController.clear();
    setState(() {
      _pendingReplyTo = null;
      _pendingUrgency = null;
    });

    // No optimistic insert — the server echoes the message back with its
    // minted id, and that echo is what actually lands in ChatProvider's
    // state and triggers this rebuild.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _selectForQuickAction(ChatMessage message) {
    setState(() => _selectedMessageId = message.id);
  }

  void _applyQuickAction(ChatMessage message, MessageUrgency urgency) {
    setState(() {
      _pendingReplyTo = MessageReply(
        id: message.id,
        from: message.from,
        content: message.content,
      );
      _pendingUrgency = urgency;
      _selectedMessageId = null;
    });
  }

  void _clearPendingReply() {
    setState(() {
      _pendingReplyTo = null;
      _pendingUrgency = null;
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTypingChanged);
    _chatProvider.closeConversation();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.messagesWith(widget.conversationKey);
    final isPeerTyping =
        !widget.isGroup && chat.isTyping(widget.conversationKey);

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
              _buildAppBar(context, isPeerTyping),
              Expanded(child: _buildMessageList(messages, chat.me)),
              if (_pendingReplyTo != null) _buildPendingReplyBar(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isPeerTyping) {
    final presence = widget.isGroup ? null : context.watch<PresenceProvider>();
    final online = widget.isGroup
        ? false
        : (presence?.isReachable(widget.peer!.userId) ?? false);

    return Container(
      height: 65,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColorFor(widget.peer!.userId),
            child: widget.peer?.avatar != null
                ? UserAvatar(
                    image: widget.peer!.avatar,
                    initials: initialsFor(widget.peer!.username),
                    radius: 17,
                    initialsColor: Colors.white,
                  )
                :  CircleAvatar(
                                      radius: 13,
                                      backgroundColor:
                                          avatarColorFor(widget.peer!.userId),
                                      child: Text(
                                        initialsFor(widget.peer!.username),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPeerTyping
                      ? 'typing…'
                      : (widget.isGroup
                            ? '${widget.group!.members.length} members'
                            : (online ? 'Online' : 'Offline')),
                  style: TextStyle(
                    fontSize: 11,
                    color: isPeerTyping
                        ? Theme.of(context).primaryColor
                        : (online ? const Color(0xFF34C759) : Colors.white38),
                    fontWeight: isPeerTyping
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
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
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.close_circle, size: 27),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, String me) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet — say hi!',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final showDivider =
            i == 0 || !isSameDay(messages[i - 1].time, msg.time);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDivider) _buildDateDivider(msg.time),
            _buildBubble(msg, me),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formatDateDivider(time),
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, String me) {
    final isMe = msg.from == me;
    final isSelected = _selectedMessageId == msg.id;
    // Group read receipt: everyone else in the group has read it.
    // 1-on-1 read receipt: the `read` flag.
    final isRead = widget.isGroup
        ? widget.group!.members
              .where((m) => m != me)
              .every((m) => msg.readBy.contains(m))
        : msg.read;

    return GestureDetector(
      onLongPress: isMe ? () => _selectForQuickAction(msg) : null,
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
                  if (msg.replyTo != null)
                    _buildQuotedReply(msg.replyTo!, isMe),
                  if (msg.urgency != MessageUrgency.normal)
                    _buildUrgencyBadge(msg.urgency, isMe),
                  Text(
                    msg.content,
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
                        formatMessageTime(msg.time),
                        style: TextStyle(
                          color: isMe ? Colors.white60 : Colors.black38,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 13,
                          color: isRead
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSelected && isMe) _buildMessageActionBar(msg),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildQuotedReply(MessageReply reply, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white70 : const Color(0xFF6C47FF),
            width: 3,
          ),
        ),
      ),
      child: Text(
        reply.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: isMe ? Colors.white70 : Colors.black54,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(MessageUrgency urgency, bool isMe) {
    final label = urgency == MessageUrgency.urgent ? 'URGENT' : 'ASAP';
    final color = urgency == MessageUrgency.urgent
        ? const Color(0xFFF39C12)
        : const Color(0xFF007AFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageActionBar(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionChip(
            icon: Icons.close,
            label: null,
            iconColor: Colors.white,
            bgColor: const Color(0xFF2A2A2A),
            onTap: () => setState(() => _selectedMessageId = null),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.flash_on,
            label: 'ASAP',
            iconColor: Colors.white,
            bgColor: const Color(0xFF2A2A2A),
            onTap: () => _applyQuickAction(msg, MessageUrgency.asap),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.info_outline,
            label: 'Urgent',
            iconColor: const Color(0xFFF39C12),
            bgColor: const Color(0xFF2A2A2A),
            onTap: () => _applyQuickAction(msg, MessageUrgency.urgent),
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

  /// Shown above the input bar once a quick action has staged a reply +
  /// urgency for the next message. Lets the user back out before sending.
  Widget _buildPendingReplyBar() {
    final reply = _pendingReplyTo!;
    final urgency = _pendingUrgency;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A45).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          if (urgency != null && urgency != MessageUrgency.normal) ...[
            _buildUrgencyBadge(urgency, false),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              reply.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: _clearPendingReply,
            child: const Icon(Icons.close, size: 16, color: Colors.white38),
          ),
        ],
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
          // TODO: wire to a file/image picker (e.g. file_picker or
          // image_picker), base64-encode the bytes, and build a
          // MessageAttachment(name, type, size, data) to pass into
          // ChatProvider.send(file: ...).
          const Icon(Icons.attach_file, color: Colors.white38, size: 20),
          const SizedBox(width: 8),
          const Icon(
            Icons.emoji_emotions_outlined,
            color: Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: TextField(
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: null,
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
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
