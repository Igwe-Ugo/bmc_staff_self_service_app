import 'dart:io';
import 'dart:typed_data';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';
import '../../core/network/services/widget.dart';
import '../common/widget.dart';
import 'widget.dart';

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

  String get conversationKey => isGroup ? group!.id : peer!.userId;

  String get title => isGroup ? group!.name : peer!.username;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPicker = false;
  late final ChatProvider _chatProvider;

  // Stores emoji reactions per message ID: { messageId: '🔥' }
  final Map<String, String> _messageReactions = {};

  MessageReply? _pendingReplyTo;
  MessageUrgency _pendingUrgency = MessageUrgency.normal;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatProvider.openConversation(
      widget.conversationKey,
      isGroup: widget.isGroup,
    );
    _messageController.addListener(_handleTypingChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  /// Scroll directly to a specific message by its target ID
  void _scrollToMessage(String messageId, List<ChatMessage> messages) {
    if (!_scrollController.hasClients) return;

    final targetIndex = messages.indexWhere((m) => m.id == messageId);
    if (targetIndex == -1) return;

    // Estimate item position based on average message bubble height
    final estimatedOffset = targetIndex * 70.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetScroll = estimatedOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _onTextFieldTapEmoji() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    }
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
      urgency: _pendingUrgency,
      replyTo: _pendingReplyTo,
    );

    _messageController.clear();
    setState(() {
      _pendingReplyTo = null;
      _pendingUrgency = MessageUrgency.normal;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom(animated: true);
    });
  }

  void _stageReply(ChatMessage msg) {
    final allMessages = _chatProvider.messagesWith(widget.conversationKey);
    final senderDisplayName = _resolveDisplayName(msg.from, allMessages);
    setState(() {
      _pendingReplyTo = MessageReply(
        id: msg.id,
        from: senderDisplayName,
        content: msg.content,
      );
    });
  }

  /// Fallback userId -> full name map for anyone the roster (ChatProvider's
  /// `usernameFor`) doesn't know — e.g. a user who has since left and no
  /// longer appears in the roster, but is still referenced in old messages.
  /// Whenever someone swipes to reply, the resolved full name rides along
  /// in `MessageReply.from` on the outbound message (see `_stageReply`
  /// above); any already-loaded message that replies to another loaded
  /// message is therefore a free (senderUserId -> fullName) fact.
  Map<String, String> _harvestKnownNames(List<ChatMessage> allMessages) {
    // messageId -> sender userId, so we can map a reply back to its author.
    final senderOf = <String, String>{
      for (final m in allMessages) m.id: m.from,
    };

    final names = <String, String>{};
    for (final m in allMessages) {
      final reply = m.replyTo;
      if (reply == null || reply.from.isEmpty) continue;
      final originalSenderId = senderOf[reply.id];
      if (originalSenderId == null || originalSenderId.isEmpty) continue;
      names.putIfAbsent(originalSenderId, () => reply.from);
    }
    return names;
  }

  String _resolveDisplayName(
    String senderUserId,
    List<ChatMessage> allMessages,
  ) {
    final currentUsername = _chatProvider.me;

    // 1. The logged-in user, in either a 1-on-1 or a group.
    if (senderUserId == currentUsername) {
      return 'Me';
    }

    // 2. Direct 1-on-1 chat — we already have the peer's full name.
    if (!widget.isGroup &&
        widget.peer?.userId == senderUserId &&
        (widget.peer?.username.isNotEmpty ?? false)) {
      return widget.peer!.username;
    }

    // 3. The roster — ChatProvider's userId -> full name directory, seeded
    // at sign-in and covering group members too (the roster is the whole
    // user directory, not just 1-on-1 contacts).
    final rostered = _chatProvider.usernameFor(senderUserId);
    if (rostered != null && rostered.isNotEmpty) {
      return rostered;
    }

    // 4. Safety net for anyone the roster doesn't know (e.g. a departed
    // user still referenced in old messages): harvested from prior replies
    // already loaded for this conversation (see _harvestKnownNames).
    final harvested = _harvestKnownNames(allMessages)[senderUserId];
    if (harvested != null && harvested.isNotEmpty) {
      return harvested;
    }

    // 5. Unknown. Deliberately NOT falling back to widget.title here —
    // that's the chat's name (peer or group), not the sender's, and using
    // it mislabels every unresolved sender as the group/peer itself.
    return senderUserId;
  }

  void _clearPendingReply() {
    setState(() {
      _pendingReplyTo = null;
    });
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        if (!mounted) return;
        showMessage(
          'Could not read that file.',
          context,
          status: MessageStatus.error,
        );
        return;
      }

      if (bytes.length > AttachmentService.maxUploadBytes) {
        if (!mounted) return;
        showMessage(
          'Files must be 5 MB or smaller.',
          context,
          status: MessageStatus.error,
        );
        return;
      }

      final mimeType = _mimeTypeFor(file.extension);
      final text = _messageController.text.trim();

      await _chatProvider.sendWithAttachment(
        to: widget.conversationKey,
        isGroup: widget.isGroup,
        content: text.isNotEmpty ? text : 'Sent an attachment: ${file.name}',
        urgency: _pendingUrgency,
        replyTo: _pendingReplyTo,
        bytes: bytes,
        fileName: file.name,
        mimeType: mimeType,
      );

      _messageController.clear();
      setState(() {
        _pendingReplyTo = null;
        _pendingUrgency = MessageUrgency.normal;
      });
      _scrollToBottom(animated: true);
    } on AttachmentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send attachment: ${e.message}')),
      );
    } catch (e, st) {
      debugPrint('❌ _pickAndSendFile failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send attachment: $e')));
    }
  }

  String _mimeTypeFor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  void _showMessageOptionsMenu(ChatMessage msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final emojis = ['🙏', '🔥', '❤️', '👍', '😂', '😮'];
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Emoji Reactions Bar ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _messageReactions[msg.id] = emoji;
                      });
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  );
                }).toList(),
              ),

              // ── Delete Option (Only if sent by current user) ───────────────
              if (isMe) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Iconsax.trash, color: Colors.redAccent),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(msg);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
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
    final presence = widget.isGroup ? null : context.watch<PresenceProvider>();
    final online = widget.isGroup
        ? false
        : (presence?.isReachable(widget.peer?.userId ?? '') ?? false);

    final String currentId = widget.conversationKey;
    final String? avatarUrl = widget.isGroup ? null : widget.peer?.avatar;
    final String initials = initialsFor(widget.title);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            navBarVisible.value = true;
          },
          icon: const Icon(Icons.arrow_back, size: 18),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarColorFor(currentId),
              child: avatarUrl != null
                  ? UserAvatar(
                      image: avatarUrl,
                      initials: initials,
                      radius: 17,
                      initialsColor: Colors.white,
                    )
                  : CircleAvatar(
                      radius: 13,
                      backgroundColor: avatarColorFor(currentId),
                      child: Text(
                        initials,
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
                          : (online
                                ? const Color(0xFF34C759)
                                : Colors.grey.shade500),
                      fontWeight: isPeerTyping
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              Expanded(child: _buildMessageList(messages, chat.me)),
              if (_pendingReplyTo != null) _buildPendingReplyBar(),
              _buildInputBar(),
              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    textEditingController: _messageController,
                    config: Config(
                      height: 250,
                      checkPlatformCompatibility: true,
                      skinToneConfig: SkinToneConfig(rememberSkinTone: true),
                      categoryViewConfig: CategoryViewConfig(
                        iconColorSelected: Theme.of(context).primaryColor,
                        indicatorColor: Theme.of(context).primaryColor,
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        iconColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        buttonIconColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        buttonColor: Theme.of(context).scaffoldBackgroundColor,
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                      ),
                      searchViewConfig: SearchViewConfig(
                        hintTextStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        buttonIconColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: Theme.of(context).cardColor,
                        emojiSizeMax:
                            28 *
                            (foundation.defaultTargetPlatform ==
                                    TargetPlatform.iOS
                                ? 1.20
                                : 1.0),
                      ),
                    ),
                    onEmojiSelected: (category, emoji) {
                      _messageController.text += emoji.emoji;
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
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
            _buildSwipableBubble(msg, me, messages),
          ],
        );
      },
    );
  }

  Widget _buildSwipableBubble(
    ChatMessage msg,
    String me,
    List<ChatMessage> allMessages,
  ) {
    final isMe = msg.from == me;

    return Dismissible(
      key: ValueKey('msg_${msg.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        _stageReply(msg);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.reply, color: Colors.white70, size: 22),
      ),
      child: GestureDetector(
        onLongPress: () => _showMessageOptionsMenu(msg, isMe),
        child: _buildBubble(msg, me, allMessages),
      ),
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

  Widget _buildBubble(
    ChatMessage msg,
    String me,
    List<ChatMessage> allMessages,
  ) {
    final isMe = msg.from == me;
    final isRead = widget.isGroup
        ? widget.group!.members
              .where((m) => m != me)
              .every((m) => msg.readBy.contains(m))
        : msg.read;
    final reaction = _messageReactions[msg.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(bottom: reaction != null ? 8 : 4),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF6C47FF)
                    : Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.replyTo != null)
                    _buildQuotedReply(msg.replyTo!, isMe, allMessages),
                  if (msg.file != null) _buildBubbleAttachment(msg.file!, isMe),
                  if (msg.urgency != MessageUrgency.normal)
                    _buildUrgencyBadge(msg.urgency, isMe),
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formatMessageTime(msg.time),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
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
          if (reaction != null)
            Positioned(
              left: 4,
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(reaction, style: const TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuotedReply(
    MessageReply reply,
    bool isMe,
    List<ChatMessage> allMessages,
  ) {
    return GestureDetector(
      onTap: () => _scrollToMessage(reply.id, allMessages),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Color(0xFFE57373), width: 3.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '~ ${reply.from}',
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reply.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(MessageUrgency urgency, bool isMe) {
    final label = urgency == MessageUrgency.urgent ? 'URGENT' : 'ASAP';
    final color = urgency == MessageUrgency.urgent
        ? const Color.fromARGB(255, 253, 1, 14).withOpacity(0.7)
        : const Color(0xFFF39C12).withOpacity(0.7);
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

  void _confirmDeleteMessage(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text(
          'Delete Message',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: BoxBorder.all(color: Colors.grey),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w200,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _chatProvider.deleteMessage(msg);
            },
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 107, 20, 11),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'Lexend',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReplyBar() {
    final reply = _pendingReplyTo!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFFE57373), width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ~ ${reply.from}',
                  style: const TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  reply.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearPendingReply,
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final isUploading = context.watch<ChatProvider>().isUploading;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A45).withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: isUploading ? null : _pickAndSendFile,
                child: isUploading
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.white,
                        size: 20,
                      )
                    : const Icon(
                        Icons.attach_file,
                        color: Colors.white38,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleEmojiPicker,
                child: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: TextField(
                    onTap: _onTextFieldTapEmoji,
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
              const SizedBox(width: 6),
              PopupMenuButton<MessageUrgency>(
                icon: Icon(
                  Icons.report_problem_outlined,
                  size: 20,
                  color: _pendingUrgency != MessageUrgency.normal
                      ? const Color(0xFFF39C12)
                      : Colors.white38,
                ),
                onSelected: (urgency) {
                  setState(() => _pendingUrgency = urgency);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: MessageUrgency.normal,
                    child: Text('Normal'),
                  ),
                  const PopupMenuItem(
                    value: MessageUrgency.asap,
                    child: Text('ASAP'),
                  ),
                  const PopupMenuItem(
                    value: MessageUrgency.urgent,
                    child: Text('Urgent'),
                  ),
                ],
              ),
              const SizedBox(width: 6),
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
        ],
      ),
    );
  }

  Widget _buildBubbleAttachment(MessageAttachment attachment, bool isMe) {
    if (!attachment.isValid) {
      return _attachmentPlaceholder('Attachment unavailable', isMe);
    }

    return FutureBuilder<Uint8List>(
      future: AttachmentService.instance.download(attachment),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            width: 160,
            height: 90,
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          );
        }

        final error = snapshot.error;
        if (error is AttachmentException) {
          return _attachmentPlaceholder(
            error.message,
            isMe,
            muted: error.kind == AttachmentFailure.gone,
          );
        }
        if (snapshot.hasError) {
          return _attachmentPlaceholder('Could not load attachment', isMe);
        }

        final bytes = snapshot.data!;

        // ── Image Attachment ───────────────────────────────────────────────
        if (attachment.isImage) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Stack(
              children: [
                Image.memory(bytes, fit: BoxFit.cover),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _saveFileToDevice(attachment.name, bytes),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.file_download,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ── Non-Image (PDF/Document) Attachment ─────────────────────────────
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 20,
                color: isMe ? Colors.white : const Color(0xFF6C47FF),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(attachment.size / 1024).toStringAsFixed(1)} KB • ${attachment.type}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.file_download,
                  size: 20,
                  color: isMe ? Colors.white : const Color(0xFF6C47FF),
                ),
                onPressed: () => _saveFileToDevice(attachment.name, bytes),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveFileToDevice(String fileName, Uint8List bytes) async {
    try {
      Directory? dir;

      if (Platform.isWindows) {
        dir = await getDownloadsDirectory();
      } else if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        if (!mounted) return;
        showMessage(
          'Could not locate local storage path.',
          context,
          status: MessageStatus.error,
        );
        return;
      }

      // Sanitize filename and prepare destination path
      final safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${dir.path}\\$safeFileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      showMessage(
        'File saved to Downloads: $filePath',
        context,
        status: MessageStatus.success,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(
        'Failed to save file: $e',
        context,
        status: MessageStatus.error,
      );
    }
  }

  Widget _attachmentPlaceholder(String label, bool isMe, {bool muted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            muted ? Icons.history_toggle_off : Icons.error_outline,
            size: 16,
            color: muted ? Colors.grey : Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
