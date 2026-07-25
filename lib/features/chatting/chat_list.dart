import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/network/models/widget.dart';
import '../common/widget.dart';
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
            _buildTabBar(),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(child: _buildUserList()),
                    ],
                  ),
                  _buildGroupsTab(),
                ],
              ),
            ),
          ],
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
          decoration: InputDecoration(
            hintText: 'Search Users...',
            hintStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
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

  Widget _buildUserList() {
    final users = _filteredUsers;

    if (users.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.user_minus, size: 40),
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
      itemBuilder: (context, index) => _buildUserTile(users[index]),
    );
  }

  // ── Single user tile ─────────────────────────────────────────────────────────

  Widget _buildUserTile(ChatUser user) {
    return InkWell(
      onTap: () {
        GoRouter.of(context).push(
          "${BMCRouter.homePath}/${BMCRouter.messagePath}/${BMCRouter.chatPath}",
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
                CircleAvatar(
                  radius: 20,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
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

  // ── Groups Tab View ────────────────────────────────────────────────────────

  Widget _buildGroupsTab() {
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
          const SizedBox(height: 24),

          // ── Create Group Button ──────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _openCreateGroupModal,
            icon: const Icon(Iconsax.add, size: 18, color: Colors.white),
            label: const Text(
              'Create New Group',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Trigger Modal Helper ─────────────────────────────────────────────────

  void _openCreateGroupModal() {
    showDialog(
      context: context,
      builder: (context) {
        return CreateGroupModal(
          availableUsers: _users,
          onCreateGroup: (groupName, description, selectedMembers) {
            // Handle group creation callback here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Group "$groupName" created!')),
            );
          },
        );
      },
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
