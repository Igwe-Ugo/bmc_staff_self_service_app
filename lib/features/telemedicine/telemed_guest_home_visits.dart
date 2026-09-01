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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      height: 300,
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              if (widget.teleMedicineProvider.guestTodayVisits.isNotEmpty)
                CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.3),
                  radius: 15,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.teleMedicineProvider.guestTodayVisits.length
                          .toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildVisitsList(
              widget.teleMedicineProvider.guestTodayVisits,
              Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
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
                "Go into the clinic for consultation?",
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
                  'Join Now',
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

  Widget _buildVisitsList(List<QryBookingVisits> visits, Color cardBg) {
    return ListView.builder(
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        final slot = visit.slotName?.trim() ?? '';
        final location = visit.location?.trim() ?? '';
        final locationText = (location.isEmpty || slot.contains(location))
            ? (slot.split('|').length > 2 ? slot.split('|')[2] : slot)
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
          child: Row(
            // Single top-level Row for horizontal layout
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Avatar
              visit.picture != null
                  ? UserAvatar(
                      image: visit.picture!,
                      initials: initialsFor(visit.fullname!),
                      radius: 15,
                      initialsColor: Colors.white,
                    )
                  : CircleAvatar(
                      radius: 15,
                      backgroundColor: avatarColorFor(visit.fullname!),
                      child: Text(
                        initialsFor(visit.fullname!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 10),

              // 2. Middle details column (takes remaining available width)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.fullname ?? 'Unknown Patient',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visit.dob != null ? _calculateAge(visit.dob!) : ''} yrs | ${visit.gender ?? ''} | ...$mrnTail',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Action Button
              ElevatedButton.icon(
                onPressed: () => _showConfirmCallDialog(
                  () async => _joinTeleMedGuestCall(visit),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Iconsax.call_outgoing,
                  size: 12,
                  color: Colors.white,
                ),
                label: const Text(
                  'Join',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
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
