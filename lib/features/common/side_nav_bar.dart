import 'package:bmc_app/features/common/nav_visibility.dart';
import 'package:bmc_app/features/common/router.dart';
import 'package:bmc_app/features/common/widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/network/provider/widget.dart';

class ProfileDrawer extends StatelessWidget {
  final VoidCallback onClose;

  const ProfileDrawer({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 TOP BAR
              IconButton(
                onPressed: () async {
                  onClose();
                  await Future.delayed(const Duration(milliseconds: 200));
                  navBarVisible.value = true;
                },
                icon: const Icon(Iconsax.arrow_left, size: 20),
              ),

              const SizedBox(height: 32),

              /// 🔹 PROFILE SECTION — only this section needs user data
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).hoverColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // Avatar: show network image if available, else initials
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                          child: userProvider.hasAvatar ? UserAvatar(
                            image:    userProvider.avatar,
                            initials: userProvider.initials,
                            radius:   40,
                          ) : null,
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProvider.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: userProvider.user!.privileges.map((p) {
                                  return Chip(
                                    label: Text(
                                      p.split('~')[1],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    backgroundColor:
                                    Theme.of(context).primaryColor.withOpacity(0.1),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              /// 🔹 PERSONAL ITEMS — no user data needed, no Consumer
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).hoverColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _personalMenuItem(context),
              ),

              const SizedBox(height: 32),

              /// 🔹 SYSTEM ITEMS
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).hoverColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _systemMenuItems(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personalMenuItem(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            hoverColor: Theme.of(context).primaryColor.withOpacity(0.5),
            selectedColor: Theme.of(context).primaryColor,
            leading: const Icon(Iconsax.profile_add),
            trailing: const Icon(Iconsax.arrow_right_3, size: 15),
            title: const Text(
              'My Profile',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            onTap: () => GoRouter.of(context).go(
              '${BMCRouter.homePath}/${BMCRouter.profileSummaryPath}',
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Iconsax.folder_cloud),
            trailing: const Icon(Iconsax.arrow_right_3, size: 15),
            title: const Text(
              'Notes',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Iconsax.setting_2),
            trailing: const Icon(Iconsax.arrow_right_3, size: 15),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _systemMenuItems(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Iconsax.note_text),
            trailing: const Icon(Iconsax.arrow_right_3, size: 15),
            title: const Text(
              'About',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            onTap: () => GoRouter.of(context).go(
              '${BMCRouter.homePath}/${BMCRouter.aboutAppPath}',
            ),
          ),
          const SizedBox(height: 14),

          // ✅ Logout clears UserProvider too
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return ListTile(
                leading: const Icon(Iconsax.logout),
                trailing: const Icon(Iconsax.arrow_right_3, size: 15),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  userProvider.clear();
                  GoRouter.of(context).go(BMCRouter.loginPath);
                },
              );
            },
          ),

          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.language),
            trailing: const Icon(Iconsax.arrow_right_3, size: 15),
            title: const Text(
              'Visit BMC website',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
