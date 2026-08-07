import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';
import '../common/widget.dart';
import 'widget.dart'; // CreateGroupModal

// ─── Messages List Screen ─────────────────────────────────────────────────────
//
// Roster + presence come from PresenceProvider. Conversations (last message,
// unread counts, groups) come from ChatProvider. Both are seeded by the same
// SocketService, so this screen never fetches anything itself — it just
// watches the providers.

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SocketUser> _filtered(List<SocketUser> users, ChatProvider chat) {
    // 1. Create a shallow copy so we don't mutate the underlying Provider list directly
    final list = List<SocketUser>.from(users);

    // 2. Sort users based on active chat timestamps, falling back to alphabetical order
    list.sort((a, b) {
      final convoA = chat.conversation(a.userId);
      final convoB = chat.conversation(b.userId);

      final timeA = convoA?.lastMessage?.time;
      final timeB = convoB?.lastMessage?.time;

      // Case A: Both users have recent messages -> sort descending by message timestamp
      if (timeA != null && timeB != null) {
        return timeB.compareTo(timeA);
      }

      // Case B: User A has a message but User B doesn't -> User A comes first
      if (timeA != null) return -1;

      // Case C: User B has a message but User A doesn't -> User B comes first
      if (timeB != null) return 1;

      // Case D: Neither has sent/received messages -> fallback to alphabetical display name
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });

    // 3. Apply the search query filter over the sorted list
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((u) => u.username.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final presence = context.watch<PresenceProvider>();
    final chat = context.watch<ChatProvider>();
    final users = _filtered(presence.allUsers, chat);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 18),
        ),
        title: const Text(
          'BMC Chat',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildTabBar(chat.groups.length),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(child: _buildUserList(users, presence, chat)),
                    ],
                  ),
                  _buildGroupsTab(chat, presence),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar(int groupCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          unselectedLabelColor: const Color(0xFF8E8E93),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Lexend',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: 'Lexend',
          ),
          tabs: [
            const Tab(text: 'Direct Messages'),
            Tab(text: 'Groups ($groupCount)'),
          ],
        ),
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          decoration: const InputDecoration(
            hintText: 'Search Users...',
            hintStyle: TextStyle(
              color: Color(0xFFAEAEB2),
              fontSize: 11,
              fontFamily: 'Lexend',
            ),
            prefixIcon: Icon(
              Iconsax.search_normal,
              color: Color(0xFFAEAEB2),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  // ── User list ────────────────────────────────────────────────────────────────

  Widget _buildUserList(
    List<SocketUser> users,
    PresenceProvider presence,
    ChatProvider chat,
  ) {
    // Roster hasn't arrived yet (socket still connecting/authenticating).
    if (!presence.isConnected && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.user_minus, size: 40),
          const SizedBox(height: 20),
          Text(
            'No users found',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 14,
              fontFamily: 'Lexend',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: users.length,
      itemBuilder: (context, index) =>
          _buildUserTile(users[index], presence, chat),
    );
  }

  // ── Single user tile ─────────────────────────────────────────────────────────

  Widget _buildUserTile(
    SocketUser user,
    PresenceProvider presence,
    ChatProvider chat,
  ) {
    final convo = chat.conversation(user.userId);
    final hasUnread = (convo?.unread ?? 0) > 0;
    final subtitle = convo?.lastMessage?.content ?? 'No messages yet';
    final online = presence.isReachable(user.userId);

    return InkWell(
      onTap: () {
        GoRouter.of(context).push(
          "${BMCRouter.homePath}/${BMCRouter.messagePath}/${BMCRouter.chatPath}",
          // NOTE: route builder must be updated to read a SocketUser here
          // instead of the old ChatUser, e.g.:
          //   final peer = state.extra as SocketUser;
          //   ChatScreen(peer: peer)
          extra: user,
        );
        navBarVisible.value = false;
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: online
                          ? const Color(0xFF34C759)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColorFor(user.userId),
                    child: user.avatar != null
                        ? UserAvatar(
                            image: user.avatar,
                            initials: initialsFor(user.username),
                            radius: 20,
                            initialsColor: Colors.white,
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: avatarColorFor(user.userId),
                            child: Text(
                              initialsFor(user.username),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 3),

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username, // display name (see naming note above)
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: hasUnread
                          ? Theme.of(context).primaryColor
                          : const Color(0xFF8E8E93),
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Action icons
            Row(
              children: [
                PresenceStatusBadge(
                  presence: user.presence,
                  hasNotifications: hasUnread,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Groups Tab View ────────────────────────────────────────────────────────

  Widget _buildGroupsTab(ChatProvider chat, PresenceProvider presence) {
    if (chat.groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.messages_3,
                size: 32,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Groups Created Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lexend',
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a group chat to collaborate with multiple colleagues at once.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Lexend',
                color: Color(0xFF8E8E93),
              ),
            ),
           /*  const SizedBox(height: 24),
            _buildCreateGroupButton(presence), */
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: chat.groups.length,
            itemBuilder: (context, index) =>
                _buildGroupTile(chat.groups[index], chat),
          ),
        ),
        /* Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildCreateGroupButton(presence),
        ), */
      ],
    );
  }

  Widget _buildGroupTile(ChatGroup group, ChatProvider chat) {
    final convo = chat.conversation(group.id);
    final hasUnread = (convo?.unread ?? 0) > 0;
    final subtitle =
        convo?.lastMessage?.content ?? '${group.members.length} members';

    return InkWell(
      onTap: () {
        GoRouter.of(context).push(
          "${BMCRouter.homePath}/${BMCRouter.messagePath}/${BMCRouter.chatPath}",
          // NOTE: route builder must read a ChatGroup here, e.g.:
          //   final group = state.extra as ChatGroup;
          //   ChatScreen(group: group)
          extra: group,
        );
        navBarVisible.value = false;
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColorFor(group.id),
                  child: Text(
                    initialsFor(group.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnread
                          ? Theme.of(context).primaryColor
                          : const Color(0xFF8E8E93),
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
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
}
