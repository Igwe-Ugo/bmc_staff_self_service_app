import 'package:bmc_app/features/common/nav_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 TOP BAR
              IconButton(
                onPressed: (){
                  onClose();
                  navBarVisible.value = true;
                },
                icon: const Icon(Iconsax.arrow_circle_left, size: 40),
              ),

              const SizedBox(height: 32),

              /// 🔹 PROFILE SECTION
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
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

              /// 🔹 MENU ITEMS
              _menuItem("assets/icons/user.svg", "My Profile"),
              _menuItem("assets/icons/folder.svg", "My Documents"),
              _menuItem("assets/icons/setting.svg", "Settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String icon, String title) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: SvgPicture.asset(icon),
        trailing: Icon(Iconsax.arrow_right_3, size: 15,),
        title: Text(
            title,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w400,
            fontSize: 14
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
