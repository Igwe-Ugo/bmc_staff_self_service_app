import 'package:bmc_app/features/home/widget.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/network/provider/widget.dart';
import '../availability/widget.dart';
import '../common/widget.dart';
import '../leave/widget.dart';
import '../rota/widget.dart';

class BMCHome extends StatefulWidget {
  const BMCHome({super.key});

  @override
  State<BMCHome> createState() => _BMCHomeState();
}

class _BMCHomeState extends State<BMCHome> {
  bool _showDrawer = false;
  late String currentDate;
  late String currentTime;

  // 1. Separate your data fetching logic into a Future-returning method
  Future<void> _refreshAllProviders() async {
    // Return a combined future so the RefreshIndicator waits for all network requests to finish
    await Future.wait([
      // Ensure these return a Future in your providers
      Future.microtask(() => context.read<AvailabilityProvider>().init()),
      context.read<LeaveProvider>().refresh(),
      context.read<RotaProvider>().loadShiftsForMonth(context, DateTime.now()),
    ]);
  }

  // 2. Keep the infinite background clock loop entirely separate so it only starts ONCE
  void _startClockTimer() {
    _updateDateTime();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _updateDateTime();
      }
      return mounted;
    });
  }

  @override
  void initState() {
    super.initState();

    // Start the clock loop once
    _startClockTimer();

    // Fetch initial network data when the home page mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshAllProviders();
      }
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
    return Consumer3<UserProvider, AvailabilityProvider, LeaveProvider>(
      builder: (context, userProvider, availabilityProvider, leaveProvider, _) {
        if (userProvider.isLoading || availabilityProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: CustomMaterialIndicator(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black12.withOpacity(0.3) : Theme.of(context).hoverColor,
            onRefresh: _refreshAllProviders,
            indicatorBuilder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Theme.of(context).primaryColor,
                  size: 40,
                )
              );
            },
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
                    child: Column(
                      children: [
                        _welcomeCard(context, userProvider),
                        const SizedBox(height: 24),
                        RotaSummary(),
                        const SizedBox(height: 24),
                        LeaveSummaryCard(),
                        const SizedBox(height: 24),
                        const WeeklyAvailabilityWidget(),
                        const SizedBox(height: 24),
                        CombinedCarouselCalendar(),
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
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: Text(badge, style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        ),
        const Spacer(),
        Text("View All", style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6), decoration: TextDecoration.underline)),
        const SizedBox(width: 2),
        Icon(Iconsax.arrow_right_3, size: 12, color: textColor.withOpacity(0.6)),
      ],
    );
  }
}
