import 'package:flutter/material.dart';
import '../../core/network/models/widget.dart';
import 'chat_ui_utils.dart';

class GroupDetailsScreen extends StatelessWidget {
  final ChatGroup group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    // Falls back to creator info if description is absent or empty
    final hasDescription =
        group.description != null && group.description!.trim().isNotEmpty;
    final displayDescription = hasDescription
        ? group.description!
        : 'Created by ${group.createdBy ?? 'Admin'}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Group Header (Name and Icon)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: avatarColorFor(group.id),
                    child: Text(
                      initialsFor(group.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    group.name,
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
                color: Theme.of(context).cardColor,
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

            // 3. Members List
            Text(
              'MEMBERS (${group.members.length})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.members.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.grey, height: 1),
                itemBuilder: (context, index) {
                  final member = group.members[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: avatarColorFor(member),
                      child: Text(
                        initialsFor(member),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(member, style: const TextStyle(fontSize: 13)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
