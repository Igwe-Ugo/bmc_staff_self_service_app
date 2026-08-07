import 'package:bmc_app/features/common/widget.dart';
import 'package:flutter/material.dart';
import '../../core/network/models/user_model.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onStartChat;

  const UserDetailsScreen({super.key, required this.user, this.onStartChat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar and Name
          Center(
            child: Column(
              children: [
                (user.image != null && user.image!.isNotEmpty)
                    ? UserAvatar(
                        image: user.image!,
                        initials: user.initials,
                        radius: 60,
                        initialsColor: Colors.white,
                      )
                    : UserAvatar(
                        image: user.image ?? '',
                        initials: user.initials,
                        radius: 60,
                        initialsColor: Colors.white,
                      ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.clinicalRoleLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.clinicalRoleLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact & Department Details
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.business, size: 20),
                  title: const Text(
                    'Department',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    user.deptName ?? user.defaultDept ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.email_outlined, size: 20),
                  title: const Text(
                    'Email Address',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    user.email.isNotEmpty ? user.email : 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, size: 20),
                  title: const Text(
                    'Phone Number',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    user.telno ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button to Start Direct Chat
          if (onStartChat != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onStartChat!();
              },
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('Send Message'),
              style: ElevatedButton.styleFrom(
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
