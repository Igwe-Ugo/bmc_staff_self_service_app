import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/network/models/widget.dart';
import '../common/widget.dart';
import 'chat_ui_utils.dart';

class CreateGroupModal extends StatefulWidget {
  final List<SocketUser> availableUsers;

  /// Returns the group name, optional description, and the selected members'
  /// USERNAMES (SocketUser.userId) — the identity SocketService.createGroup
  /// expects.
  final void Function(
    String name,
    String description,
    List<String> selectedMemberIds,
  )
  onCreateGroup;

  const CreateGroupModal({
    super.key,
    required this.availableUsers,
    required this.onCreateGroup,
  });

  @override
  State<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<CreateGroupModal> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Keyed by userId (username), not by SocketUser instance — the roster can
  // rebuild SocketUser objects on every presence event, so identity-based
  // Set membership would silently drop a selection mid-edit.
  final Set<String> _selectedUserIds = {};

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleUserSelection(SocketUser user) {
    setState(() {
      if (_selectedUserIds.contains(user.userId)) {
        _selectedUserIds.remove(user.userId);
      } else {
        _selectedUserIds.add(user.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const inputBorderColor = Color(0xFF6366F1); // Accent outline border
    const textMutedColor = Color(0xFF94A3B8);

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Container(
        width: 480, // Restrict width for web/desktop or large screens
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ──────────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Iconsax.user_add,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Create New Group",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Create a group to chat with multiple people at once.",
                style: TextStyle(
                  color: textMutedColor,
                  fontSize: 13,
                  fontFamily: 'Lexend',
                ),
              ),

              const SizedBox(height: 17),

              // ── Group Name Input ───────────────────────────────────────────
              RichText(
                text: const TextSpan(
                  text: "Group Name ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Lexend',
                  ),
                  children: [
                    TextSpan(
                      text: "*",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Enter group name...",
                  hintStyle: const TextStyle(
                    color: textMutedColor,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: inputBorderColor,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: inputBorderColor,
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ── Description Input (Optional) ──────────────────────────────
              Text(
                "Description (Optional)",
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "What's this group about?",
                  hintStyle: const TextStyle(
                    color: textMutedColor,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: inputBorderColor,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: inputBorderColor,
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ── Select Members Section ─────────────────────────────────────
              RichText(
                text: TextSpan(
                  text: "Select Members ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Lexend',
                  ),
                  children: [
                    const TextSpan(
                      text: "* ",
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                      text: "(${_selectedUserIds.length} selected)",
                      style: const TextStyle(
                        color: textMutedColor,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Scrollable User List Frame
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: inputBorderColor, width: 1),
                ),
                child: widget.availableUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No users available',
                          style: TextStyle(
                            color: textMutedColor,
                            fontSize: 13,
                            fontFamily: 'Lexend',
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: widget.availableUsers.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.6),
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final user = widget.availableUsers[index];
                            final isSelected = _selectedUserIds.contains(
                              user.userId,
                            );

                            return InkWell(
                              onTap: () => _toggleUserSelection(user),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    // Checkbox widget
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleUserSelection(user),
                                        activeColor: const Color(0xFF6366F1),
                                        side: const BorderSide(
                                          color: textMutedColor,
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Avatar
                                    CircleAvatar(
                                      radius: 13,
                                      backgroundColor: avatarColorFor(
                                        user.userId,
                                      ),
                                      child: user.avatar != null
                                          ? UserAvatar(
                                              image: user.avatar,
                                              initials: initialsFor(
                                                user.username,
                                              ),
                                              radius: 13,
                                              initialsColor: Colors.white,
                                            )
                                          : CircleAvatar(
                                              radius: 13,
                                              backgroundColor: avatarColorFor(
                                                user.userId,
                                              ),
                                              child: Text(
                                                initialsFor(user.username),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),

                                    const SizedBox(width: 12),

                                    // User Name (display name — see naming
                                    // note in socket_models.dart)
                                    Expanded(
                                      child: Text(
                                        user.username,
                                        style: TextStyle(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Lexend',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              const SizedBox(height: 28),

              // ── Action Buttons ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Button
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.transparent,
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Create Group Button
                  ElevatedButton(
                    onPressed: () {
                      final groupName = _groupNameController.text.trim();
                      if (groupName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a group name'),
                          ),
                        );
                        return;
                      }
                      if (_selectedUserIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select at least one member'),
                          ),
                        );
                        return;
                      }

                      widget.onCreateGroup(
                        groupName,
                        _descriptionController.text.trim(),
                        _selectedUserIds.toList(),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF312E81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Create Group",
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
