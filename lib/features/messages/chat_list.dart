import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/widget.dart';
import '../models/widget.dart';
import 'widget.dart';

// ─── Messages List Screen ─────────────────────────────────────────────────────

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

  final List<ChatUser> _users = const [
    ChatUser(
      name: 'Orji Ugochukwu',
      subtitle: 'No messages yet',
      isYou: true,
      avatarColor: Color(0xFF8D6E63),
      initials: 'OU',
    ),
    ChatUser(
      name: 'Adenike Abiodun',
      subtitle: 'No messages yet',
      hasNotification: true,
      avatarColor: Color(0xFF5C6BC0),
      initials: 'AA',
    ),
    ChatUser(
      name: 'Tega Ojiriokhi',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFF66BB6A),
      initials: 'TO',
    ),
    ChatUser(
      name: 'Tega Ojiriokhi',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFF42A5F5),
      initials: 'TO',
    ),
    ChatUser(
      name: 'Idowu Abiodun',
      subtitle: 'No messages yet',
      hasNotification: true,
      avatarColor: Color(0xFFAB47BC),
      initials: 'IA',
    ),
    ChatUser(
      name: 'Valerie Olufolaji',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFFEF5350),
      initials: 'VO',
    ),
    ChatUser(
      name: 'Promise Nwabogor',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFF26A69A),
      initials: 'PN',
    ),
  ];

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

  List<ChatUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users
        .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            _buildTabBar(),
            _buildSearchBar(),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
    );
  }

  // ── Drag handle ──────────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ── "No Unread messages" header ──────────────────────────────────────────────

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Text(
        'No Unread messages',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF8E8E93),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
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
          labelColor: const Color(0xFF1C1C1E),
          unselectedLabelColor: const Color(0xFF8E8E93),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Direct Messages'),
            Tab(text: 'Groups (0)'),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
          decoration: const InputDecoration(
            hintText: 'Search Users...',
            hintStyle: TextStyle(color: Color(0xFFAEAEB2), fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Color(0xFFAEAEB2), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  // ── User list ────────────────────────────────────────────────────────────────

  Widget _buildUserList() {
    final users = _filteredUsers;

    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 60,
        color: Color(0xFFE5E5EA),
      ),
      itemBuilder: (context, index) => _buildUserTile(users[index]),
    );
  }

  // ── Single user tile ─────────────────────────────────────────────────────────

  Widget _buildUserTile(ChatUser user) {
    return InkWell(
      onTap: (){
        GoRouter.of(context).push("${BMCRouter.messagePath}/${BMCRouter.chatPath}", extra: user);
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: user.avatarColor,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (user.hasNotification)
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

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      if (user.isYou) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '(You)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),

            // Action icons
            Row(
              children: [
                _buildActionIcon(
                  icon: Icons.notifications_outlined,
                  filled: user.hasNotification,
                ),
                const SizedBox(width: 8),
                _buildActionIcon(icon: Icons.block, filled: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, required bool filled}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: filled ? Colors.white : const Color(0xFF8E8E93),
      ),
    );
  }
}
