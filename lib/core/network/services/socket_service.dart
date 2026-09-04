// socket_service.dart
//
// Connection lifecycle for the BMC Socket.io mesh.
//
// Responsibilities:
//   - authenticated handshake (`surface: 'mobile'` + Bearer access token)
//   - the mandatory `process-user-sign-in` emit after every connect
//   - recovery when the access token expires mid-session
//   - app-lifecycle handling (reconnect on resume)
//   - typed broadcast streams for the providers to consume
//
// It deliberately does NOT hold chat or presence state — see
// `presence_provider.dart` and `chat_provider.dart`.

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/widget.dart';
import 'socket_events.dart';

enum SocketStatus {
  /// Never connected, or intentionally disconnected (logout).
  disconnected,

  /// Handshake in flight, or socket.io is retrying after a network blip.
  connecting,

  /// Connected AND signed in (rooms joined).
  connected,

  /// The server rejected our token and a refresh did not fix it. The user
  /// must log in again — nothing will reconnect on its own from here.
  unauthorized,
}

/// Raised for every `send-invalidate-queries`.
class InvalidationEvent {
  /// Flattened key names, e.g. `['HR_MY_SHIFTS', 'HR_ROTA_PERIOD']`.
  final List<String> keys;
  const InvalidationEvent(this.keys);
}

class SocketService with WidgetsBindingObserver {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  bool _observerAttached = false;

  // ── Injected dependencies ────────────────────────────────────────────────

  late Uri _url;

  /// Reads the current access token from secure storage.
  late Future<String?> Function() _readAccessToken;

  /// Runs the single-flight refresh and returns the NEW access token, or null
  /// if refresh failed. Wire this to the same single-flight helper the Dio
  /// AuthInterceptor uses — never a second, independent refresh path, or the
  /// two will race and the server will revoke the whole token family.
  late Future<String?> Function() _refreshAccessToken;

  /// Called when the socket cannot be authenticated even after a refresh.
  /// Wire this to AuthProvider.logout().
  VoidCallback? _onAuthLost;

  /// Privileges to send with `process-user-sign-in`. The server ignores the
  /// array (it uses the token's claims) but the event signature expects it.
  List<String> Function() _privileges = () => const [];

  /// User preference sent at handshake.
  bool Function() _dnd = () => false;

  // ── State ────────────────────────────────────────────────────────────────

  SocketStatus _status = SocketStatus.disconnected;
  SocketStatus get status => _status;
  bool get isConnected => _status == SocketStatus.connected;

  /// Guards against a refresh loop: one refresh attempt per connect cycle.
  bool _refreshAttempted = false;

  /// True between an explicit [disconnect] and the next [connect].
  bool _intentionallyClosed = true;

  // ── Streams ──────────────────────────────────────────────────────────────

  final _status$ = StreamController<SocketStatus>.broadcast();
  final _rosterFull$ = StreamController<List<SocketUser>>.broadcast();
  final _userSignedIn$ = StreamController<SocketUser>.broadcast();
  final _presence$ = StreamController<PresenceEvent>.broadcast();
  final _message$ = StreamController<ChatMessage>.broadcast();
  final _messageDeleted$ =
      StreamController<({String messageId, String deletedBy})>.broadcast();
  final _messageKept$ =
      StreamController<
        ({String messageId, String userId, bool removed})
      >.broadcast();
  final _read$ =
      StreamController<({String userId, String withUserId})>.broadcast();
  final _groupRead$ =
      StreamController<
        ({String groupId, String userId, int markedCount})
      >.broadcast();
  final _typing$ = StreamController<TypingEvent>.broadcast();
  final _typingStopped$ = StreamController<TypingEvent>.broadcast();
  final _groups$ = StreamController<List<ChatGroup>>.broadcast();
  final _groupUpserted$ = StreamController<ChatGroup>.broadcast();
  final _groupDeleted$ = StreamController<String>.broadcast();
  final _groupMembership$ =
      StreamController<
        ({String groupId, String userId, bool added})
      >.broadcast();
  final _invalidation$ = StreamController<InvalidationEvent>.broadcast();

