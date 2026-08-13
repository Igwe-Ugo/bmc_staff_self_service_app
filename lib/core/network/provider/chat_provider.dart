// chat_provider.dart
//
// Conversation state for 1-on-1 and group messaging.
//
// Conversations are keyed by:
//   - the OTHER PARTY'S USERNAME for 1-on-1
//   - the groupId for groups
//
// The message history for 1-on-1 chats arrives with the roster on sign-in
// (`send-users-list` carries a `messages` array per user), so there is no
// separate history fetch — seeding from the roster IS the offline backlog.

// ignore_for_file: unnecessary_getters_setters

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/widget.dart';
import '../services/widget.dart';


class Conversation {
  Conversation({required this.key, required this.isGroup});

  /// Other party's username, or the groupId.
  final String key;
  final bool isGroup;

  final List<ChatMessage> messages = [];

  int unread = 0;
  DateTime? lastActivity;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}

class ChatProvider extends ChangeNotifier {
  ChatProvider({SocketService? service})
      : _service = service ?? SocketService.instance {
    _subs.addAll([
      _service.onStatus.listen(_onStatus),
      _service.onRoster.listen(_seedFromRoster),
      _service.onMessage.listen(_onMessage),
      _service.onMessageDeleted.listen(_onMessageDeleted),
      _service.onMessageKept.listen(_onMessageKept),
      _service.onMessagesRead.listen(_onMessagesRead),
      _service.onGroupMessagesRead.listen(_onGroupMessagesRead),
      _service.onTyping.listen(_onTyping),
      _service.onTypingStopped.listen(_onTypingStopped),
      _service.onGroups.listen(_onGroups),
      _service.onGroupUpserted.listen(_onGroupUpserted),
      _service.onGroupDeleted.listen(_onGroupDeleted),
    ]);
  }

  final SocketService _service;
  final List<StreamSubscription> _subs = [];

  /// The signed-in user's USERNAME — not their uuid. Set this from
  /// `UserProvider.user!.username` immediately after login.
  String _me = '';
  set me(String username) => _me = username;
  String get me => _me;

  
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  final Map<String, Conversation> _conversations = {};
  final Map<String, ChatGroup> _groups = {};

  /// Every message id we have already ingested.
  ///
  /// Required, not defensive: for GROUP messages the server emits to the group
  /// room (which the sender is in) AND does a direct `socket.emit` back to the
  /// sender, so the sender receives its own message twice.
  final Set<String> _seenIds = {};

  /// Usernames currently typing to us, with their auto-expiry timers.
  final Map<String, Timer> _typingTimers = {};
  final Set<String> _typing = {};

  /// The conversation the user is currently looking at. Messages arriving here
  /// are marked read instead of counted as unread.
  String? _activeConversation;

  // ── Public state ─────────────────────────────────────────────────────────

