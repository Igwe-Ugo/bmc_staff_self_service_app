// leave_summary.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/models/leave_model.dart';
import '../../../core/network/provider/leave_provider.dart';

class LeaveSummaryCard extends StatefulWidget {
  const LeaveSummaryCard({
    super.key,
  });

  @override
  State<LeaveSummaryCard> createState() => _LeaveSummaryCardState();
}

class _LeaveSummaryCardState extends State<LeaveSummaryCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start a timer to update the UI every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ───────────────── COLORS ─────────────────

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'COMPASSIONATE':
        return const Color(0xFF22C55E);
      case 'SICK':
        return const Color(0xFFF59E0B);
      case 'REST':
      case 'ANNUAL':
        return const Color(0xFFDC2626);
      case 'EMERGENCY':
        return const Color(0xFF16A34A);
      case 'STUDY':
        return const Color(0xFF6C47FF);
      case 'MATERNITY':
        return const Color(0xFFEC4899);
      case 'PATERNITY':
        return const Color(0xFF14B8A6);
      case 'BEREAVEMENT':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF6C47FF);
    }
  }

  // ───────────────── PROGRESS ─────────────────

  double _progress(HrLeaveRequest request) {
    if (request.status != HrLeaveRequestStatus.approved) {
      return 0;
    }

    final now = DateTime.now();
    final start = DateTime.parse(request.startDate);
    final end = DateTime.parse(request.endDate);

    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;

    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;

    if (total <= 0) return 1;

    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color _progressColor(double progress) {
    if (progress <= 1 / 3) {
      return const Color(0xFF22C55E); // Green
    }

    if (progress <= 2 / 3) {
      return const Color(0xFFF59E0B); // Yellow/Orange
    }

    return const Color(0xFFDC2626); // Red
  }

  // ───────────────── COUNTDOWN ─────────────────

  int _getRemainingDays(HrLeaveRequest request) {
    if (request.status != HrLeaveRequestStatus.approved) return 0;

    final now = DateTime.now();
    final end = DateTime.parse(request.endDate);

    if (now.isAfter(end)) return 0;

    final remaining = end.difference(now);
    return remaining.inDays + 1; // +1 to include the current day
  }

  String _getCountdownText(HrLeaveRequest request) {
    if (request.status != HrLeaveRequestStatus.approved) return '';

    final now = DateTime.now();
    final end = DateTime.parse(request.endDate);

    if (now.isAfter(end)) return 'Completed';

    final remaining = end.difference(now);

    if (remaining.inSeconds <= 0) return 'Completed';

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} left';
    } else if (hours > 0) {
      return '$hours hr${hours == 1 ? '' : 's'} left';
    } else if (minutes > 0) {
      return '$minutes min left';
    } else {
      return '< 1 min left';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveProvider>(
      builder: (context, provider, _) {
        // Filter out cancelled requests
        final filteredRequests = provider.myRequests
            .where((e) => e.status != HrLeaveRequestStatus.cancelled)
            .toList();

        if (filteredRequests.isEmpty) {
          return _emptyState(context);
        }

        // Count approved and pending for badges
        final approvedCount = filteredRequests
            .where((e) => e.status == HrLeaveRequestStatus.approved)
            .length;

        final pendingCount = filteredRequests
            .where((e) => e.status == HrLeaveRequestStatus.pending)
            .length;

        // Group by leave type for summary
        final Map<String, _LeaveSummary> summary = {};

        for (final request in filteredRequests) {
          final type = request.leaveType.toUpperCase();

          summary.putIfAbsent(
            type,
                () => _LeaveSummary(type: type),
          );

          final item = summary[type]!;

          item.total += request.totalDays;

          if (request.status == HrLeaveRequestStatus.approved) {
            item.used += request.totalDays;
            final remainingDays = _getRemainingDays(request);
            item.remainingDays += remainingDays;
            final progress = _progress(request);
            if (progress > item.highestProgress) {
              item.highestProgress = progress;
            }
            // Store the first approved request for countdown display
            item.approvedRequest ??= request;
          }

          if (request.status == HrLeaveRequestStatus.pending) {
            item.pending += request.totalDays;
          }
        }

        final items = summary.values.toList();
        final mainItem = items.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ──
              Row(
                children: [
                  const Text(
                    'My Leave',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Approved Badge
                  if (approvedCount > 0)
                    _badge(
                      '$approvedCount Approved',
                      const Color(0xFF22C55E),
                    ),

                  const SizedBox(width: 6),

                  // Pending Badge
                  if (pendingCount > 0)
                    _badge(
                      '$pendingCount Pending',
                      const Color(0xFFF59E0B),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Main Content ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Main Leave Type
                  Expanded(
                    child: _mainLeaveTile(mainItem),
                  ),

                  const SizedBox(width: 14),

                  // Right Column - Other Leave Types
                  Expanded(
                    child: Column(
                      children: items
                          .skip(1)
                          .take(3)
                          .map((item) => _smallLeaveTile(item))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── MAIN TILE ─────────────────

  Widget _mainLeaveTile(_LeaveSummary s) {
    final progress = s.highestProgress;
    final hasApproved = s.used > 0;
    final color = _typeColor(s.type);

    // Get the countdown display text
    String countdownText = '';
    if (s.approvedRequest != null) {
      countdownText = _getCountdownText(s.approvedRequest!);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatType(s.type),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Show remaining days / total days for approved leaves
          if (hasApproved && s.remainingDays > 0)
            Text(
              '${s.remainingDays}/${s.total}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              '${s.used}/${s.total}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

          const SizedBox(height: 4),

          // Countdown text
          if (hasApproved && countdownText.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: _progressColor(progress),
                ),
                const SizedBox(width: 4),
                Text(
                  countdownText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _progressColor(progress),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 10),

          if (hasApproved && progress > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  _progressColor(progress),
                ),
              ),
            )
          else if (hasApproved)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.15,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  const Color(0xFF22C55E),
                ),
              ),
            ),

          const SizedBox(height: 14),

          _statRow("Estimated", s.total),
          _statRow("Used", s.used),
          _statRow("Carried over", 0),
          _statRow("Pending", s.pending),
        ],
      ),
    );
  }

  // ───────────────── SMALL TILE ─────────────────

  Widget _smallLeaveTile(_LeaveSummary s) {
    final hasApproved = s.used > 0;
    final hasPending = s.pending > 0;
    final color = _typeColor(s.type);

    // Determine status for display
    String status = "Pending";
    Color statusColor = const Color(0xFFF59E0B);

    if (hasApproved) {
      // Check if there's an approved request with countdown
      if (s.approvedRequest != null) {
        final now = DateTime.now();
        final end = DateTime.parse(s.approvedRequest!.endDate);
        if (now.isAfter(end)) {
          status = "Completed";
          statusColor = const Color(0xFF22C55E);
        } else {
          status = "Approved";
          statusColor = const Color(0xFF22C55E);
        }
      } else {
        status = "Approved";
        statusColor = const Color(0xFF22C55E);
      }
    } else if (hasPending) {
      status = "Pending";
      statusColor = const Color(0xFFF59E0B);
    } else {
      status = "No requests";
      statusColor = Colors.grey;
    }

    final double progress = hasApproved ? s.highestProgress : 0;

    // Get countdown text for small tile
    String countdownText = '';
    if (s.approvedRequest != null) {
      countdownText = _getCountdownText(s.approvedRequest!);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatType(s.type),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Show remaining days / total days for approved leaves
              if (hasApproved && s.remainingDays > 0)
                Text(
                  '${s.remainingDays}/${s.total}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  '${s.used}/${s.total}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          // Countdown text for small tile
          if (hasApproved && countdownText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 10,
                  color: _progressColor(progress),
                ),
                const SizedBox(width: 4),
                Text(
                  countdownText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _progressColor(progress),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          if (hasApproved)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : 0.15,
                minHeight: 4,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  progress > 0 ? _progressColor(progress) : const Color(0xFF22C55E),
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ───────────────── HELPERS ─────────────────

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() +
        type.substring(1).toLowerCase();
  }

  // ───────────────── EMPTY STATE ─────────────────

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            "No leave request yet!",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Summary of all leave requests is displayed here",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── INTERNAL SUMMARY CLASS ─────────────────

class _LeaveSummary {
  final String type;

  int total = 0;
  int used = 0;
  int pending = 0;
  int remainingDays = 0;
  double highestProgress = 0;
  HrLeaveRequest? approvedRequest;

  _LeaveSummary({
    required this.type,
  });
}
