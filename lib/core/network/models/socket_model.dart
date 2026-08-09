// socket_models.dart
//
// Dart mirrors of the socket payload types in the backend's `types/type.d.ts`.
//
// ⚠️ NAMING TRAP — read this before using any of these models.
//
// On the socket mesh the server sets:
//     socket.data.userId   = the JWT `username` claim   (e.g. "john.doe")
//     socket.data.username = the JWT `name` claim       (e.g. "John Doe")
//     socket.data.sessionId= the JWT `sub` claim        (the uuid)
//
// (see `verifyMobileHandshake` in server.ts). So in every payload below,
// `userId` is a USERNAME and `username` is a FULL NAME. The personal room a
// socket joins is `{username}`, and 1-on-1 messages are addressed to the
// recipient's username.
//
// The REST `/api/mobapp/auth/login` response is the other way round: `user.id`
// is the uuid and `user.username` is the username. Use `user.username` for
// anything socket-related and `user.id` only for REST. Sending `user.id` as a
// message `to` produces no error — the message is simply delivered to a room
// nobody is in.

import 'dart:convert';

/// Parsed form of the `connectStatus` JSON string.
///
/// The three flags are orthogonal and can all be true at once:
///   - [online] / [local] — the user has a WEB connection on that deployment
///   - [mobile]           — the user has a MOBILE connection
class PresenceFlags {
  final bool online;
  final bool local;
  final bool mobile;

  const PresenceFlags({
    this.online = false,
    this.local = false,
    this.mobile = false,
  });

  static const empty = PresenceFlags();

  /// Any surface at all. Use this for "is this user reachable" —
  /// a check of `online || local` renders a phone-only user as offline.
  bool get isConnected => online || local || mobile;

  /// True when the only surface is the phone.
  bool get isMobileOnly => mobile && !online && !local;

  /// `connectStatus` arrives as a JSON *string*, not an object. Tolerates the
  /// legacy two-key `{online, local}` form, which reads `mobile: false`.
  factory PresenceFlags.fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return empty;
      return PresenceFlags(
        online: decoded['online'] == true,
        local: decoded['local'] == true,
        mobile: decoded['mobile'] == true,
      );
    } catch (_) {
      return empty;
    }
  }

  PresenceFlags copyWithSurface(String surface, bool value) => PresenceFlags(
        online: surface == 'online' ? value : online,
        local: surface == 'local' ? value : local,
        mobile: surface == 'mobile' ? value : mobile,
      );

  @override
  String toString() =>
      'PresenceFlags(online: $online, local: $local, mobile: $mobile)';
}

/// A roster entry — one per user known to the mesh, online or not.
class SocketUser {
  /// The user's USERNAME (see the naming trap at the top of this file).
  final String userId;

  /// The user's FULL NAME.
  final String username;

  final bool dnd;
  final PresenceFlags presence;
  final String? avatar;
  final DateTime? lastSeen;

  /// Message history between this user and us, delivered with the roster on
  /// sign-in. This is the offline backlog.
  final List<ChatMessage> messages;

  const SocketUser({
    required this.userId,
    required this.username,
    required this.dnd,
    required this.presence,
    this.avatar,
    this.lastSeen,
    this.messages = const [],
  });

