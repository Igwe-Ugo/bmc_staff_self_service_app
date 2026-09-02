// lib/features/screens/booking_visits_screen.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';
import '../chatting/widget.dart';
import '../common/widget.dart';
import 'widget.dart';

class BookingVisitsScreen extends StatefulWidget {
  const BookingVisitsScreen({super.key});

  @override
  State<BookingVisitsScreen> createState() => _BookingVisitsScreenState();
}

class _BookingVisitsScreenState extends State<BookingVisitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _joiningVisitIds = {};
  final Set<String> _togglingReadyIds = {};

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TeleMedicineProvider>();
      provider.loadVisits();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'TeleMedicine Consultant',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: Consumer<TeleMedicineProvider>(
        builder: (context, teleMedProvider, child) {
          if (teleMedProvider.isLoading) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            );
          }

          if (teleMedProvider.errorMessage != null) {
            return Center(
              child: Text(
                teleMedProvider.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 70.0),
            child: Column(
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: TextField(
                      onChanged: teleMedProvider.updateSearchQuery,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText:
                            'Filter by patient name, MRN, slot, or location...',
                        hintStyle: TextStyle(fontSize: 12),
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(3),
                    dividerColor: Colors.transparent,
                    labelColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    unselectedLabelColor: const Color(0xFF8E8E93),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lexend',
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Lexend',
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Today (${teleMedProvider.todayVisits.length})',
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Upcoming (${teleMedProvider.upcomingVisits.length})',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // List Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVisitsList(
                        teleMedProvider.todayVisits,
                        Theme.of(context).cardColor,
                      ),
                      _buildVisitsList(
                        teleMedProvider.upcomingVisits,
                        Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisitsList(List<QryBookingVisits> visits, Color cardBg) {
    if (visits.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Iconsax.user_search, size: 40),
          SizedBox(height: 15),
          Text(
            'No records found.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        final isReady = (visit.consultantReady ?? false) == true;

        final slot = visit.slotName?.trim() ?? '';
        final location = visit.location?.trim() ?? '';
        final locationText = (location.isEmpty || slot.contains(location))
            ? slot.split('|')[2]
            : '$slot | $location';
        final mrnStr = visit.medrecnum?.toString() ?? '';
        final mrnTail = mrnStr.length > 6 ? mrnStr.substring(6) : mrnStr;

        final isCheckedIn = visit.checkedIn == 1;
        final canJoin =
            (visit.triageCompleted == 1 || visit.triageBypassed == 1) & isReady;
        final isToggling = _togglingReadyIds.contains(visit.id);
        final isJoining = _joiningVisitIds.contains(visit.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Patient & Avatar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  visit.picture != null
                      ? UserAvatar(
                          image: visit.picture!,
                          initials: initialsFor(visit.fullname!),
                          radius: 17,
                          initialsColor: Colors.white,
                        )
                      : CircleAvatar(
                          radius: 17,
                          backgroundColor: avatarColorFor(visit.fullname!),
                          child: Text(
                            initialsFor(visit.fullname!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.fullname ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${visit.dob != null ? _calculateAge(visit.dob!) : ''} yrs | ${visit.gender ?? ''} | ...$mrnTail',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey.withOpacity(0.5), height: 16),

              // Appointment details
              Text(
                locationText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  visit.checkedIn == 1
                      ? TeleMedIndicator(visits: visit)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            visit.status ?? 'Upcoming',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Mark as Ready — gated purely on patient check-in
                      _actionIconButton(
                        isToggling,
                        isReady
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: isCheckedIn
                            ? (isReady
                                  ? const Color.fromRGBO(76, 175, 80, 1)
                                  : const Color(0xFF2196F3))
                            : Colors.grey,
                        onTap: (isCheckedIn && !isToggling && visit.id != null)
                            ? () => _showConfirmReadyDialog(() async {
                                setState(
                                  () => _togglingReadyIds.add(visit.id!),
                                );
                                try {
                                  final provider = context
                                      .read<TeleMedicineProvider>();
                                  final success = await provider
                                      .toggleConsultantReady(visit);

                                  if (!mounted) return;
                                  if (!success &&
                                      provider.errorMessage != null) {
                                    showMessage(
                                      provider.errorMessage!,
                                      context,
                                      status: MessageStatus.error,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(
                                      () => _togglingReadyIds.remove(visit.id!),
                                    );
                                  }
                                }
                              })
                            : null,
                      ),
                      const SizedBox(width: 6),

                      // Join Call — gated purely on triage completion/bypass
                      _actionIconButton(
                        isJoining,
                        Icons.videocam_outlined,
                        color: canJoin
                            ? const Color.fromARGB(255, 250, 192, 1)
                            : Colors.grey,
                        onTap: (canJoin && !isJoining)
                            ? () => _showConfirmCallDialog(
                                () async => _joinTeleMedCall(visit),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmReadyDialog(VoidCallback? onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you're ready to start the telemedicine session?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Confirm your intention!",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend',
                ),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: BoxBorder.all(color: Colors.grey),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w200,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            //if (!slot.isLocked && canSchedule)
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                onConfirm?.call();
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 107, 20, 11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Mark as Ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'Lexend',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmCallDialog(VoidCallback? onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Join the telemedicine consultation?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Confirm your intention!",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend',
                ),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: BoxBorder.all(color: Colors.grey),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w200,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            //if (!slot.isLocked && canSchedule)
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                onConfirm?.call();
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 107, 20, 11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Enter Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'Lexend',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinTeleMedCall(QryBookingVisits visit) async {
    final authUser = context.read<UserProvider>().user; // read, not watch

    if (visit.id == null || authUser?.id == null) return;

    final visitId = visit.visitId!;
    if (_joiningVisitIds.contains(visitId)) {
      return; // already in flight — ignore re-tap
    }

    setState(() => _joiningVisitIds.add(visitId));
    final JoinTeleMedLink _joinTeleMedLink = JoinTeleMedLink(
      userId: authUser!.id,
      visitId: visitId,
    );

    try {
      final provider = context.read<TeleMedicineProvider>();
      final joinLink = await provider.joinTelemedicineRoom(_joinTeleMedLink);

      if (!context.mounted) return;

      if (joinLink != null) {
        showMessage(
          'Joining Meeting as Consultant',
          context,
          status: MessageStatus.success,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TelemedicineRoomScreen(joinLink: joinLink, visits: visit),
          ),
        );
        navBarVisible.value = false;
      } else if (provider.errorMessage != null) {
        showMessage(
          provider.errorMessage!,
          context,
          status: MessageStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _joiningVisitIds.remove(visitId));
    }
  }

  Widget _actionIconButton(
    bool isJoining,
    IconData icon, {
    Color color = Colors.grey,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isJoining
                ? Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).primaryColor
                : color.withOpacity(0.5),
          ),
        ),
        child: isJoining
            ? LoadingAnimationWidget.staggeredDotsWave(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
                size: 16,
              )
            : Icon(icon, color: color, size: 16),
      ),
    );
  }
}
