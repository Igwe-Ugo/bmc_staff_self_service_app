import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/network/models/widget.dart';

class PresenceStatusBadge extends StatelessWidget {
  final PresenceFlags presence;

  const PresenceStatusBadge({
    super.key,
    required this.presence,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Online / Cloud / Notification indicator
        _buildCircleIcon(
          icon: Iconsax.cloud,
          isActive: presence.online,
          activeColor: const Color(0xFF3B82F6), // Blue
        ),
        const SizedBox(width: 4),

        // 2. Local connection indicator
        _buildCircleIcon(
          icon: Iconsax.home_2,
          isActive: presence.local,
          activeColor: const Color.fromARGB(255, 232, 3, 144), // Blue
        ),
        const SizedBox(width: 4),

        // 3. Mobile connection indicator
        _buildCircleIcon(
          icon: Iconsax.mobile,
          isActive: presence.mobile,
          activeColor: const Color(0xFF10B981), // Green
        ),
      ],
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
  }) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isActive
            ? activeColor
            : const Color(0xFF1F2937).withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 13,
        color: isActive ? Colors.white : const Color(0xFF4B5563),
      ),
    );
  }
}