  factory SocketUser.fromJson(Map<String, dynamic> json) => SocketUser(
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String? ?? '',
        dnd: json['dnd'] == true || json['dnd'] == 'true',
        presence: PresenceFlags.fromJsonString(json['connectStatus'] as String?),
        avatar: json['avatar'] as String?,
        lastSeen: _parseTime(json['time']),
        messages: (json['messages'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );

  SocketUser copyWith({PresenceFlags? presence, bool? dnd, DateTime? lastSeen}) =>
      SocketUser(
        userId: userId,
        username: username,
        dnd: dnd ?? this.dnd,
        presence: presence ?? this.presence,
        avatar: avatar,
        lastSeen: lastSeen ?? this.lastSeen,
        messages: messages,
      );
}

enum MessageUrgency { normal, asap, urgent }

MessageUrgency _urgencyFrom(dynamic raw) => switch (raw) {
      'URGENT' => MessageUrgency.urgent,
      'ASAP' => MessageUrgency.asap,
      _ => MessageUrgency.normal,
    };

String? _urgencyTo(MessageUrgency u) => switch (u) {
      MessageUrgency.urgent => 'URGENT',
      MessageUrgency.asap => 'ASAP',
      MessageUrgency.normal => null,
    };

class MessageAttachment {
  final String name;
  final String type; // MIME type, e.g. 'image/jpeg'
  final int size;

  /// Reference into the external document store — NOT the bytes. Attachments
  /// used to travel inline as base64 over the socket; they now live in cloud
  /// storage and the message only carries this key. Fetch the actual bytes
  /// via AttachmentService.download(this). See MESSAGING_ATTACHMENTS.md.
  final String documentKey;

  const MessageAttachment({
    required this.name,
    required this.type,
    required this.size,
    required this.documentKey,
  });

  /// server.ts only relays `file` on a message when `file?.documentKey` is
  /// present — an attachment sent with an empty key produces NO error
  /// anywhere, the message just silently arrives with no file at all. This
  /// is what the assert in ChatMessage.outbound() below checks.
  bool get isValid => documentKey.isNotEmpty;

  bool get isImage => type.startsWith('image/');

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        name: json['name'] as String? ?? 'file',
        type: json['type'] as String? ?? 'application/octet-stream',
        size: (json['size'] as num?)?.toInt() ?? 0,
        documentKey: json['documentKey'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'type': type, 'size': size, 'documentKey': documentKey};
}

class MessageReply {
  final String id;
  final String from;
  final String content;

  const MessageReply({
    required this.id,
    required this.from,
    required this.content,
  });

  factory MessageReply.fromJson(Map<String, dynamic> json) => MessageReply(
        id: json['id'] as String? ?? '',
        from: json['from'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'content': content};
}

class ChatMessage {
  /// Server-minted nanoid. Use this to dedupe — the server delivers group
  /// messages to the sender TWICE (once via the group room, once via a direct
  /// `socket.emit`).
  final String id;

  /// Recipient: a USERNAME for 1-on-1, a groupId for group messages.
  final String to;

  /// Sender's USERNAME.
  final String from;

  final String content;
  final DateTime time;
  final bool read;
  final bool isGroup;
  final String? groupId;
  final MessageUrgency urgency;
  final List<String> keptBy;
  final List<String> readBy;
  final MessageReply? replyTo;
  final MessageAttachment? file;

  const ChatMessage({
    required this.id,
    required this.to,
    required this.from,
    required this.content,
    required this.time,
    this.read = false,
    this.isGroup = false,
    this.groupId,
    this.urgency = MessageUrgency.normal,
    this.keptBy = const [],
    this.readBy = const [],
    this.replyTo,
    this.file,
  });

  /// The other party in this conversation, from [me]'s point of view.
  /// For group messages this is the groupId.
  String conversationKey(String me) {
    if (isGroup) return groupId ?? to;
    return from == me ? to : from;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        to: json['to'] as String? ?? '',
        from: json['from'] as String? ?? '',
        content: json['content'] as String? ?? '',
        time: _parseTime(json['time']) ?? DateTime.now(),
        read: json['read'] == true,
        isGroup: json['isGroup'] == true,
        groupId: json['groupId'] as String?,
        urgency: _urgencyFrom(json['urgency']),
        keptBy: _stringList(json['keptBy']),
        readBy: _stringList(json['readBy']),
        replyTo: json['replyTo'] is Map
            ? MessageReply.fromJson(Map<String, dynamic>.from(json['replyTo']))
            : null,
        file: json['file'] is Map
            ? MessageAttachment.fromJson(Map<String, dynamic>.from(json['file']))
            : null,
      );

  ChatMessage copyWith({
    bool? read,
    List<String>? keptBy,
    List<String>? readBy,
  }) =>
      ChatMessage(
        id: id,
        to: to,
        from: from,
        content: content,
        time: time,
        read: read ?? this.read,
        isGroup: isGroup,
        groupId: groupId,
        urgency: urgency,
        keptBy: keptBy ?? this.keptBy,
        readBy: readBy ?? this.readBy,
        replyTo: replyTo,
        file: file,
      );

  /// Outbound payload for `process-send-message`. Note there is no `id` or
  /// `from` — the server mints both.
  static Map<String, dynamic> outbound({
    required String content,
    required String to,
    bool isGroup = false,
    String? groupId,
    MessageUrgency urgency = MessageUrgency.normal,
    MessageReply? replyTo,
    MessageAttachment? file,
  }) {
    assert(
      !isGroup || (groupId != null && groupId.isNotEmpty),
      'isGroup: true requires a groupId. The server checks `isGroup && groupId` '
      'and otherwise falls through to the 1-on-1 branch, delivering the message '
      'to a room named by the groupId that nobody has joined.',
    );
    assert(
      file == null || file.isValid,
      'MessageAttachment.documentKey is empty. The server only relays `file` '
      'when documentKey is present — an invalid attachment produces no error '
      'anywhere, the message just silently arrives without it. Upload via '
      'AttachmentService first and pass the returned documentKey — this '
      'assert is debug-only, so ChatProvider.sendWithAttachment must also '
      'refuse to send when the upload itself throws (release builds don\'t '
      'get this assert to save them).',
    );
    final payload = <String, dynamic>{'content': content, 'to': to};
    if (isGroup) {
      payload['isGroup'] = true;
      payload['groupId'] = groupId;
    }
    final u = _urgencyTo(urgency);
    if (u != null) payload['urgency'] = u;
    if (replyTo != null) payload['replyTo'] = replyTo.toJson();
    if (file != null) payload['file'] = file.toJson();
    return payload;
  }
}

class GroupMember {
  final String userId;
  final String username;
  final bool isAdmin;
  final DateTime? joinedAt;

  const GroupMember({
    required this.userId,
    required this.username,
    required this.isAdmin,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String? ?? '',
        isAdmin: json['isAdmin'] == true,
        joinedAt: _parseTime(json['joinedAt']),
      );
}

class ChatGroup {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String createdBy;
  final DateTime? createdAt;
  final List<String> members;
  final List<String> admins;
  final List<ChatMessage> messages;

  const ChatGroup({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.createdBy,
    this.createdAt,
    this.members = const [],
    this.admins = const [],
    this.messages = const [],
  });

  bool isAdmin(String username) => admins.contains(username);

  factory ChatGroup.fromJson(Map<String, dynamic> json) => ChatGroup(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        avatar: json['avatar'] as String?,
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: _parseTime(json['createdAt']),
        members: _stringList(json['members']),
        admins: _stringList(json['admins']),
        messages: (json['messages'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}

/// Payload of `send-user-sign-out` and `send-user-disconnected`.
class PresenceEvent {
  /// The user's USERNAME.
  final String userId;

  /// The single surface that went away: 'online' | 'local' | 'mobile'.
  final String location;

  /// Authoritative flags AFTER the event. Optional for backward compatibility —
  /// when absent, flip the single flag named by [location].
  final PresenceFlags? presence;

  const PresenceEvent({
    required this.userId,
    required this.location,
    this.presence,
  });

  factory PresenceEvent.fromJson(Map<String, dynamic> json) => PresenceEvent(
        userId: json['userId'] as String? ?? '',
        location: json['location'] as String? ?? '',
        presence: json['connectStatus'] == null
            ? null
            : PresenceFlags.fromJsonString(json['connectStatus'] as String?),
      );
}

class TypingEvent {
  /// Sender's USERNAME.
  final String from;

  /// Sender's FULL NAME (absent on `user-stopped-typing`).
  final String? username;

  const TypingEvent({required this.from, this.username});

  factory TypingEvent.fromJson(Map<String, dynamic> json) => TypingEvent(
        from: json['from'] as String? ?? '',
        username: json['username'] as String?,
      );
}

// ── helpers ─────────────────────────────────────────────────────────────────

DateTime? _parseTime(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<String>().toList();
}
