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
import '../telemedicine/widget.dart';

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
      currentTime = DateFormat('hh:mm:ss a').format(now);
      currentDate = DateFormat('EE, MMMM d, yyyy').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      UserProvider,
      AvailabilityProvider,
      LeaveProvider,
      TeleMedicineProvider
    >(
      builder:
          (
            context,
            userProvider,
            availabilityProvider,
            leaveProvider,
            teleMedProvider,
            _,
          ) {
            if (userProvider.isLoading || availabilityProvider.isLoading) {
              return Scaffold(
                body: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Theme.of(context).primaryColor,
                    size: 70,
                  ),
                ),
              );
            }

            // Check telemedicine privilege
            final user = userProvider.user;
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

            return Scaffold(
              body: CustomMaterialIndicator(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black12.withOpacity(0.3)
                    : Theme.of(context).hoverColor,
                onRefresh: _refreshAllProviders,
                indicatorBuilder: (context, controller) {
                  return Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Theme.of(context).primaryColor,
                      size: 40,
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/login.png"),
                          fit: BoxFit.cover,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1E2F)
                                : Colors.white,
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1E2F)
                                : Colors.white,
                          ],
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
                          child: Column(
                            children: [
                              _welcomeCard(context, userProvider),
                              const SizedBox(height: 24),
                              if (teleMedProvider.guestTodayVisits.isNotEmpty &
                                      hasTelemedicine ==
                                  true)
                                Column(
                                  children: [
                                    TeleMedGuestHomeVisits(
                                      teleMedicineProvider: teleMedProvider,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              RotaSummary(),
                              const SizedBox(height: 24),
                              LeaveSummaryCard(),
                              const SizedBox(height: 24),
                              const WeeklyAvailabilityWidget(),
                              const SizedBox(height: 24),
                              CombinedCarouselCalendar(),
                            ],
                          ),
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
                      left: _showDrawer
                          ? 0
                          : -MediaQuery.of(context).size.width,
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
          image: AssetImage(
            "assets/images/beautiful-strawberry-garden-sunrise.png",
          ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  userProvider.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Spacer(),
                SvgPicture.asset(
                  'assets/icons/weather.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Gleanings for the day",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const Divider(color: Colors.white30, height: 12),
            const Text(
              "Philippians 4:13",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "I can do all things through Christ who strengthens me.",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topNavBar(
    BuildContext context, {
    required UserProvider userProvider,
    required VoidCallback onProfileTap,
  }) {
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
              child: userProvider.hasAvatar
                  ? UserAvatar(
                      image: userProvider.avatar,
                      initials: userProvider.initials,
                      radius: 16,
                    )
                  : UserAvatar(
                      image: userProvider.avatar,
                      initials: userProvider.initials,
                      radius: 16,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentTime,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currentDate,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final themeProvider = Provider.of<DarkThemeProvider>(
                context,
                listen: false,
              );
              themeProvider.darkTheme = !themeProvider.darkTheme;
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black12.withOpacity(0.3)
                  : Theme.of(context).hoverColor,
              child: Icon(isDark ? Iconsax.sun_1 : Iconsax.moon, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          MessageBadgeIcon(),
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
