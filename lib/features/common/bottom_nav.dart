import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

enum NavStyle { floating, stationary }

class BMCAppNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final NavStyle navStyle;

  const BMCAppNavBar({
    super.key,
    required this.navigationShell,
    this.navStyle = NavStyle.floating,
  });

  @override
  State<BMCAppNavBar> createState() => _BMCAppNavBarState();
}

class _BMCAppNavBarState extends State<BMCAppNavBar> {
  static final _navItems = [
    _NavItem(onIconName: 'assets/icons/home_on.svg', offIconName: 'assets/icons/home.svg', label: 'Home'),
    _NavItem(onIconName: 'assets/icons/calendar-add_on.svg', offIconName: 'assets/icons/calendar-add.svg', label: 'Availability'),
    _NavItem(onIconName: 'assets/icons/share_on.svg', offIconName: 'assets/icons/share.svg', label: 'Rota'),
    _NavItem(onIconName: 'assets/icons/brifecase-timer_on.svg', offIconName: 'assets/icons/brifecase-timer.svg', label: 'Leave'),
    _NavItem(onIconName: 'assets/icons/messages_on.svg', offIconName: 'assets/icons/messages.svg', label: 'Messages'),
  ];

  int _shellIndexToUiIndex(int shellIndex) => shellIndex;

  void _onItemTapped(int uiIndex) {
    final shellIndex = uiIndex;
    widget.navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedUiIndex =
    _shellIndexToUiIndex(widget.navigationShell.currentIndex);

    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: _buildNavBar(context, selectedUiIndex),
    );
  }

  Widget _buildNavBar(BuildContext context, int selectedUiIndex) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 12),
      child: Material(
        elevation: 10, // 🔥 REAL elevation
        borderRadius: BorderRadius.circular(50),
        shadowColor: Colors.black.withOpacity(0.5),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (index) {
              return _NavTile(
                item: _navItems[index],
                isActive: index == selectedUiIndex,
                onTap: () => _onItemTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Single Nav Tile ───────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  // Purple from the screenshot
  static const _activeColor = Color(0xFFB8B0E8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? _activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Menu item uses a slightly larger icon, others are standard
            SvgPicture.asset(
              isActive ? item.onIconName : item.offIconName,
              height: 25,
              width: 25,
            ),
            // Animate label in/out for active state (non-menu items only)
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _NavItem {
  final String offIconName;
  final String onIconName;
  final String label;
  const _NavItem({required this.offIconName, required this.onIconName, required this.label});
}