  Stream<SocketStatus> get onStatus => _status$.stream;
  Stream<List<SocketUser>> get onRoster => _rosterFull$.stream;
  Stream<SocketUser> get onUserSignedIn => _userSignedIn$.stream;
  Stream<PresenceEvent> get onPresenceChange => _presence$.stream;
  Stream<ChatMessage> get onMessage => _message$.stream;
  Stream<({String messageId, String deletedBy})> get onMessageDeleted =>
      _messageDeleted$.stream;
  Stream<({String messageId, String userId, bool removed})> get onMessageKept =>
      _messageKept$.stream;
  Stream<({String userId, String withUserId})> get onMessagesRead =>
      _read$.stream;
  Stream<({String groupId, String userId, int markedCount})>
  get onGroupMessagesRead => _groupRead$.stream;
  Stream<TypingEvent> get onTyping => _typing$.stream;
  Stream<TypingEvent> get onTypingStopped => _typingStopped$.stream;
  Stream<List<ChatGroup>> get onGroups => _groups$.stream;
  Stream<ChatGroup> get onGroupUpserted => _groupUpserted$.stream;
  Stream<String> get onGroupDeleted => _groupDeleted$.stream;
  Stream<({String groupId, String userId, bool added})> get onGroupMembership =>
      _groupMembership$.stream;
  Stream<InvalidationEvent> get onInvalidation => _invalidation$.stream;

  // ── Setup ────────────────────────────────────────────────────────────────

