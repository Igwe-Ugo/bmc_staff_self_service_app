import 'package:flutter/material.dart';

import '../../core/network/models/widget.dart';

class TeleMedIndicator extends StatelessWidget {
  final QryBookingVisits visits;
  const TeleMedIndicator({super.key, required this.visits});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildIndicatorIcon(
          icon: Icons.pending_actions_outlined,
          activeColor: visits.triageCompleted == 1
              ? visits.triageBypassed == 1
                    ? Theme.of(context).primaryColor
                    : Colors.green
              : Colors.redAccent,
        ),
        const SizedBox(width: 8),
        _buildIndicatorIcon(
          icon: Icons.pending_outlined,
          activeColor: visits.checkedIn == 1
              ? visits.patientReady == 1
                    ? Colors.green
                    : Colors.orange
              : Colors.grey,
        ),
        const SizedBox(width: 8),
        _buildIndicatorIcon(
          icon: Icons.house_outlined,
          activeColor: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildIndicatorIcon(
          icon: Icons.video_call_outlined,
          activeColor: visits.callStarted == 1
              ? visits.callEnded == 1
                    ? Colors.green
                    : Colors.grey
              : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildIndicatorIcon({
    required IconData icon,
    required Color activeColor,
  }) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
      child: Icon(icon, size: 13, color: Colors.white),
    );
  }
}
