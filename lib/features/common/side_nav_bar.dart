import 'package:bmc_app/features/common/nav_visibility.dart';
import 'package:bmc_app/features/common/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

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

              /// 🔹 PROFILE SECTION
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).hoverColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/images/profile_pic.png'),
                    ),
                    const SizedBox(width: 22),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Orji Ugochukwu",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Nurse",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey),
                        ),
                      ]),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              /// 🔹 personal ITEMS
              Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).hoverColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _personalMenuItem(context)
              ),
              const SizedBox(height: 32,),
              /// 🔹 system ITEMS
              Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).hoverColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _systemMenuItems(context)
              )
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
              leading: Icon(Iconsax.profile_add),
              trailing: Icon(Iconsax.arrow_right_3, size: 15),
              title: Text(
                "My Profile",
                style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 14
                ),
              ),
              onTap: () => GoRouter.of(context).go("${BMCRouter.homePath}/${BMCRouter.profilePath}"),
            ),
            const SizedBox(height: 14,),
            ListTile(
              leading: Icon(Iconsax.folder_cloud),
              trailing: Icon(Iconsax.arrow_right_3, size: 15,),
              title: Text(
                "Notes",
                style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 14
                ),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 14,),
            ListTile(
              leading: Icon(Iconsax.setting_2),
              trailing: Icon(Iconsax.arrow_right_3, size: 15,),
              title: Text(
                "Settings",
                style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 14
                ),
              ),
              onTap: () {},
            )
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
            leading: Icon(Iconsax.note_text),
            trailing: Icon(Iconsax.arrow_right_3, size: 15,),
            title: Text(
              "About",
              style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w400,
                  fontSize: 14
              ),
            ),
            onTap: () => GoRouter.of(context).go("${BMCRouter.homePath}/${BMCRouter.aboutAppPath}"),
          ),
          const SizedBox(height: 14,),
          ListTile(
            leading: Icon(Iconsax.logout),
            trailing: Icon(Iconsax.arrow_right_3, size: 15,),
            title: Text(
              "logout",
              style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w400,
                  fontSize: 14
              ),
            ),
            onTap: () => GoRouter.of(context).go(BMCRouter.loginPath),
          ),
          const SizedBox(height: 14,),
          ListTile(
            leading: Icon(Icons.language),
            trailing: Icon(Iconsax.arrow_right_3, size: 15,),
            title: Text(
              "Visit BMC website",
              style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w400,
                  fontSize: 14
              ),
            ),
            onTap: () {},
          )
        ],
      ),
    );
  }
}