  List<Conversation> get conversations {
    final list = _conversations.values.toList();
    list.sort((a, b) {
      final at = a.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return list;
  }

  List<ChatGroup> get groups => _groups.values.toList();

  Conversation? conversation(String key) => _conversations[key];

  List<ChatMessage> messagesWith(String key) =>
      _conversations[key]?.messages ?? const [];

  /// Drives the message badge in the app bar.
  int get totalUnread =>
      _conversations.values.fold(0, (sum, c) => sum + c.unread);

  bool isTyping(String username) => _typing.contains(username);

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Call when a chat screen opens. Clears unread and tells the server.
  ///
  /// [isGroup] is only consulted for a conversation that does not exist yet —
  /// an existing conversation already knows what it is, and trusting a wrong
  /// argument would send `{withUserId: <groupId>}` with no `groupId`, which
  /// takes the server's 1-on-1 branch and marks nothing.
  void openConversation(String key, {bool isGroup = false}) {
    _activeConversation = key;
    final convo = _conversations[key];
    final group = convo?.isGroup ?? isGroup;

    final hadUnread = (convo?.unread ?? 0) > 0;
    if (convo != null && hadUnread) {
      convo.unread = 0;
      for (var i = 0; i < convo.messages.length; i++) {
        convo.messages[i] = convo.messages[i].copyWith(read: true);
      }
      notifyListeners();
    }

    // Only tell the server when there was something to mark. The handler
    // rewrites the user's entire Redis message list, so firing it on every
    // screen open is a real cost for no effect.
    if (hadUnread) {
      _service.markRead(
        withUserId: group ? '' : key,
        groupId: group ? key : null,
      );
    }
  }

  void closeConversation() {
    // Flush any in-flight typing indicator so the peer does not sit on a stale
    // "…is typing" until their 6s failsafe expires.
    final active = _activeConversation;
    if (active != null && _outboundTyping.containsKey(active)) {
      stopTypingNow(active, isGroup: _conversations[active]?.isGroup ?? false);
    }
    _activeConversation = null;
  }

  /// [to] is the recipient's USERNAME for 1-on-1, or the groupId for groups.
  ///
  /// There is no optimistic insert here: the server echoes the message back to
  /// the sender with its minted id, and that echo is what lands in state.
  /// Adding a local copy first would double-render, because the echo has an id
  /// the local copy could not have known.
  void send({
    required String to,
    required String content,
    bool isGroup = false,
    MessageUrgency urgency = MessageUrgency.normal,
    MessageReply? replyTo,
    MessageAttachment? file,
  }) {
    if (content.trim().isEmpty && file == null) return;
    _service.sendMessage(
      content: content,
      to: to,
      isGroup: isGroup,
      groupId: isGroup ? to : null,
      urgency: urgency,
      replyTo: replyTo,
      file: file,
    );
  }

  void deleteMessage(ChatMessage message) => _service.deleteMessage(
        messageId: message.id,
        withUserId: message.conversationKey(_me),
        groupId: message.isGroup ? message.groupId : null,
      );

  /// `toggle` is NOT the desired state — the server reads it as "this is a
  /// toggle request" and decides the direction itself:
  ///
  ///   if (toggle && isCurrentlyKept) → un-keep
  ///   else if (!isCurrentlyKept)     → keep
  ///
  /// Sending `false` to un-keep therefore matches neither branch, yet the
  /// server still emits `message-kept`, which would leave the UI permanently
  /// stuck. Always send `true`.
  void toggleKeep(ChatMessage message) => _service.keepMessage(
        messageId: message.id,
        withUserId: message.conversationKey(_me),
        toggle: true,
      );

  /// One debounce timer per conversation. A single shared timer meant that
  /// switching chats mid-typing suppressed `typing-start` for the new chat and
  /// then sent its `typing-stop` to the wrong person.
  final Map<String, Timer> _outboundTyping = {};

  /// Call on every keystroke. Emits `typing-start` once, then `typing-stop`
  /// 2s after the last keystroke, rather than one event per character.
  void notifyTyping(String to, {bool isGroup = false}) {
    if (!_outboundTyping.containsKey(to)) {
      _service.startTyping(to, groupId: isGroup ? to : null);
    }
    _outboundTyping[to]?.cancel();
    _outboundTyping[to] = Timer(const Duration(seconds: 2), () {
      _outboundTyping.remove(to);
      _service.stopTyping(to, groupId: isGroup ? to : null);
    });
  }

  void stopTypingNow(String to, {bool isGroup = false}) {
    _outboundTyping.remove(to)?.cancel();
    _service.stopTyping(to, groupId: isGroup ? to : null);
  }

  // ── Stream handlers ──────────────────────────────────────────────────────

  void _onStatus(SocketStatus status) {
    if (status == SocketStatus.disconnected ||
        status == SocketStatus.unauthorized) {
      _conversations.clear();
      _groups.clear();
      _seenIds.clear();
      _typing.clear();
      for (final t in _typingTimers.values) {
        t.cancel();
      }
      _typingTimers.clear();
      for (final t in _outboundTyping.values) {
        t.cancel();
      }
      _outboundTyping.clear();
      _activeConversation = null;
      notifyListeners();
    }
  }

  /// The roster doubles as the offline backlog.
  void _seedFromRoster(List<SocketUser> users) {
    for (final user in users) {
      if (user.messages.isEmpty) continue;
      final convo = _conversations.putIfAbsent(
        user.userId,
        () => Conversation(key: user.userId, isGroup: false),
      );
      for (final message in user.messages) {
        if (!_seenIds.add(message.id)) continue;
        convo.messages.add(message);
        if (message.from != _me && !message.read) convo.unread++;
      }
      convo.messages.sort((a, b) => a.time.compareTo(b.time));
      convo.lastActivity = convo.messages.isEmpty ? null : convo.messages.last.time;
    }
    notifyListeners();
  }

  /// Uploads bytes via AttachmentService, then sends only if that succeeds.
  /// Throws AttachmentException (propagated from the upload) if it fails —
  /// callers must catch this and must NOT assume the message was sent.
  /// This is what keeps a message from silently arriving with no file: the
  /// send() call below never happens unless upload() actually returned a
  /// valid documentKey.
  Future<void> sendWithAttachment({
    required String to,
    required String content,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    bool isGroup = false,
    MessageUrgency urgency = MessageUrgency.normal,
    MessageReply? replyTo,
    void Function(int sent, int total)? onProgress,
  }) async {
    _isUploading = true;
    notifyListeners();
    try {
      final documentKey = await AttachmentService.instance.upload(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        onProgress: onProgress,
      );

      send(
        to: to,
        content: content,
        isGroup: isGroup,
        urgency: urgency,
        replyTo: replyTo,
        file: MessageAttachment(
          name: fileName,
          type: mimeType,
          size: bytes.length,
          documentKey: documentKey,
        ),
      );
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void _onMessage(ChatMessage message) {
    // Group messages arrive twice for the sender — see [_seenIds].
    if (!_seenIds.add(message.id)) return;

    final key = message.conversationKey(_me);
    final convo = _conversations.putIfAbsent(
      key,
      () => Conversation(key: key, isGroup: message.isGroup),
    );

    convo.messages.add(message);
    convo.lastActivity = message.time;

    final isMine = message.from == _me;
    final isActive = _activeConversation == key;
    if (!isMine && !isActive) {
      convo.unread++;
    } else if (!isMine && isActive) {
      _service.markRead(
        withUserId: message.isGroup ? '' : key,
        groupId: message.isGroup ? key : null,
      );
    }

    // A message from someone means they have stopped typing.
    _clearTyping(message.from);
    notifyListeners();
  }

  void _onMessageDeleted(({String messageId, String deletedBy}) event) {
    for (final convo in _conversations.values) {
      final index = convo.messages.indexWhere((m) => m.id == event.messageId);
      if (index == -1) continue;

      final removed = convo.messages.removeAt(index);
      // Deleting an unread inbound message must also decrement the badge, or
      // the count outlives the message and can exceed messages.length.
      if (removed.from != _me && !removed.read && convo.unread > 0) {
        convo.unread--;
      }
      _seenIds.remove(event.messageId);
      convo.lastActivity =
          convo.messages.isEmpty ? null : convo.messages.last.time;
      notifyListeners();
      return;
    }
  }

  void _onMessageKept(({String messageId, String userId, bool removed}) event) {
    for (final convo in _conversations.values) {
      final index = convo.messages.indexWhere((m) => m.id == event.messageId);
      if (index == -1) continue;
      final message = convo.messages[index];
      final keptBy = List<String>.from(message.keptBy);
      if (event.removed) {
        keptBy.remove(event.userId);
      } else if (!keptBy.contains(event.userId)) {
        keptBy.add(event.userId);
      }
      convo.messages[index] = message.copyWith(keptBy: keptBy);
      notifyListeners();
      return;
    }
  }

  /// Server payload is `{ userId: <who marked read>, withUserId: <other party> }`
  /// and is emitted to BOTH parties, so which side of the conversation to flag
  /// depends on whether we were the reader.
  void _onMessagesRead(({String userId, String withUserId}) event) {
    final iAmTheReader = event.userId == _me;
    final key = iAmTheReader ? event.withUserId : event.userId;
    final convo = _conversations[key];
    if (convo == null) return;

    for (var i = 0; i < convo.messages.length; i++) {
      final message = convo.messages[i];
      // We read their messages → flag inbound.
      // They read ours      → flag outbound (drives the read receipt tick).
      final shouldFlag = iAmTheReader ? message.from != _me : message.from == _me;
      if (shouldFlag && !message.read) {
        convo.messages[i] = message.copyWith(read: true);
      }
    }
    if (iAmTheReader) convo.unread = 0;
    notifyListeners();
  }

  void _onGroupMessagesRead(
      ({String groupId, String userId, int markedCount}) event) {
    final convo = _conversations[event.groupId];
    if (convo == null) return;
    for (var i = 0; i < convo.messages.length; i++) {
      final message = convo.messages[i];
      if (message.readBy.contains(event.userId)) continue;
      convo.messages[i] =
          message.copyWith(readBy: [...message.readBy, event.userId]);
    }
    // The server broadcasts this to the whole group room, so we are also told
    // when WE read the group on another device — clear the badge here too.
    if (event.userId == _me) convo.unread = 0;
    notifyListeners();
  }

  void _onTyping(TypingEvent event) {
    if (event.from == _me) return;
    _typing.add(event.from);
    _typingTimers[event.from]?.cancel();
    // Failsafe: `user-stopped-typing` can be lost if the sender drops.
    _typingTimers[event.from] =
        Timer(const Duration(seconds: 6), () => _clearTyping(event.from));
    notifyListeners();
  }

  void _onTypingStopped(TypingEvent event) => _clearTyping(event.from);

  void _clearTyping(String username) {
    _typingTimers.remove(username)?.cancel();
    if (_typing.remove(username)) notifyListeners();
  }

  void _onGroups(List<ChatGroup> groups) {
    _groups
      ..clear()
      ..addEntries(groups.map((g) => MapEntry(g.id, g)));
    for (final group in groups) {
      if (group.messages.isEmpty) continue;
      final convo = _conversations.putIfAbsent(
        group.id,
        () => Conversation(key: group.id, isGroup: true),
      );
      for (final message in group.messages) {
        if (!_seenIds.add(message.id)) continue;
        convo.messages.add(message);
        if (message.from != _me && !message.readBy.contains(_me)) convo.unread++;
      }
      convo.messages.sort((a, b) => a.time.compareTo(b.time));
      convo.lastActivity = convo.messages.isEmpty ? null : convo.messages.last.time;
    }
    notifyListeners();
  }

  void _onGroupUpserted(ChatGroup group) {
    _groups[group.id] = group;
    notifyListeners();
  }

  void _onGroupDeleted(String groupId) {
    _groups.remove(groupId);
    _conversations.remove(groupId);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    for (final t in _outboundTyping.values) {
      t.cancel();
    }
    _outboundTyping.clear();
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    super.dispose();
  }
}
