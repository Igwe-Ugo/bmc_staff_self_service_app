import 'package:bmc_app/features/common/widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/network/provider/widget.dart';
import '../../core/network/services/widget.dart';
import '../chatting/widget.dart';

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
          // Fix overflow: wrap Column in SingleChildScrollView
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 TOP BAR
                GestureDetector(
                  onTap: () async {
                    onClose();
                    await Future.delayed(const Duration(milliseconds: 200));
                    navBarVisible.value = true;
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.black12.withOpacity(0.3)
                        : Theme.of(context).hoverColor,
                    child: Icon(Iconsax.arrow_left, size: 20),
                  ),
                ),

                const SizedBox(height: 32),

                /// 🔹 PROFILE SECTION
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    // Guard: if user is null (mid-logout), show nothing
                    final user = userProvider.user;
                    if (user == null) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.15),
                            child: userProvider.hasAvatar
                                ? UserAvatar(
                                    image: userProvider.avatar,
                                    initials: userProvider.initials,
                                    radius: 40,
                                  )
                                : UserAvatar(
                                    image: userProvider.avatar,
                                    initials: userProvider.initials,
                                    radius: 40,
                                  ),
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
                                // Safe: using local `user` variable, no `!`
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: user.privileges.map((p) {
                                    final parts = p.split('~');
                                    final label = parts.length > 1
                                        ? parts[1]
                                        : p; // safe split
                                    return Chip(
                                      label: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      backgroundColor:
                                          Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.1)
                                          : Colors.white,
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
                _personalMenuItem(context),
                const SizedBox(height: 32),
                _systemMenuItems(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _personalMenuItem(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // inside ScrollView
        children: [
          ListTile(
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
            onTap: () => GoRouter.of(
              context,
            ).go('${BMCRouter.homePath}/${BMCRouter.profilePath}'),
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Iconsax.folder_cloud),
            trailing: const Icon(Iconsax.arrow_right_3, size: 15),
            title: const Text(
              'My Documents',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            onTap: () => GoRouter.of(
              context,
            ).go('${BMCRouter.homePath}/${BMCRouter.documentsPath}'),
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Iconsax.chart_1),
            trailing: const Icon(Iconsax.arrow_right_3, size: 15),
            title: const Text(
              'Stats',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            onTap: () => GoRouter.of(
              context,
            ).go('${BMCRouter.homePath}/${BMCRouter.statsPath}'),
          ),
        ],
      ),
    );
  }

  Widget _systemMenuItems(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // inside ScrollView
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
            onTap: () => GoRouter.of(
              context,
            ).go('${BMCRouter.homePath}/${BMCRouter.aboutAppPath}'),
          ),
          const SizedBox(height: 14),

          Consumer5<
            UserProvider,
            AuthProvider,
            LeaveProvider,
            RotaProvider,
            AvailabilityProvider
          >(
            builder:
                (
                  context,
                  userProvider,
                  authProvider,
                  leaveProvider,
                  rotaProvider,
                  availabilityProvider,
                  _,
                ) {
                  final AuthServices authServices = AuthServices();
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
                    onTap: () async {
                      // 1. Safe frame-aligned navigation redirect
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          GoRouter.of(context).go(BMCRouter.loginPath);
                          showMessage(
                            'Logout Successful!',
                            context,
                            status: MessageStatus.success,
                          );
                        }
                      });
                      // 2. Wipe out data states from memory immediately
                      userProvider.clear();
                      leaveProvider.clearUserData();
                      rotaProvider.clearUserData();
                      availabilityProvider.clearUserData();

                      // 3. Trigger the secure storage & backend token invalidation
                      authProvider.reset();
                      await authServices
                          .logout(); // Calling your service clear block
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
