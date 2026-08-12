import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../chatting/widget.dart';
import '../common/widget.dart';

class BookingVisitsScreen extends StatefulWidget {
  const BookingVisitsScreen({super.key});

  @override
  State<BookingVisitsScreen> createState() => _BookingVisitsScreenState();
}

class _BookingVisitsScreenState extends State<BookingVisitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeleMedicineProvider>().loadVisits();
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
          'TeleMedicine',
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
            print(teleMedProvider.errorMessage!);
            return Center(
              child: Text(
                teleMedProvider.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          return Column(
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

              // Tab Bar (Today and Upcoming only)
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
                          Text('Today (${teleMedProvider.todayVisits.length})'),
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
          );
        },
      ),
    );
  }

  Widget _buildVisitsList(List<QryBookingVisits> visits, Color cardBg) {
    if (visits.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.user_search, size: 40),
          const SizedBox(height: 15),
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
        final startDate = visit.appmtStartDate != null
            ? DateFormat('EEE MMM d, yyyy: HH:mm').format(visit.appmtStartDate!)
            : '';
        final endDate = visit.appmtEndDate != null
            ? DateFormat('HH:mm').format(visit.appmtEndDate!)
            : '';
        final bookedDateStr = visit.bookedDate != null
            ? DateFormat('dd-MMM-yyyy hh:mm a').format(visit.bookedDate!)
            : '';

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
                          radius: 13,
                          initialsColor: Colors.white,
                        )
                      : CircleAvatar(
                          radius: 13,
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
                          '${visit.gender ?? ''} | ..${visit.medrecnum ?? ''}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
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
                ],
              ),
              Divider(color: Colors.grey.withOpacity(0.5), height: 16),

              // Appointment details
              Text(
                '${visit.specialistClinicType ?? 'Telemed Clinic'} - ${visit.slotName ?? ''} | ${visit.location ?? ''} | $startDate - $endDate',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${visit.type ?? 'Telemedicine'} | ${visit.bookedByName ?? ''} | $bookedDateStr',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 10),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionIconButton(Icons.check_circle_outline, () {}),
                  const SizedBox(width: 6),
                  _actionIconButton(Icons.description_outlined, () {}),
                  const SizedBox(width: 6),
                  _actionIconButton(Icons.movie_outlined, () {}),
                  const SizedBox(width: 6),
                  _actionIconButton(Icons.videocam_outlined, () {}),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        child: Icon(icon, color: Colors.grey, size: 16),
      ),
    );
  }
}