  /// Call once at app start, before [connect].
  ///
  /// [socketUrl] must be the deployment ORIGIN — `https://app.example.com`,
  /// not the `/api` base URL. It must also be the `https://` URL directly:
  /// socket.io-client does not follow the nginx 301 from the HTTP vhost, and
  /// the resulting failure looks like a firewall or CORS problem but is not.
  void configure({
    required String socketUrl,
    required Future<String?> Function() readAccessToken,
    required Future<String?> Function() refreshAccessToken,
    VoidCallback? onAuthLost,
    List<String> Function()? privileges,
    bool Function()? dnd,
  }) {
    _url = Uri.parse(socketUrl);

    // These are THROWS, not asserts, on purpose.
    //
    // `assert` is stripped from release builds, so an assert here would fail
    // loudly in debug and silently in the Play Store build — the exact shape of
    // the release-only bug this app already shipped once. Both checks below are
    // deterministic (they depend on build config, not on runtime data), so
    // throwing means any misconfiguration is caught on the first launch of any
    // build, including internal testing, and can never reach a user.
    if (!_url.hasScheme || !(_url.path.isEmpty || _url.path == '/')) {
      throw ArgumentError.value(
        socketUrl,
        'socketUrl',
        'must be a bare origin with no path — pass the deployment origin '
            '(https://host), not the /api REST base URL',
      );
    }
    if (_url.scheme == 'http' && !_isPrivateHost(_url.host)) {
      throw ArgumentError.value(
        socketUrl,
        'socketUrl',
        'is plain http on a public host. socket.io-client does not follow the '
            'nginx 301 to https, so the handshake fails with what looks like a '
            'CORS or firewall error. Use the https:// URL directly',
      );
    }
    _readAccessToken = readAccessToken;
    _refreshAccessToken = refreshAccessToken;
    _onAuthLost = onAuthLost;
    if (privileges != null) _privileges = privileges;
    if (dnd != null) _dnd = dnd;

    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }
  }

  static bool _isPrivateHost(String host) =>
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '10.0.2.2' || // Android emulator → host machine
      host.startsWith('10.') ||
      host.startsWith('192.168.');

  /// Derives the socket origin from the REST base URL, e.g.
  /// `https://app.example.com/api` → `https://app.example.com`.
  static String originFromApiBaseUrl(String apiBaseUrl) {
    final uri = Uri.parse(apiBaseUrl);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// True while a [disconnect] call is tearing the socket down. [connect]
  /// awaits this instead of racing it — see the note there.
  Future<void>? _disconnecting;

  /// Connects and signs in. Safe to call repeatedly — a live socket is reused.
  Future<void> connect() async {
    // If a disconnect (e.g. logout) is still in flight, its socket may still
    // report `connected == true` for up to ~120ms while it waits to flush
    // the sign-out emit before tearing down. Without this wait, a fast
    // logout->login lands here during that window, the guard below sees the
    // OLD socket as "connected", and this call silently no-ops — no socket
    // is ever built for the new account, and the previous account's data
    // isn't cleared until the pending disconnect finally completes, well
    // after the new account's screens are already showing.
    final inFlight = _disconnecting;
    if (inFlight != null) await inFlight;

    if (_socket?.connected == true) return;

    final token = await _readAccessToken();
    if (token == null || token.isEmpty) {
      _setStatus(SocketStatus.disconnected);
      return;
    }

    _intentionallyClosed = false;
    _refreshAttempted = false;
    _build(token);
    _setStatus(SocketStatus.connecting);
    _socket!.connect();
  }

  /// Signs out of the mesh and closes the socket.
  ///
  /// The `process-user-sign-out` emit is what clears this surface's presence
  /// flag and leaves the rooms. Disconnecting without it also works (the
  /// server's `disconnect` handler recomputes presence), but the explicit
  /// sign-out is immediate and does not depend on the disconnect being clean.
  ///
  /// Always await this fully before calling [connect] for a different
  /// account (or, better, let [connect]'s own wait above handle it) — and
  /// clear any account-scoped app state (ChatProvider, PresenceProvider,
  /// etc.) once it resolves, rather than relying solely on the
  /// `onStatus(disconnected)` event to do so, since that event is what this
  /// method delays.
  Future<void> disconnect({bool signOut = true}) {
    final future = _disconnectInternal(signOut: signOut);
    _disconnecting = future;
    future.whenComplete(() {
      if (identical(_disconnecting, future)) _disconnecting = null;
    });
    return future;
  }

  Future<void> _disconnectInternal({bool signOut = true}) async {
    _intentionallyClosed = true;
    final s = _socket;
    if (s != null) {
      if (signOut && s.connected) {
        s.emit(SocketEvents.userSignOut);
        // Give the frame a chance to flush before tearing the transport down.
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      _teardown();
    }
    _setStatus(SocketStatus.disconnected);
  }

  /// Reconnects with a freshly-minted token. Call this after any out-of-band
  /// token refresh (e.g. the Dio interceptor refreshed while the socket was
  /// idle) so the next handshake does not use the stale token.
  Future<void> reconnectWithNewToken() async {
    _teardown();
    await connect();
  }

  /// Tears down the transport and detaches the lifecycle observer.
  ///
  /// The stream controllers are deliberately NOT closed. This is a singleton
  /// that outlives every subscriber, and a closed broadcast controller throws
  /// on the next `add()` — so closing them here would turn "user logged out
  /// and back in" into a StateError. Subscribers cancel their own listeners.
  void dispose() {
    _teardown();
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_intentionallyClosed) {
      // Android kills idle sockets aggressively; the client's own reconnect
      // timer may also have exhausted its attempts while backgrounded.
      if (_socket?.connected != true && _status != SocketStatus.unauthorized) {
        connect();
      }
    }
  }

  // ── Emitters ─────────────────────────────────────────────────────────────

  void sendMessage({
    required String content,
    required String to,
    bool isGroup = false,
    String? groupId,
    MessageUrgency urgency = MessageUrgency.normal,
    MessageReply? replyTo,
    MessageAttachment? file,
  }) {
    _emit(
      SocketEvents.sendMessage,
      ChatMessage.outbound(
        content: content,
        to: to,
        isGroup: isGroup,
        groupId: groupId,
        urgency: urgency,
        replyTo: replyTo,
        file: file,
      ),
    );
  }

  /// [withUserId] is the other party's USERNAME. Pass [groupId] for groups.
  void markRead({required String withUserId, String? groupId}) => _emit(
    SocketEvents.markMessagesRead,
    {'withUserId': withUserId, if (groupId != null) 'groupId': groupId},
  );

  void deleteMessage({
    required String messageId,
    required String withUserId,
    String? groupId,
  }) => _emit(SocketEvents.deleteMessage, {
    'messageId': messageId,
    'withUserId': withUserId,
    if (groupId != null) 'groupId': groupId,
  });

  void keepMessage({
    required String messageId,
    required String withUserId,
    bool toggle = true,
  }) => _emit(SocketEvents.keepMessage, {
    'messageId': messageId,
    'withUserId': withUserId,
    'toggle': toggle,
  });

  /// The server fans typing out with a bare `socket.to(to)` and ignores the
  /// `groupId` field entirely, but group rooms are named `group:{id}` — so a
  /// group target must carry the prefix or the event goes to a room nobody is
  /// in and is silently dropped.
  void startTyping(String to, {String? groupId}) => _emit(
    SocketEvents.typingStart,
    {'to': _typingTarget(to, groupId), 'groupId': groupId},
  );

  void stopTyping(String to, {String? groupId}) => _emit(
    SocketEvents.typingStop,
    {'to': _typingTarget(to, groupId), 'groupId': groupId},
  );

  static String _typingTarget(String to, String? groupId) =>
      groupId == null ? to : 'group:$groupId';

  void requestUsersList() => _emit(SocketEvents.requestUsersList);
  void requestGroupsList() => _emit(SocketEvents.requestGroupsList);

  // NOTE: `process-request-backlog` is deliberately not exposed. The server
  // answers it only with `send-action-notification`, which is phase 2 — adding
  // the emit without the matching listener would look wired up but discard
  // every reply.

  void createGroup({
    required String name,
    String? description,
    required List<String> members,
  }) => _emit(SocketEvents.createGroup, {
    'name': name,
    if (description != null) 'description': description,
    'members': members,
  });

  void addGroupMember(String groupId, String userId) => _emit(
    SocketEvents.addGroupMember,
    {'groupId': groupId, 'userId': userId},
  );

  void removeGroupMember(String groupId, String userId) => _emit(
    SocketEvents.removeGroupMember,
    {'groupId': groupId, 'userId': userId},
  );

  void updateGroup(String groupId, {String? name, String? description}) =>
      _emit(SocketEvents.updateGroup, {
        'groupId': groupId,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      });

  void deleteGroup(String groupId) =>
      _emit(SocketEvents.deleteGroup, {'groupId': groupId});

  void promoteAdmin(String groupId, String userId) =>
      _emit(SocketEvents.promoteAdmin, {'groupId': groupId, 'userId': userId});

  void demoteAdmin(String groupId, String userId) =>
      _emit(SocketEvents.demoteAdmin, {'groupId': groupId, 'userId': userId});

  /// Tell other clients to refetch. Mirrors `broadcastInvalidation()` in the
  /// web app's `lib/configs/socket.config.ts`.
  ///
  /// The server uses `socket.to(target)`, which EXCLUDES the sender — so this
  /// never round-trips back to us. Refresh local state directly as well.
  void broadcastInvalidation(
    List<String> keys, {
    String target = 'global-users',
  }) => _emit(SocketEvents.invalidateQueries, {
    'target': target,
    'queryKeys': keys.map((k) => [k]).toList(),
  });

  void _emit(String event, [Object? payload]) {
    final s = _socket;
    if (s == null || !s.connected) {
      debugPrint('⚠️ socket not connected — dropped "$event"');
      return;
    }
    payload == null ? s.emit(event) : s.emit(event, payload);
  }

  // ── Wiring ───────────────────────────────────────────────────────────────

  void _build(String token) {
    _teardown();

    final socket = io.io(
      _url.toString(),
      io.OptionBuilder()
          // Websocket only. There is no polling handshake to authenticate, and
          // the server's docs note CORS only becomes a factor if polling is
          // added back as a fallback.
          .setTransports(['websocket'])
          .disableAutoConnect()
          // REQUIRED for the token-refresh path. socket_io_client caches the
          // Manager per URL and `Manager.socket()` returns the CACHED Socket,
          // whose `auth` was captured at construction — so without forceNew a
          // rebuild after a refresh silently replays the expired token, fails
          // again, and dead-ends in the _refreshAttempted guard below.
          .enableForceNew()
          .setAuth({
            'surface': 'mobile', // REQUIRED — selects the mobile handshake path
            'token': token, // REQUIRED — the /auth/login access token
            'dnd': _dnd() ? 'true' : 'false', // string, not bool
          })
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('🔌 socket connected: ${socket.id}');
      _refreshAttempted = false;

      // MANDATORY. Room joins (personal room, global-users, mobile-users,
      // privilege rooms, group rooms) all happen inside the server's handler
      // for this event — not at handshake. Without it the socket is connected
      // but deaf.
      socket.emit(SocketEvents.userSignIn, _privileges());

      // ALSO mandatory. Sign-in joins the `group:*` rooms but does not send the
      // group roster — that only happens in response to this request. Without
      // it, group chats and their history never appear.
      socket.emit(SocketEvents.requestGroupsList);

      _setStatus(SocketStatus.connected);
    });

    socket.onDisconnect((reason) {
      debugPrint('🔌 socket disconnected: $reason');
      if (_status != SocketStatus.unauthorized) {
        _setStatus(
          _intentionallyClosed
              ? SocketStatus.disconnected
              : SocketStatus.connecting,
        );
      }
    });

    socket.onConnectError((err) => _handleConnectError(err));
    socket.onError((err) => debugPrint('🔌 socket error: $err'));

    // ── Roster & presence ──────────────────────────────────────────────────
    socket.on(SocketEvents.usersList, (data) => _emitRoster(data));
    socket.on(SocketEvents.requestedUsersList, (data) => _emitRoster(data));

    socket.on(SocketEvents.userSignedIn, (data) {
      final map = _asMap(data);
      if (map != null) _userSignedIn$.add(SocketUser.fromJson(map));
    });

    for (final evt in [
      SocketEvents.userSignedOut,
      SocketEvents.userDisconnected,
    ]) {
      socket.on(evt, (data) {
        final map = _asMap(data);
        if (map != null) _presence$.add(PresenceEvent.fromJson(map));
      });
    }

    // ── Messaging ──────────────────────────────────────────────────────────
    socket.on(SocketEvents.receiveMessage, (data) {
      final map = _asMap(data);
      if (map != null) _message$.add(ChatMessage.fromJson(map));
    });

    socket.on(SocketEvents.messageDeleted, (data) {
      final map = _asMap(data);
      if (map == null) return;
      _messageDeleted$.add((
        messageId: map['messageId'] as String? ?? '',
        deletedBy: map['deletedBy'] as String? ?? '',
      ));
    });

    socket.on(SocketEvents.messageKept, (data) {
      final map = _asMap(data);
      if (map == null) return;
      _messageKept$.add((
        messageId: map['messageId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        removed: map['removed'] == true,
      ));
    });

    socket.on(SocketEvents.messagesMarkedRead, (data) {
      final map = _asMap(data);
      if (map == null) return;
      _read$.add((
        userId: map['userId'] as String? ?? '',
        withUserId: map['withUserId'] as String? ?? '',
      ));
    });

    socket.on(SocketEvents.groupMessagesMarkedRead, (data) {
      final map = _asMap(data);
      if (map == null) return;
      _groupRead$.add((
        groupId: map['groupId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        markedCount: (map['markedCount'] as num?)?.toInt() ?? 0,
      ));
    });

    socket.on(SocketEvents.userTyping, (data) {
      final map = _asMap(data);
      if (map != null) _typing$.add(TypingEvent.fromJson(map));
    });

    socket.on(SocketEvents.userStoppedTyping, (data) {
      final map = _asMap(data);
      if (map != null) _typingStopped$.add(TypingEvent.fromJson(map));
    });

    // ── Groups ─────────────────────────────────────────────────────────────
    socket.on(SocketEvents.groupsList, (data) {
      if (data is! List) return;
      _groups$.add(
        data
            .whereType<Map>()
            .map((g) => ChatGroup.fromJson(Map<String, dynamic>.from(g)))
            .toList(),
      );
    });

    for (final evt in [SocketEvents.groupCreated, SocketEvents.groupUpdated]) {
      socket.on(evt, (data) {
        final map = _asMap(data);
        if (map != null) _groupUpserted$.add(ChatGroup.fromJson(map));
      });
    }

    socket.on(SocketEvents.groupDeleted, (data) {
      if (data is String) _groupDeleted$.add(data);
    });

    socket.on(SocketEvents.groupMemberAdded, (data) {
      final map = _asMap(data);
      if (map == null) return;
      final member = _asMap(map['member']);
      _groupMembership$.add((
        groupId: map['groupId'] as String? ?? '',
        userId: member?['userId'] as String? ?? '',
        added: true,
      ));
    });

    socket.on(SocketEvents.groupMemberRemoved, (data) {
      final map = _asMap(data);
      if (map == null) return;
      _groupMembership$.add((
        groupId: map['groupId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        added: false,
      ));
    });

    // ── Live data refresh ──────────────────────────────────────────────────
    socket.on(SocketEvents.invalidateQueriesIn, (data) {
      final map = _asMap(data);
      final raw = map?['queryKeys'];
      if (raw is! List) return;
      // Server sends string[][] — flatten to a plain list of key names.
      final keys = <String>[];
      for (final group in raw) {
        if (group is List) {
          keys.addAll(group.whereType<String>());
        } else if (group is String) {
          keys.add(group);
        }
      }
      if (keys.isNotEmpty) _invalidation$.add(InvalidationEvent(keys));
    });

    _socket = socket;
  }

  void _emitRoster(dynamic data) {
    if (data is! List) return;
    _rosterFull$.add(
      data
          .whereType<Map>()
          .map((u) => SocketUser.fromJson(Map<String, dynamic>.from(u)))
          .toList(),
    );
  }

  Future<void> _handleConnectError(dynamic err) async {
    final text = err.toString().toLowerCase();
    debugPrint('🔌 connect_error: $err');

    // Anything other than an auth rejection is a transport problem — let
    // socket.io's own reconnection handle it.
    if (!text.contains('unauthorized')) {
      _setStatus(SocketStatus.connecting);
      return;
    }

    // Stop the retry loop: the same bad token would be replayed every attempt.
    _socket?.disconnect();

    if (_refreshAttempted) {
      debugPrint('🔒 socket unauthorized after refresh — signing out');
      _setStatus(SocketStatus.unauthorized);
      _teardown();
      _onAuthLost?.call();
      return;
    }

    _refreshAttempted = true;
    final fresh = await _refreshAccessToken();
    if (fresh == null || fresh.isEmpty) {
      _setStatus(SocketStatus.unauthorized);
      _teardown();
      _onAuthLost?.call();
      return;
    }

    debugPrint('🔑 token refreshed — reconnecting socket');
    _build(fresh);
    _setStatus(SocketStatus.connecting);
    _socket!.connect();
  }

  void _teardown() {
    final s = _socket;
    _socket = null;
    if (s == null) return;
    s.clearListeners();
    s.disconnect();
    s.dispose();
  }

  void _setStatus(SocketStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_status$.isClosed) _status$.add(next);
  }

  static Map<String, dynamic>? _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : null;
}
