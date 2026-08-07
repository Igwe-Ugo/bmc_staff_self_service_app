// ignore_for_file: invalid_null_aware_operator

import 'package:flutter/material.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/services/socket_service.dart';
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

  // ── Member Details Pop-Up Dialog ─────────────────────────────────────────

  void _showMemberDialog(UserModel user, bool isMemberAdmin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: avatarColorFor(user.id),
              backgroundImage: (user.image != null && user.image!.isNotEmpty)
                  ? NetworkImage(user.image!)
                  : null,
              child: (user.image == null || user.image!.isEmpty)
                  ? Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (isMemberAdmin)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Profile Info Fields
            _infoRow(
              Icons.business,
              'Department',
              user.deptName ?? user.defaultDept ?? 'N/A',
            ),
            _infoRow(
              Icons.email_outlined,
              'Email',
              user.email.isNotEmpty ? user.email : 'N/A',
            ),
            _infoRow(Icons.phone_outlined, 'Phone', user.telno ?? 'N/A'),
          ],
        ),
        actions: [
          if (user.id != widget.currentUserId &&
              widget.onStartPrivateChat != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Close group screen to view chat
                widget.onStartPrivateChat!(user);
              },
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Private Chat'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Admin Actions ────────────────────────────────────────────────────────

  void _editGroupDetails() {
    final nameController = TextEditingController(text: _group.name);
    final descController = TextEditingController(text: _group.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              SocketService.instance.updateGroup(
                _group.id,
                name: nameController.text.trim(),
                description: descController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addMemberDialog() {
    final nonMembers = widget.availableUsers
        .where((u) => !_group.members.contains(u.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: nonMembers.length,
            itemBuilder: (_, index) {
              final user = nonMembers[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.deptName ?? user.defaultDept ?? ''),
                onTap: () {
                  SocketService.instance.addGroupMember(_group.id, user.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMemberOptionsBottomSheet(UserModel user, bool isMemberAdmin) {
    final isCreator = user.id == _group.createdBy;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(ctx);
                _showMemberDialog(user, isMemberAdmin);
              },
            ),
            if (isSuperAdmin && !isCreator) ...[
              if (!isMemberAdmin)
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.amber),
                  title: const Text('Make Group Admin'),
                  onTap: () {
                    SocketService.instance.promoteAdmin(_group.id, user.id);
                    Navigator.pop(ctx);
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.remove_moderator,
                    color: Colors.orange,
                  ),
                  title: const Text('Dismiss as Admin'),
                  onTap: () {
                    SocketService.instance.demoteAdmin(_group.id, user.id);
                    Navigator.pop(ctx);
                  },
                ),
            ],
            if (isAdmin && !isCreator && user.id != widget.currentUserId)
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text(
                  'Remove from Group',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  SocketService.instance.removeGroupMember(_group.id, user.id);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              SocketService.instance.deleteGroup(_group.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: _editGroupDetails,
            ),
        ],
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

          // 3. Members List Header & Add Member Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MEMBERS (${_group.members.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  onPressed: _addMemberDialog,
                ),
            ],
          ),
          const SizedBox(height: 8),

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
                  onTap: () =>
                      _showMemberOptionsBottomSheet(user, isMemberAdmin),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: avatarColorFor(user.id),
                    backgroundImage:
                        (user.image != null && user.image!.isNotEmpty)
                        ? NetworkImage(user.image!)
                        : null,
                    child: (user.image == null || user.image!.isEmpty)
                        ? Text(
                            user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    user.username.isNotEmpty ? user.username : user.name,
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
          const SizedBox(height: 32),

          // 5. Delete Group Action (Admin Only)
          if (isAdmin)
            ElevatedButton.icon(
              onPressed: _confirmDeleteGroup,
              icon: const Icon(Icons.delete, size: 18, color: Colors.white),
              label: const Text(
                'Delete Group',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
