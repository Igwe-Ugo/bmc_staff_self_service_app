import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/network/provider/widget.dart';
import '../common/widget.dart';
import 'package:intl/intl.dart';

import '../models/widget.dart';

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
  late ChatUser user;

  @override
  void initState() {
    super.initState();
    _updateDateTime();

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
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        // Show loader while fetching
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (userProvider.state == UserState.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(userProvider.errorMessage ?? 'Failed to load profile'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => userProvider.fetchMe(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 100, 20, 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 5,),
                      _welcomeCard(context, userProvider),
                      const SizedBox(height: 24,),
                      _SectionTitle(title: "My Rota", badge: "23", isRota: true,),
                      SizedBox(height: 18,),
                      SizedBox(
                        height: 240,
                        child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._buildRotaCard(context, [
                              {
                                'color': Theme.of(context).primaryColor,
                                'active': true,
                                'day': "Today",
                                'label': "Morning Shift",
                                'dayNumber': "01",
                                'month': "May",
                                'shiftDuty': "Consultation",
                                'shiftRoom': "Ward One"
                              },
                              {
                                'color': Theme.of(context).primaryColor.withOpacity(0.2),
                                'active': false,
                                'day': "Tue",
                                'label': "All Day",
                                'dayNumber': "02",
                                'month': "May",
                                'shiftDuty': "",
                                'shiftRoom': "No shift"
                              },
                                {
                                'color': Colors.orange.shade200,
                                'active': false,
                                'day': "Tue",
                                'label': "Night Shift",
                                'dayNumber': "03",
                                'month': "May",
                                'shiftDuty': "Consultation",
                                'shiftRoom': "Ward One"
                                }
                            ])
                          ]
                        ),
                      ),
                      SizedBox(height: 32,),
                      _SectionTitle(title: "My Leave", badge: "18", isRota: false,),
                      SizedBox(height: 18,),
                      _buildLeaveCard(),
                      SizedBox(height: 32,),
                      _SectionTitle(title: "My Availability", badge: "18", isRota: false,),
                      SizedBox(height: 18,),
                      buildWeekCalendar(
                        selectedIndex: _selectedDayIndex,
                        onDaySelected: (index) {
                          setState(() => _selectedDayIndex = index);
                        },
                      ),
                      SizedBox(height: 32,),
                      _SectionTitle(title: "Recent Notifications", badge: "10", isRota: false,),
                      SizedBox(height: 18,),
                      _buildNotificationList(userProvider),
                      SizedBox(height: 32,),
                      _SectionTitle(title: "Recent Messages", badge: "5", isRota: false,),
                      SizedBox(height: 18,),
                      _buildMessagesList(userProvider),
                      //_showMoreInfoSheet(),
                    ],
                  ),
                ),
              ),
              _topNavBar(
                context,
                userProvider: userProvider,
                onProfileTap: () {
                  setState(() {
                    _showDrawer = true;
                    navBarVisible.value = false;
                  });
                },
              ),
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
      }
    );
  }

  Widget _welcomeCard(context, UserProvider userProvider){
    return Container(
      height: 185,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: AssetImage("assets/images/beautiful-strawberry-garden-sunrise.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black,
              Colors.transparent,
            ],
          ),
        ),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8,),
                Text(
                  userProvider.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w100,
                  ),
                ),
                const Spacer(),
                SvgPicture.asset('assets/icons/weather.svg')
              ],
            ),
            const SizedBox(height: 19),
            Text(
              "Gleanings for the day",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            Divider(),
            const SizedBox(height: 10),
            Text(
              "Philippians 4:13",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 10,),
            Text(
              "I can do all things through Christ who strengthens me.",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  Widget _topNavBar(BuildContext context, {required VoidCallback onProfileTap, required UserProvider userProvider}){
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => onProfileTap(),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: UserAvatar(
                    image:    userProvider.avatar,
                    initials: userProvider.initials,
                    radius:   18,
                  ),
                ),
              ),
              const SizedBox(width: 10,),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTime,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10,),
              CircleAvatar(
                radius: 7,
                backgroundColor: Color(0xff22C55E).withOpacity(0.3),
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Color(0xff22C55E),
                ),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: (){},
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black12.withOpacity(0.3) : Theme.of(context).hoverColor,
              child: Icon(Iconsax.moon, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white: Colors.black,),
            ),
          ),
          const SizedBox(width: 16,),
          MessageBadgeIcon(),
          const SizedBox(width: 16,),
          NotificationBadgeIcon()
        ],
      ),
    );
  }

  List<Widget> _buildRotaCard(
      BuildContext context, List<Map<String, dynamic>> myRota) {
    return myRota
        .map((rota) => _rotaCard(
      context,
      color: rota['color']!,
      dayNumber: rota['dayNumber']!,
      day: rota['day']!,
      month: rota['month']!,
      label: rota['label']!,
      active: rota['active']!,
      shiftDuty: rota['shiftDuty']!,
      shiftRoom: rota['shiftRoom'],
    )).toList();
  }

  Widget _rotaCard(
      BuildContext context, {
        required Color color,
        required String dayNumber,
        required String day,
        required String month,
        required String label,
        required bool active,
        required String shiftDuty,
        required String shiftRoom,
      }) {
    final textColor = Colors.white;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayNumber,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      )),
                  Text(month,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                      )),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
              )),

          const Spacer(),

          if (active)
            Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 15,
                child: SvgPicture.asset(
                  "assets/icons/arrow-2.svg",
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          const SizedBox(height: 13),
          Text(shiftDuty, style: TextStyle(color: textColor, fontFamily: 'Lexend', fontWeight: FontWeight.w500, fontSize: 15)),
          Text(shiftRoom, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _buildLeaveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Section - Donut chart
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compassionate 2026',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: 0.75,
                            strokeWidth: 12,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        const Text(
                          '75%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '0/0 Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Section
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estimated / Used card
                _buildInfoCard(
                  children: [
                    _buildInfoRow('Estimated', '0'),
                    const SizedBox(height: 6),
                    _buildInfoRow('Used', '0'),
                  ],
                ),
                const SizedBox(height: 10),

                // Carried over / Pending card
                _buildInfoCard(
                  children: [
                    _buildInfoRow('Carried over', '0'),
                    const SizedBox(height: 6),
                    _buildInfoRow('Pending', '0'),
                  ],
                ),
                const SizedBox(height: 10),

                // Sick tile
                _buildArrowTile('Sick'),
                const SizedBox(height: 8),

                // Travel tile
                _buildArrowTile('Travel'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildArrowTile(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: Color(0xFF888888),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(UserProvider userProvider) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Availability window open closes 30/05/2026 at 23:59',
        'subtitle': '2 Days left',
        'metaIcon': Icons.access_time_outlined,
        'badge': 'Admin',
        'badgeColor': Color(0xFFEDE9FF),
        'badgeTextColor': Theme.of(context).primaryColor,
        'time': '12.50pm',
        'borderColor': Theme.of(context).primaryColor,
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'Ugoo wants is giving you his shift',
        'subtitle': 'Swap Request',
        'metaIcon': Icons.swap_horiz,
        'badge': 'Ugoo',
        'badgeColor': Color(0xFFE6F9F0),
        'badgeTextColor': Color(0xFF27AE60),
        'time': '12.50pm',
        'borderColor': Color(0xFF27AE60),
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'Leave Request',
        'subtitle': 'Approved',
        'metaIcon': Icons.check_circle_outline,
        'badge': 'Admin',
        'badgeColor': Color(0xFFEDE9FF),
        'badgeTextColor': Theme.of(context).primaryColor,
        'time': '12.50pm',
        'borderColor': Theme.of(context).primaryColor,
        'icon': Icons.check_circle_outline,
      },
      {
        'title': 'Swap shift with Ugochukwu Igwe',
        'subtitle': 'Accepted',
        'metaIcon': Icons.check_circle_outline,
        'badge': 'Igwe',
        'badgeColor': Color(0xFFFFF3E0),
        'badgeTextColor': Color(0xFFF39C12),
        'time': '12.50pm',
        'borderColor': Color(0xFFF39C12),
        'icon': Icons.check_circle_outline,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = notifications[index];
        return GestureDetector(
            onTap: () {
              navBarVisible.value = false;
              showModalBottomSheet(
                context: context,
                builder: (context) => _showMoreInfoSheet(
                  userProvider: userProvider,
                  colleague: item['badge'],
                  color: item['borderColor'],
                  username: userProvider.displayName,
                  userDept: "Nursing",
                  userAvatar: userProvider.avatar!,
                  title: item['title'],
                  info: item['subtitle'],
                  time: "Yesterday | ${item['time']}",
                ),
              );
            },
            child: _buildCard(item, userProvider),
        );
      },
    );
  }

  Widget _buildMessagesList(UserProvider userProvider) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'I won’t come to work tomorrow ma',
        'subtitle': 'Today',
        'metaIcon': Icons.access_time_outlined,
        'badge': 'Ugoo',
        'badgeColor': Color(0xFF27AE60).withOpacity(0.2),
        'badgeTextColor': Color(0xFF27AE60),
        'time': '12.50pm',
        'borderColor': Color(0xFF27AE60),
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'Please don’t involve me',
        'subtitle': 'Today',
        'metaIcon': Icons.access_time_outlined,
        'badge': 'Ugoo',
        'badgeColor': Color(0xFFDE2626).withOpacity(0.2),
        'badgeTextColor': Color(0xFFDE2626),
        'time': '12.50pm',
        'borderColor': Color(0xFFDE2626),
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'Help buy food while coming tomorrow',
        'subtitle': 'Yesterday',
        'metaIcon': Icons.access_time_outlined,
        'badge': 'Uzo',
        'badgeColor': Color(0xFF3782F3).withOpacity(0.2),
        'badgeTextColor': Color(0xFF3782F3),
        'time': '12.50pm',
        'borderColor': Color(0xFF3782F3),
        'icon': Icons.check_circle_outline,
      },
      {
        'title': 'Send me that money nah',
        'subtitle': 'Yesterday',
        'metaIcon': Icons.access_time_outlined,
        'badge': 'Igwe',
        'badgeColor': Color(0xFFF39C12).withOpacity(0.2),
        'badgeTextColor': Color(0xFFF39C12),
        'time': '12.50pm',
        'borderColor': Color(0xFFF39C12),
        'icon': Icons.check_circle_outline,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = notifications[index];
        return _buildCard(item, userProvider);
      },
    );
  }

  SingleChildScrollView _showMoreInfoSheet({required UserProvider userProvider, required String colleague, required String title, required Color color, required String username, required String userDept, required String userAvatar, required String info, required String time}){
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: _buildHeaderTile(userProvider: userProvider,color: color, title: title, username: username, userDept: userDept, userAvatar: userAvatar, info: info, time: time),
            ),
            const SizedBox(height: 24,),
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swap Summary:',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        fontFamily: 'Lexend'
                    ),
                  ),
                  const SizedBox(height: 24,),
                  Text(
                    'You get: Fri 29 May Night (17.00-08.00)',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      fontFamily: 'Lexend'
                    ),
                  ),
                  const SizedBox(height: 16,),
                  Text(
                    'You give: Sun 31 May Night (17.00 - 08.00)',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        fontFamily: 'Lexend'
                    ),
                  ),
                  const SizedBox(height: 16,),
                  Text(
                    'With $colleague',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        fontFamily: 'Lexend'
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50,),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Color(0xFF27AE60).withOpacity(0.6))
                  ),
                ),
                child: const Text(
                  "Accept",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16,),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  navBarVisible.value = true;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0x88F3C0C0).withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Color(0xFFDE2626).withOpacity(0.6))
                  ),
                ),
                child: const Text(
                  "Reject",
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Lexend',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 70,)
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTile({required UserProvider userProvider, required Color color, required String title, required String username, required String userDept, required String userAvatar, required String info, required String time}) {
    return InkWell(
      onTap: (){},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Avatar
            UserAvatar(
              image:    userProvider.avatar,
              initials: userProvider.initials,
              radius:   22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        info,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userDept,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // State variable to track selected index — declare this in your class:
// int _selectedDayIndex = 1;

  Widget buildWeekCalendar({
    required int selectedIndex,
    required ValueChanged<int> onDaySelected,
  }) {
    final List<Map<String, dynamic>> days = [
      {
        'day': 'S',
        'date': '30',
        'dots': [Color(0xFF4CAF50)],
      },
      {
        'day': 'M',
        'date': '01',
        'dots': [Color(0xFF4CAF50)],
      },
      {
        'day': 'T',
        'date': '02',
        'dots': [Color(0xFF4CAF50), Color(0xFFFFEB3B)],
      },
      {
        'day': 'W',
        'date': '03',
        'dots': [Color(0xFF4CAF50), Color(0xFFFFEB3B)],
      },
      {
        'day': 'T',
        'date': '04',
        'dots': [Color(0xFFF44336)],
      },
      {
        'day': 'F',
        'date': '05',
        'dots': [Color(0xFF4CAF50)],
      },
      {
        'day': 'S',
        'date': '06',
        'dots': <Color>[],
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(days.length, (index) {
          final item = days[index];
          final bool isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEEBF8) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day letter
                  Text(
                    item['day'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : const Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Date number
                  Text(
                    item['date'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF6C47FF)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Dot indicators
                  _buildDotRow(item['dots'] as List<Color>),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDotRow(List<Color> dots) {
    if (dots.isEmpty) {
      return const SizedBox(height: 6);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots.asMap().entries.map((entry) {
        return Container(
          margin: EdgeInsets.only(left: entry.key > 0 ? 3 : 0),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: entry.value,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, UserProvider userProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: item['borderColor'] as Color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: item['badgeTextColor'] as Color,
            child: UserAvatar(
                image: userProvider.avatar,
                initials: userProvider.initials,
              radius: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      item['metaIcon'] as IconData,
                      size: 13,
                      color: const Color(0xFF888888),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    if (item.containsKey('meta')) ...[
                      const SizedBox(width: 4),
                      Text(
                        item['meta'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right side: badge + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: item['badgeColor'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item['badge'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item['badgeTextColor'] as Color,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item['time'] as String,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String badge;
  final bool isRota;

  const _SectionTitle({required this.title, required this.badge, required this.isRota});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Lexend')),
        if (isRota)
          ...[const SizedBox(width: 6),
          Text(
            "| This Month",
              style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 13, fontFamily: 'Lexend')
          ),],
        const SizedBox(width: 6),
        CircleAvatar(
          radius: 10,
          child: Text(
              badge,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend'
              )
          ),
        ),
        const Spacer(),
        const Text(
            "View All",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            fontFamily: 'Lexend',
            decoration: TextDecoration.underline,
          ),
        ),
        GestureDetector(
            onTap: (){},
            child: Icon(Iconsax.arrow_right_3, size: 15)
        ),
      ],
    );
  }
}
