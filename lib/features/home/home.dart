import 'package:bmc_app/features/home/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/network/provider/widget.dart';
import '../availability/widget.dart';
import '../common/widget.dart';
import '../leave/widget.dart';

class BMCHome extends StatefulWidget {
  const BMCHome({super.key});

  @override
  State<BMCHome> createState() => _BMCHomeState();
}

class _BMCHomeState extends State<BMCHome> {
  int _selectedDayIndex = 1; // Monday selected by default
  bool _showDrawer = false;
  late String currentDate;
  late String currentTime;

  @override
  void initState() {
    super.initState();
    _updateDateTime();

    // Initialize availability data when home loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AvailabilityProvider>(context, listen: false).init();
    });

    // Updates every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _updateDateTime();
      }
      return mounted;
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm a').format(now);
      currentDate = DateFormat('EE, MMMM d').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // UI Theme Palette mapping matching your screenshots
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF888888);

    return Consumer3<UserProvider, AvailabilityProvider, LeaveProvider>(
      builder: (context, userProvider, availabilityProvider, leaveProvider, _) {
        if (userProvider.isLoading || availabilityProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
                  child: Column(
                    children: [
                      _welcomeCard(context, userProvider),
                      const SizedBox(height: 24),

                      const _SectionTitle(title: "My Rota", badge: "23", isRota: true),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 190,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _buildRotaCard(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LeaveSummaryCard(),
                      const SizedBox(height: 24),

                      const _SectionTitle(title: "My Availability", badge: "14", isRota: false),
                      const SizedBox(height: 14),
                      const WeeklyAvailabilityWidget(),
                      const SizedBox(height: 24),

                      const _SectionTitle(title: "Recent Messages", badge: "5", isRota: false),
                      const SizedBox(height: 14),
                      _buildMessagesList(userProvider, Theme.of(context).cardColor),
                      const SizedBox(height: 24),

                      const _SectionTitle(title: "Recent Notifications", badge: "10", isRota: false),
                      const SizedBox(height: 14),
                      _buildNotificationList(userProvider, Theme.of(context).cardColor),
                    ],
                  ),
                ),
              ),
              _topNavBar(context, userProvider: userProvider, onProfileTap: () {setState(() {_showDrawer = true; navBarVisible.value = false;});},),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                left: _showDrawer ? 0 : -MediaQuery.of(context).size.width,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ProfileDrawer(
                    onClose: () {
                      setState(() => _showDrawer = false);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UI Component Builders ---

  Widget _welcomeCard(BuildContext context, UserProvider userProvider) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage("assets/images/beautiful-strawberry-garden-sunrise.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "${_getGreeting()}, ",
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  userProvider.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w300),
                ),
                const Spacer(),
                SvgPicture.asset('assets/icons/weather.svg', width: 20, height: 20)
              ],
            ),
            const SizedBox(height: 6),
            const Text("Gleanings for the day", style: TextStyle(color: Colors.white70, fontSize: 11)),
            const Divider(color: Colors.white30, height: 12),
            const Text("Philippians 4:13", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            const Text("I can do all things through Christ who strengthens me.", style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRotaCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> rotas = [
      {
        'color': const Color(0xFF6C47FF),
        'dayNumber': "01", 'month': "May", 'day': "Today",
        'label': "On Call", 'shiftDuty': "Consultant", 'shiftRoom': "Ward one", 'active': true
      },
      {
        'color': isDark ? const Color(0xFF27273F) : Colors.white,
        'dayNumber': "02", 'month': "May", 'day': "Tue",
        'label': "All Day", 'shiftDuty': "No Shift", 'shiftRoom': "", 'active': false
      },
      {
        'color': const Color(0xFFFFF3E0),
        'dayNumber': "03", 'month': "May", 'day': "Wed",
        'label': "Night Shift", 'shiftDuty': "Consultant", 'shiftRoom': "Ward two", 'active': false
      }
    ];

    return rotas.map((rota) {
      final bool customColored = rota['active'] || rota['label'] == "Night Shift";
      final Color textColor = customColored
          ? (rota['label'] == "Night Shift" ? const Color(0xFFF39C12) : Colors.white)
          : (isDark ? Colors.white : const Color(0xFF1A1A2E));

      return Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: rota['color'],
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: Colors.black12.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rota['dayNumber'], style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                Text(rota['day'], style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
              ],
            ),
            Text(rota['month'], style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7))),
            const SizedBox(height: 16),
            Text(rota['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
            const Spacer(),
            Text(rota['shiftDuty'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
            if (rota['shiftRoom'].toString().isNotEmpty)
              Text(rota['shiftRoom'], style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6))),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLeaveRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLeaveMenuTile(String label, Color indicatorColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Icon(Icons.chevron_right, size: 16)
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: indicatorColor, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar(AvailabilityProvider provider, Color cardColor) {
    final List<Map<String, dynamic>> staticDays = [
      {'day': 'S', 'date': '30', 'dots': [Colors.green]},
      {'day': 'M', 'date': '01', 'dots': [Colors.green]},
      {'day': 'T', 'date': '02', 'dots': [Colors.green, Colors.orange]},
      {'day': 'W', 'date': '03', 'dots': [Colors.green, Colors.orange]},
      {'day': 'T', 'date': '04', 'dots': [Colors.red]},
      {'day': 'F', 'date': '05', 'dots': [Colors.red]},
      {'day': 'S', 'date': '06', 'dots': [Colors.green]},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(staticDays.length, (index) {
          final item = staticDays[index];
          final bool isSelected = index == _selectedDayIndex;

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 42,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C47FF).withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: const Color(0xFF6C47FF), width: 1.5) : null,
              ),
              child: Column(
                children: [
                  Text(item['day'], style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(item['date'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: (item['dots'] as List<Color>).map((color) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 5, height: 5,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    )).toList(),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMessagesList(UserProvider userProvider, Color cardColor) {
    final List<Map<String, dynamic>> msgs = [
      {'title': 'I won’t come to work tomorrow ma', 'subtitle': 'Today', 'badge': 'Ugoo', 'color': Colors.green, 'time': '12:50pm'},
      {'title': 'Please don’t involve me', 'subtitle': 'Today', 'badge': 'Richard', 'color': Colors.red, 'time': '12:50pm'},
      {'title': 'Help buy food while coming tomorrow', 'subtitle': 'Yesterday', 'badge': 'Uzo', 'color': Colors.blue, 'time': '12:50pm'},
      {'title': 'Send me that money nah', 'subtitle': 'Yesterday', 'badge': 'Igwe', 'color': Colors.amber, 'time': '12:50pm'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: msgs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _listTileCard(msgs[index], cardColor),
    );
  }

  Widget _buildNotificationList(UserProvider userProvider, Color cardColor) {
    final List<Map<String, dynamic>> notes = [
      {'title': 'Availability window open closes 30/05/2026 at 23:59', 'subtitle': '2 Days left', 'badge': 'Admin', 'color': const Color(0xFF6C47FF), 'time': '12:50pm'},
      {'title': 'Ugoo wants is giving you his shift', 'subtitle': 'Swap Request', 'badge': 'Ugoo', 'color': Colors.green, 'time': '12:50pm'},
      {'title': 'Leave Request', 'subtitle': 'Approved', 'badge': 'Admin', 'color': const Color(0xFF6C47FF), 'time': '12:50pm'},
      {'title': 'Swap shift with Ugochukwu Igwe', 'subtitle': 'Accepted', 'badge': 'Igwe', 'color': Colors.amber, 'time': '12:50pm'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _listTileCard(notes[index], cardColor),
    );
  }

  Widget _listTileCard(Map<String, dynamic> item, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: item['color'], width: 4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: (item['color'] as Color).withOpacity(0.2),
            child: Icon(Icons.person, size: 16, color: item['color']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item['subtitle'], style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(item['badge'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item['color'])),
              ),
              const SizedBox(height: 4),
              Text(item['time'], style: TextStyle(fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _topNavBar(BuildContext context, {required UserProvider userProvider, required VoidCallback onProfileTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      height: 100,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onProfileTap(),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: UserAvatar(image: userProvider.avatar, initials: userProvider.initials, radius: 16),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(currentDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 6),
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const Spacer(),
          GestureDetector(
            onTap: (){
              final themeProvider = Provider.of<DarkThemeProvider>(context, listen: false);
              themeProvider.darkTheme = !themeProvider.darkTheme;
            },
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black12.withOpacity(0.3) : Theme.of(context).hoverColor,
              child: Icon(isDark ? Iconsax.sun_1 : Iconsax.moon, size: 25),
            ),
          ),
          const SizedBox(width: 12),
          MessageBadgeIcon(),
          const SizedBox(width: 12),
          NotificationBadgeIcon(),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String badge;
  final bool isRota;

  const _SectionTitle({required this.title, required this.badge, required this.isRota});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A2E);
    return Row(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
        if (isRota) ...[
          const SizedBox(width: 4),
          Text("| This Month", style: TextStyle(fontWeight: FontWeight.w300, fontSize: 12, color: textColor.withOpacity(0.7))),
        ],
        const SizedBox(width: 6),
        CircleAvatar(
          radius: 9,
          backgroundColor: const Color(0xFF6C47FF).withOpacity(0.2),
          child: Text(badge, style: const TextStyle(fontSize: 10, color: Color(0xFF6C47FF), fontWeight: FontWeight.bold)),
        ),
        const Spacer(),
        Text("View All", style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6), decoration: TextDecoration.underline)),
        const SizedBox(width: 2),
        Icon(Iconsax.arrow_right_3, size: 12, color: textColor.withOpacity(0.6)),
      ],
    );
  }
}
