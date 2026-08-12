import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';

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
    final darkBg = const Color(0xFF1E1E2C);
    final cardBg = const Color(0xFF27273A);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        title: const Text(
          'Appointments',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Consumer<TeleMedicineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text(
                provider.errorMessage!,
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
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    onChanged: provider.updateSearchQuery,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Filter by patient name, MRN, slot, or location...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Colors.grey, size: 18),
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
                  color: const Color(0xFF14141F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 14),
                          const SizedBox(width: 6),
                          Text('Today (${provider.todayVisits.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month, size: 14),
                          const SizedBox(width: 6),
                          Text('Upcoming (${provider.upcomingVisits.length})'),
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
                    _buildVisitsList(provider.todayVisits, cardBg),
                    _buildVisitsList(provider.upcomingVisits, cardBg),
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
      return const Center(
        child: Text(
          'No records found.',
          style: TextStyle(color: Colors.grey),
        ),
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
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Patient & Avatar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white10,
                    backgroundImage: visit.picture != null
                        ? NetworkImage(visit.picture!)
                        : null,
                    child: visit.picture == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.fullname ?? 'Unknown Patient',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${visit.gender ?? ''} | ..${visit.medrecnum ?? ''}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const Divider(color: Colors.white12, height: 16),

              // Appointment details
              Text(
                '${visit.specialistClinicType ?? 'Telemed Clinic'} - ${visit.slotName ?? ''} | ${visit.location ?? ''} | $startDate - $endDate',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${visit.type ?? 'Telemedicine'} | ${visit.bookedByName ?? ''} | $bookedDateStr',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
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
          color: const Color(0xFF14141F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.grey, size: 16),
      ),
    );
  }
}
