import 'package:bmc_app/core/network/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../common/widget.dart';

class Stats extends StatelessWidget {
  const Stats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              onPressed: () => GoRouter.of(context).pop(),
              icon: const Icon(Iconsax.arrow_left, size: 20),
            ),
            title: const Text(
              'Profile',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lexend'
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Portfolio'),
                        const SizedBox(height: 8),
                        _buildPortfolioCard(context, userProvider),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Availability'),
                        const SizedBox(height: 8),
                        _buildDonutCard(context,
                          percent: 0.75,
                          centerLabel: '75%',
                          color: const Color(0xFF6C47FF),
                          stats: const [
                            _StatItem('Available', 31, Color(0xFF6C47FF)),
                            _StatItem('Unavailable', 24, Color(0xFFFF6B6B)),
                            _StatItem('Preferred', 20, Color(0xFFFFD93D)),
                            _StatItem('Total', 270, Color(0xFF6C47FF)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Leave'),
                        const SizedBox(height: 8),
                        _buildDonutCard(context,
                          percent: 0.55,
                          centerLabel: '55%',
                          color: const Color(0xFF9B87F5),
                          stats: const [
                            _StatItem('Compassionate', 21, Color(0xFF6C47FF)),
                            _StatItem('Sick', 24, Color(0xFFFF6B6B)),
                            _StatItem('Rest', 20, Color(0xFFFFD93D)),
                            _StatItem('Total', 130, Color(0xFF6C47FF)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionLabel('Rota'),
                        const SizedBox(height: 8),
                        _buildDonutCard(context,
                          percent: 0.80,
                          centerLabel: '80%',
                          color: const Color(0xFF6C47FF),
                          stats: const [
                            _StatItem('Day', 30, Color(0xFF6C47FF)),
                            _StatItem('Night', 24, Color(0xFFFF6B6B)),
                            _StatItem('On Call', 20, Color(0xFFFFD93D)),
                            _StatItem('Off', 14, Color(0xFFFF6B6B)),
                            _StatItem('Total', 160, Color(0xFF6C47FF)),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _buildButton(
                          label: 'Update Profile',
                          filled: true,
                          onTap: () => GoRouter.of(context).go("${BMCRouter.homePath}/${BMCRouter.statsPath}/${BMCRouter.profilePath}"),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Portfolio card (with avatar) ───────────────────────────────────────────

  Widget _buildPortfolioCard(BuildContext context, UserProvider userProvider) {
    return _cardShell(context,
      child: Row(
        children: [
          // Avatar with decorative ring
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Theme.of(context).primaryColor,
              child: UserAvatar(
                image:    userProvider.avatar,
                initials: userProvider.initials,
                radius:   40,
              )
            ),
          ),
          const SizedBox(width: 16),
          // Stats grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.displayName,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: userProvider.user!.privileges.map((p) {
                    return Text(
                      p.split('~')[1],
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        decoration: TextDecoration.underline,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Donut card ─────────────────────────────────────────────────────────────

  Widget _buildDonutCard(BuildContext context, {
    required double percent,
    required String centerLabel,
    required Color color,
    required List<_StatItem> stats,
  }) {
    // Split stats into rows of 2
    final rows = <List<_StatItem>>[];
    for (var i = 0; i < stats.length; i += 2) {
      rows.add(stats.sublist(i, math.min(i + 2, stats.length)));
    }

    return _cardShell(context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Donut chart
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _DonutPainter(
                    percent: percent,
                    activeColor: color,
                    trackColor: const Color(0xFFE5E5EA),
                  ),
                ),
                Text(
                  centerLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Stat badges grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: row.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildBadge(item.label, item.value, item.color),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat badge ─────────────────────────────────────────────────────────────

  Widget _buildBadge(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF3C3C43),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ── Card shell ─────────────────────────────────────────────────────────────

  Widget _cardShell(context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────────

  Widget _buildButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF6C47FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: filled
              ? null
              : Border.all(color: const Color(0xFF6C47FF), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : const Color(0xFF6C47FF),
          ),
        ),
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final int value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}

// ── Donut Painter ──────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double percent;
  final Color activeColor;
  final Color trackColor;

  const _DonutPainter({
    required this.percent,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 8;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect =
    Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track (full circle)
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    // Active arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.percent != percent || old.activeColor != activeColor;
}
