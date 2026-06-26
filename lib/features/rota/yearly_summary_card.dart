import 'package:flutter/material.dart';
import '../../core/network/models/widget.dart';

class YearlySummaryCard extends StatelessWidget {
  final Map<ShiftType, int> counts;

  const YearlySummaryCard({
    super.key,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36, // Matches the explicit height of the filter row
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ShiftType.values.map((type) {
          final count = counts[type] ?? 0;

          // Appends the count inline directly inside the label parentheses
          final label = '${type.label} ($count)';
          final color = type.color;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), // Matching the unselected colored overlay tint
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
