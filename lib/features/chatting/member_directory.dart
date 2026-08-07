// lib/features/chat/member_directory.dart
//
// UserProvider only ever holds ONE UserModel — the person currently logged
// in. There's no roster of everyone else anywhere in it. But
// UserServices.getUser(userId: ...) can fetch ANY user's profile by id
// (UserProvider.fetchMe() already proves that), so this is just a small
// in-memory cache on top of that call, keyed by username — used to turn a
// ChatGroup's member list (which is only ever usernames, never names or
// departments) into real UserModels for display.

import '../../core/network/models/user_model.dart';
import '../../core/network/services/user_services.dart';

class MemberDirectory {
  MemberDirectory._();
  static final MemberDirectory instance = MemberDirectory._();

  final UserServices _services = UserServices();
  final Map<String, UserModel> _cache = {};

  /// Fetch (or return cached) profile for a single username.
  ///
  /// NOTE: fetchMe() calls getUser(userId:, deptId:) passing the CURRENT
  /// user's own deptId as context. It's unconfirmed whether getUser needs a
  /// deptId to resolve users outside that department — if lookups for
  /// members in other departments come back empty, that's the first thing
  /// to check.
  Future<UserModel?> get(String username) async {
    final cached = _cache[username];
    if (cached != null) return cached;

    try {
      final user = await _services.getUser(userId: username);
      _cache[username] = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Resolves a whole group's members in parallel. Usernames that fail to
  /// resolve are just omitted rather than blocking the rest of the group
  /// from loading.
  Future<Map<String, UserModel>> getMany(List<String> usernames) async {
    final entries = await Future.wait(
      usernames.map((u) async => MapEntry(u, await get(u))),
    );
    return {
      for (final e in entries)
        if (e.value != null) e.key: e.value!,
    };
  }

  /// Call this after any action that could change a profile server-side
  /// (rare for chat, but cheap insurance) — e.g. if you add a "refresh"
  /// affordance to GroupDetailsScreen later.
  void invalidate(String username) => _cache.remove(username);
}
