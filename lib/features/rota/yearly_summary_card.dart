import 'package:flutter/material.dart';
import '../../core/network/models/widget.dart';

class YearlySummaryCard extends StatelessWidget {
  final Map<ShiftType, int> counts;
  const YearlySummaryCard({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: ShiftType.values.map((type) {
          final count = counts[type] ?? 0;
          return _SummaryChip(type: type, count: count);
        }).toList(),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final ShiftType type;
  final int       count;
  const _SummaryChip({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: type.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: type.color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: type.color)),
          ),
        ],
      ),
    );
  }
}
