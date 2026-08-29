import 'package:bmc_app/core/network/provider/telemed_provider.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../chatting/widget.dart';
import '../common/widget.dart';
import 'widget.dart';

class TeleMedGuestHomeVisits extends StatefulWidget {
  final TeleMedicineProvider teleMedicineProvider;
  const TeleMedGuestHomeVisits({super.key, required this.teleMedicineProvider});

  @override
  State<TeleMedGuestHomeVisits> createState() => _TeleMedGuestHomeVisitsState();
}

class _TeleMedGuestHomeVisitsState extends State<TeleMedGuestHomeVisits> {
  final Set<String> _joiningGuestVisitIds = {};

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
  Widget build(BuildContext context) {
    return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TeleMedicine Clinic Invites',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.teleMedicineProvider.guestVisits.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                  ),
                  child: Text(
                    widget.teleMedicineProvider.guestVisits.length.toString(),
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          Expanded(
            child: _buildVisitsList(
              widget.teleMedicineProvider.todayVisits,
              Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );
  }

  _buildVisitsList(List<QryBookingVisits> visits, Color cardBg) {
    return ListView.builder(
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        final slot = visit.slotName?.trim() ?? '';
        final location = visit.location?.trim() ?? '';
        final locationText = (location.isEmpty || slot.contains(location))
            ? slot.split('|')[2]
            : '$slot | $location';
        final mrnStr = visit.medrecnum?.toString() ?? '';
        final mrnTail = mrnStr.length > 6 ? mrnStr.substring(6) : mrnStr;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            // Appointment details
                            Text(
                              locationText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
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
                      ElevatedButton.icon(
                        onPressed: () => _joinTeleMedGuestCall(visit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(Iconsax.call_outgoing),
                        label: Text(
                          'Join',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
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

  Future<void> _joinTeleMedGuestCall(QryBookingVisits visit) async {
    final visitId = visit.visitId!;
    if (_joiningGuestVisitIds.contains(visitId)) {
      return; // already in flight — ignore re-tap
    }

    setState(() => _joiningGuestVisitIds.add(visitId));

    try {
      final provider = context.read<TeleMedicineProvider>();
      final joinLink = await provider.joinTeleMedGuestRoom(visitId);

      if (!context.mounted) return;

      if (joinLink != null) {
        showMessage(
          'Joining Meeting as Guest',
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
      } else if (provider.errorMessage != null) {
        showMessage(
          provider.errorMessage!,
          context,
          status: MessageStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _joiningGuestVisitIds.remove(visitId));
    }
  }
}
