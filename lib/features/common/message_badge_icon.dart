import 'package:bmc_app/features/common/widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/network/provider/widget.dart';

/// Notification icon with badge showing unread count. Tapping navigates to notifications.
class MessageBadgeIcon extends StatelessWidget {
  const MessageBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    // watching total unread messages from chatprovider
    final unreadCount = context.watch<ChatProvider>().totalUnread;
    return InkWell(
      onTap: () {
        GoRouter.of(
          context,
        ).go("${BMCRouter.homePath}/${BMCRouter.messagePath}");
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black12.withOpacity(0.3)
              : Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          clipBehavior: Clip.none,
          children: [
            Icon(
              Iconsax.message,
              size: 20,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -7,
                top: -4,
                child: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.3),
                  radius: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
