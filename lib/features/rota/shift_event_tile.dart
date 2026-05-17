import 'package:flutter/material.dart';
import '../../core/network/models/widget.dart';

class ShiftEventTile extends StatelessWidget {
  final RotaEvent event;
  const ShiftEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar placeholder
          CircleAvatar(
            radius: 22,
            backgroundColor: event.type.bgColor,
            child: Text(
              event.staffName.substring(0, 1),
              style: TextStyle(color: event.type.color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.staffName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 12, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Text(event.role,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 2),
                    Text(event.ward,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Shift badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: event.type.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.type.label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: event.type.color),
                ),
              ),
              const SizedBox(height: 4),
              if (event.endTime.isNotEmpty)
                Text(event.timeRange,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)))
              else
                Text(event.startTime,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          ),
        ],
      ),
    );
  }
}
