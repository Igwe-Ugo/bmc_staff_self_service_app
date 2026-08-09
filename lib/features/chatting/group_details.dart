// ignore_for_file: invalid_null_aware_operator

import 'package:flutter/material.dart';
import '../../core/network/models/widget.dart';
import '../common/widget.dart';
import 'widget.dart';

class GroupDetailsScreen extends StatefulWidget {
  final ChatGroup group;
  final String currentUserId;
  final Map<String, UserModel>
  userLookup; // Map of userId/username to UserModel
  final List<UserModel> availableUsers; // All app users for adding members
  final Function(UserModel user)? onStartPrivateChat;

  const GroupDetailsScreen({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.userLookup,
    required this.availableUsers,
    this.onStartPrivateChat,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late ChatGroup _group;

  bool get isSuperAdmin => widget.currentUserId == _group.createdBy;
  bool get isAdmin =>
      isSuperAdmin || (_group.admins?.contains(widget.currentUserId) ?? false);

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  // ── Build Method ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creatorUser = widget.userLookup[_group.createdBy];
    final hasDescription =
        _group.description != null && _group.description!.trim().isNotEmpty;
    final displayDescription = hasDescription
        ? _group.description!
        : 'Created by ${creatorUser?.name ?? 'Admin'}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 18),
        ),
        title: const Text(
          'Group Info',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Group Header (Name and Avatar)
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: avatarColorFor(_group.id),
                  child: Text(
                    initialsFor(_group.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _group.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Group Description / Creator Fallback
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDescription ? 'DESCRIPTION' : 'ABOUT',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayDescription,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 4. Members ListView
          Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _group.members.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.grey, height: 1),
              itemBuilder: (context, index) {
                final memberId = _group.members[index];

                // Fetch details using memberId, hiding usernames completely
                final user =
                    widget.userLookup[memberId] ??
                    UserModel(
                      id: memberId,
                      username: '', // concealed
                      name: memberId,
                      email: '',
                      initials: initialsFor('User $memberId'),
                      privileges: const [],
                    );

                final isMemberAdmin =
                    _group.admins?.contains(memberId) ??
                    (memberId == _group.createdBy);
                final isCreator = memberId == _group.createdBy;

                return ListTile(
                  dense: true,
                  leading: (user.image != null && user.image!.isNotEmpty)
                      ? UserAvatar(
                          image: user.image,
                          initials: initialsFor(user.username),
                          radius: 13,
                          initialsColor: Colors.white,
                        )
                      : UserAvatar(
                          image: user.image,
                          initials: initialsFor(user.username),
                          radius: 13,
                          initialsColor: Colors.white,
                        ),
                  title: Text(
                    user.username.isNotEmpty ? user.name : user.username,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    user.deptName ?? user.defaultDept ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: isCreator
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Group Creator',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : isMemberAdmin
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
