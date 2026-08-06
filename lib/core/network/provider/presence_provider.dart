// presence_provider.dart
//
// Roster + presence state, driven entirely by SocketService streams.
//
// Register in main.dart AFTER UserProvider (it needs the signed-in username).

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/widget.dart';
import '../services/widget.dart';

class PresenceProvider extends ChangeNotifier {
  PresenceProvider({SocketService? service})
      : _service = service ?? SocketService.instance {
    _subs.addAll([
      _service.onStatus.listen(_onStatus),
      _service.onRoster.listen(_onRoster),
      _service.onUserSignedIn.listen(_onUserSignedIn),
      _service.onPresenceChange.listen(_onPresenceChange),
    ]);
  }

  final SocketService _service;
  final List<StreamSubscription> _subs = [];

  /// Keyed by USERNAME (the socket-level identity). See the note at the top of
  /// socket_models.dart.
  final Map<String, SocketUser> _users = {};

  SocketStatus _status = SocketStatus.disconnected;

  /// The signed-in user's USERNAME. Set it from `UserProvider.user!.username`
  /// before connecting — the server's roster includes the requesting user's own
  /// session, so without this the current user appears in their own contact
  /// list.
  String _me = '';
  set me(String username) {
    _me = username;
    notifyListeners();
  }

  SocketStatus get status => _status;
  bool get isConnected => _status == SocketStatus.connected;

  /// True when the session is dead and the user must log in again.
  bool get isUnauthorized => _status == SocketStatus.unauthorized;

  /// Everyone except the signed-in user.
  List<SocketUser> get allUsers {
    final list = _users.values.where((u) => u.userId != _me).toList();
    list.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    return list;
  }

  /// The signed-in user's own roster entry — useful for rendering your own
  /// presence, and the only way to read your own `dnd` as the server sees it.
  SocketUser? get self => _me.isEmpty ? null : _users[_me];

  /// Everyone reachable on ANY surface, phone included.
  List<SocketUser> get connectedUsers =>
      allUsers.where((u) => u.presence.isConnected).toList();

  SocketUser? user(String username) => _users[username];

  PresenceFlags presenceOf(String username) =>
      _users[username]?.presence ?? PresenceFlags.empty;

  /// The only correct "is this person reachable" test.
  ///
  /// A check of `online || local` reports a phone-only user as offline —
  /// which is exactly the bug the backend's presence rework was meant to end.
  bool isReachable(String username) => presenceOf(username).isConnected;

  bool isOnPhoneOnly(String username) => presenceOf(username).isMobileOnly;

  // ── Stream handlers ──────────────────────────────────────────────────────

  void _onStatus(SocketStatus s) {
    _status = s;
    if (s == SocketStatus.disconnected || s == SocketStatus.unauthorized) {
      _users.clear();
    }
    notifyListeners();
  }

  void _onRoster(List<SocketUser> users) {
    _users
      ..clear()
      ..addEntries(users.map((u) => MapEntry(u.userId, u)));
    notifyListeners();
  }

  void _onUserSignedIn(SocketUser user) {
    _users[user.userId] = user;
    notifyListeners();
  }

  void _onPresenceChange(PresenceEvent event) {
    final existing = _users[event.userId];
    if (existing == null) return;

    // Prefer the authoritative post-event flags. Older payloads omit them, in
    // which case flip only the surface named by `location` — the other
    // surfaces stay as they were, which is the whole point of the three-flag
    // model (signing out of mobile must not clear a live web session).
    final next = event.presence ??
        existing.presence.copyWithSurface(event.location, false);

    _users[event.userId] = existing.copyWith(
      presence: next,
      lastSeen: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}
