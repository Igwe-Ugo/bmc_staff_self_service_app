// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/network/provider/widget.dart';
import 'widget.dart';

enum NavStyle { floating, stationary }

class BMCAppNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final NavStyle navStyle;
  final bool hideNavBar;

  const BMCAppNavBar({
    super.key,
    required this.navigationShell,
    this.hideNavBar = false,
    this.navStyle = NavStyle.floating,
  });

  @override
  State<BMCAppNavBar> createState() => _BMCAppNavBarState();
}

class _BMCAppNavBarState extends State<BMCAppNavBar> {
  static final _navItems = [
    _NavItem(
      onIconName: 'assets/icons/home_on.svg',
      offIconName: 'assets/icons/home.svg',
      label: 'Home',
      isTelemedicine: false,
    ),
    _NavItem(
      onIconName: 'assets/icons/calendar-add_on.svg',
      offIconName: 'assets/icons/calendar-add.svg',
      label: 'Availability',
      isTelemedicine: false,
    ),
    _NavItem(
      onIconName: 'assets/icons/share_on.svg',
      offIconName: 'assets/icons/share.svg',
      label: 'Rota',
      isTelemedicine: false,
    ),
    _NavItem(
      onIconName: 'assets/icons/brifecase-timer_on.svg',
      offIconName: 'assets/icons/brifecase-timer.svg',
      label: 'Leave',
      isTelemedicine: false,
    ),
    _NavItem(
      onIconName: 'assets/icons/telemedicine.svg',
      offIconName: 'assets/icons/telemedicine_on.svg',
      label: 'TeleMed',
      isTelemedicine: true,
    ),
  ];

  int _getUiIndexFromShellIndex(int shellIndex, List<_NavItem> visibleItems) {
    if (shellIndex >= _navItems.length) return 0;
    final item = _navItems[shellIndex];
    final index = visibleItems.indexOf(item);
    return index != -1 ? index : 0;
  }

  void _onItemTapped(int uiIndex, List<_NavItem> visibleItems) {
    final selectedItem = visibleItems[uiIndex];
    final actualShellIndex = _navItems.indexOf(selectedItem);

    widget.navigationShell.goBranch(
      actualShellIndex,
      initialLocation: actualShellIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    // Check telemedicine privilege
    bool hasTelemedicine = false;
    if (user != null) {
      hasTelemedicine = user.privileges.any((p) {
        final lower = p.toLowerCase();
        return lower.contains('operate~telemedicine') ||
            lower.contains('operate~telemed') ||
            lower == 'operate~telemedicine' ||
            lower == 'operate~telemed';
      });
    }

    // Print to console for debugging
    debugPrint('🔑 User Privileges: ${user?.privileges}');
    debugPrint('🩺 Has Telemedicine: $hasTelemedicine');

    final visibleItems = _navItems.where((item) {
      if (item.isTelemedicine) return hasTelemedicine;
      return true;
    }).toList();

    final currentShellIndex = widget.navigationShell.currentIndex;
    final selectedUiIndex = _getUiIndexFromShellIndex(
      currentShellIndex,
      visibleItems,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: navBarVisible,
      builder: (context, _isNavVisible, _) {
        return Scaffold(
          extendBody: true,
          body: widget.navigationShell,
          bottomNavigationBar: _isNavVisible == true
              ? _buildNavBar(
                  context,
                  visibleItems,
                  selectedUiIndex,
                  hasTelemedicine,
                  (index) => _onItemTapped(index, visibleItems),
                )
              : null,
        );
      },
    );
  }

  Widget _buildNavBar(
    BuildContext context,
    List<_NavItem> items,
    int selectedUiIndex,
    bool hasTelemedicine,
    Function(int) onTap,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(5, 8, 5, bottomPadding + 5),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(50),
        shadowColor: Colors.black.withOpacity(0.5),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 1.0,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              return _NavTile(
                item: items[index],
                isActive: index == selectedUiIndex,
                onTap: () => onTap(index), // ✅ Fixed: call onTap with index
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
      onTap: onTap, // ✅ Fixed: use the callback directly
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
            SvgPicture.asset(
              isActive ? item.onIconName : item.offIconName,
              height: 25,
              width: 25,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
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
  final bool isTelemedicine;

  const _NavItem({
    required this.offIconName,
    required this.onIconName,
    required this.label,
    this.isTelemedicine = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NavItem &&
          offIconName == other.offIconName &&
          onIconName == other.onIconName &&
          label == other.label &&
          isTelemedicine == other.isTelemedicine;

  @override
  int get hashCode =>
      offIconName.hashCode ^
      onIconName.hashCode ^
      label.hashCode ^
      isTelemedicine.hashCode;
}
