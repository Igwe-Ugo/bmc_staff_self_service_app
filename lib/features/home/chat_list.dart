import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../common/widget.dart';
import '../models/widget.dart';

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
      userAvatar: "assets/images/profile_pic.png"
    ),
    ChatUser(
      name: 'Adenike Abiodun',
      subtitle: 'No messages yet',
      hasNotification: true,
      avatarColor: Color(0xFF5C6BC0),
        userAvatar: "assets/images/users/user_1.png"
    ),
    ChatUser(
      name: 'Tega Ojiriokhi',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFF66BB6A),
        userAvatar: "assets/images/users/user_2.png"
    ),
    ChatUser(
      name: 'Tega Ojiriokhi',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFF42A5F5),
        userAvatar: "assets/images/users/user_3.png"
    ),
    ChatUser(
      name: 'Idowu Abiodun',
      subtitle: 'No messages yet',
      hasNotification: true,
      avatarColor: Color(0xFFAB47BC),
        userAvatar: "assets/images/users/user_4.png"
    ),
    ChatUser(
      name: 'Valerie Olufolaji',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFFEF5350),
        userAvatar: "assets/images/users/user_5.png"
    ),
    ChatUser(
      name: 'Promise Nwabogor',
      subtitle: 'No messages yet',
      avatarColor: Color(0xFF26A69A),
        userAvatar: "assets/images/users/user_6.png"
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              GoRouter.of(context).pop();
            },
            icon: const Icon(
              Iconsax.arrow_left,
              size: 17,
            )),
        title: Text(
          "Collaborate with team members",
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            _buildSearchBar(),
            Expanded(child: _buildUserList()),
          ],
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
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(fontSize: 18, color: Color(0xFF1C1C1E)),
          decoration: const InputDecoration(
            hintText: 'Search Users...',
            hintStyle: TextStyle(color: Color(0xFFAEAEB2), fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Color(0xFFAEAEB2), size: 25),
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
          Icon(
            Iconsax.user_remove,
            size: 70,
          ),
          const SizedBox(height: 20,),
          Text(
            'No users found with this identity!',
            style: TextStyle(color: Colors.grey, fontSize: 14),
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
      onTap: (){
        GoRouter.of(context).push("${BMCRouter.homePath}/${BMCRouter.messagePath}/${BMCRouter.chatPath}", extra: user);
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
                  child: Image.asset(user.userAvatar),
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
                  icon: Iconsax.cloud,
                  filled: user.hasNotification,
                ),
                const SizedBox(width: 8),
                _buildActionIcon(
                  icon: Iconsax.home_wifi,
                  filled: false,
                ),
                const SizedBox(width: 8),
                _buildActionIcon(icon: Iconsax.eye_slash, filled: false),
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
        color: filled ? const Color(0xFF007AFF) : Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: filled ? Colors.white : Colors.black,
      ),
    );
  }
}
