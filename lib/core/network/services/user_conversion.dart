// lib/features/chat/user_conversions.dart
//
// SocketUser (core/socket/socket_models.dart) and UserModel
// (core/network/models/user_model.dart) describe the same PERSON from two
// different systems. They share one identity: SocketUser.userId ==
// UserModel.id (both are the login username — see the naming note at the
// top of socket_models.dart).
//
// The conversion is NOT symmetric:
//
//   SocketUser -> UserModel   is safe. It's a thin fallback built from
//                             whatever the live roster already knows (name,
//                             avatar) — no department/email/phone, since
//                             the socket layer never carries those. Good
//                             for an instant placeholder while
//                             MemberDirectory.get(userId) resolves the real
//                             profile in the background.
//
//   UserModel  -> SocketUser  should almost never be done by fabricating
//                             one. presence/dnd are LIVE state that only
//                             the socket actually knows — a UserModel has
//                             no idea if someone is online right now.
//                             Prefer context.read<PresenceProvider>()
//                             .user(model.id) wherever you need a REAL
//                             SocketUser; if that returns null, the person
//                             genuinely isn't on the connected roster, and
//                             no conversion changes that fact. The
//                             extension below exists only for the rare
//                             case where you need the TYPE (a widget that
//                             requires SocketUser) for someone who isn't
//                             live right now — e.g. rendering an offline
//                             row — never as a substitute for the real
//                             lookup.

import 'package:bmc_app/core/network/models/widget.dart';
import '../../../features/chatting/widget.dart';

extension SocketUserToModel on SocketUser {
  /// Thin UserModel built entirely from roster data. Use as an immediate
  /// placeholder — e.g. render this instantly, then swap in
  /// MemberDirectory.get(userId)'s real result once it resolves — not as a
  /// permanent stand-in for the real profile.
  UserModel toFallbackUserModel() {
    final displayName = username.isNotEmpty ? username : userId;
    return UserModel(
      id: userId,
      username: userId,
      name: displayName,
      email: '',
      image: avatar,
      initials: initialsFor(displayName),
      privileges: const [],
    );
  }
}

extension UserModelToSocketUser on UserModel {
  /// Builds a placeholder SocketUser shape from REST data alone.
  ///
  /// presence is always PresenceFlags.empty (offline/unknown) here — this
  /// has no way to know the person's real connection state, because that
  /// only exists on the socket. Reach for
  /// context.read<PresenceProvider>().user(model.id) instead wherever the
  /// actual online/offline state matters (which is almost everywhere —
  /// e.g. deciding whether "Message" should be enabled).
  SocketUser toPlaceholderSocketUser() {
    return SocketUser(
      userId: id,
      username: name,
      dnd: doNotDisturb ?? false,
      presence: PresenceFlags.empty,
      avatar: image,
    );
  }
}
