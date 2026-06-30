import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';
import '../common/widget.dart';

class ShiftEventTile extends StatelessWidget {
  final RotaEvent event;
  final UserProvider userProvider;
  final Color cardBg;

  const ShiftEventTile({
    super.key,
    required this.event,
    required this.cardBg,
    required this.userProvider,
  });

  // Helper method to convert 24-hour time strings or time ranges to a clean 12-hour AM/PM format
  String _convertTo12Hour(String timeStr) {
    if (timeStr.isEmpty) return '';

    if (timeStr.contains('-')) {
      final parts = timeStr.split('-');
      if (parts.length == 2) {
        return '${_formatSingleTime(parts[0].trim())} - ${_formatSingleTime(parts[1].trim())}';
      }
    }

    return _formatSingleTime(timeStr);
  }

  String _formatSingleTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final tempDate = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('h:mm a').format(tempDate).toLowerCase();
      }
    } catch (_) {}
    return time;
  }

  // Popup layout showing full information about the shift event
  void _showShiftDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                _buildDetailRow(Iconsax.user, 'Staff Name', userProvider.displayName),
                _buildDetailRow(Iconsax.hospital, 'Role / Designation', event.role),
                _buildDetailRow(Iconsax.location, 'Ward / Department', event.ward),
                _buildDetailRow(
                  Iconsax.calendar_1,
                  'Scheduled Date',
                  DateFormat('EEEE, MMMM dd, yyyy').format(event.date),
                ),
                _buildDetailRow(
                  Iconsax.clock,
                  'Shift Type',
                  event.type.label,
                  badgeColor: event.type.color.withOpacity(0.1),
                  textColor: event.type.color,
                ),
                _buildDetailRow(
                  Iconsax.timer_1,
                  'Shift Hours',
                  event.endTime.isNotEmpty ? "${_convertTo12Hour(event.startTime)} - ${_convertTo12Hour(event.endTime)}" : " ${_convertTo12Hour(event.startTime)}",
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? badgeColor, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                badgeColor != null
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                )
                    : Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showShiftDetailDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 40),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: event.type.color),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Date Indicator Badge Block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEE').format(event.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    DateFormat('dd').format(event.date),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Avatar Placeholder
            CircleAvatar(
              radius: 18,
              backgroundColor: event.type.color,
              child: UserAvatar(
                image: userProvider.avatar,
                initials: userProvider.initials,
                radius: 16,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProvider.displayName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Iconsax.hospital, size: 12),
                      const SizedBox(width: 4),
                      Text(event.ward, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 8),
                      const Icon(Iconsax.location, size: 12),
                      const SizedBox(width: 2),
                      Text(event.role, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.type.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: event.type.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.endTime.isNotEmpty ? "${_convertTo12Hour(event.startTime)} - ${_convertTo12Hour(event.endTime)}" : " ${_convertTo12Hour(event.startTime)}",
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}