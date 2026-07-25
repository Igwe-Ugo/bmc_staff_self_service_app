import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/network/models/widget.dart'; // Adjust import path to your ChatUser model

class CreateGroupModal extends StatefulWidget {
  final List<ChatUser> availableUsers;
  final Function(
    String name,
    String description,
    List<ChatUser> selectedMembers,
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

  // Track selected members using a Set for clean add/remove lookups
  final Set<ChatUser> _selectedUsers = {};

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleUserSelection(ChatUser user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
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
                  SizedBox(width: 10),
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
                text: TextSpan(
                  text: "Group Name ",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
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
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
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
                      text: "(${_selectedUsers.length} selected)",
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.availableUsers.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFF1E2638),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final user = widget.availableUsers[index];
                      final isSelected = _selectedUsers.contains(user);

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
                                  onChanged: (_) => _toggleUserSelection(user),
                                  activeColor: const Color(0xFF6366F1),
                                  side: const BorderSide(
                                    color: textMutedColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Avatar
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: user.avatarColor,
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // User Name
                              Expanded(
                                child: Text(
                                  user.name,
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

                      widget.onCreateGroup(
                        groupName,
                        _descriptionController.text.trim(),
                        _selectedUsers.toList(),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF312E81,
                      ), // Dark indigo button
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
