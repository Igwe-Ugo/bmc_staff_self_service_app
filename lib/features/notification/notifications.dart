import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 18),
        ),
        title: const Text(
          'BMC Notifications',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: _buildNotificationList(Theme.of(context).cardColor),
        ),
      ),
    );
  }

  Widget _buildNotificationList(Color cardColor) {
    final List<Map<String, dynamic>> notes = [
      {
        'title': 'Availability window open closes 30/05/2026 at 23:59',
        'subtitle': '2 Days left',
        'badge': 'Admin',
        'color': const Color(0xFF6C47FF),
        'time': '12:50pm',
      },
      {
        'title': 'Ugoo wants is giving you his shift',
        'subtitle': 'Swap Request',
        'badge': 'Ugoo',
        'color': Colors.green,
        'time': '12:50pm',
      },
      {
        'title': 'Leave Request',
        'subtitle': 'Approved',
        'badge': 'Admin',
        'color': const Color(0xFF6C47FF),
        'time': '12:50pm',
      },
      {
        'title': 'Swap shift with Ugochukwu Igwe',
        'subtitle': 'Accepted',
        'badge': 'Igwe',
        'color': Colors.amber,
        'time': '12:50pm',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _listTileCard(notes[index], cardColor),
    );
  }

  Widget _listTileCard(Map<String, dynamic> item, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: item['color'], width: 4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: (item['color'] as Color).withOpacity(0.2),
            child: Icon(Icons.person, size: 16, color: item['color']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(item['subtitle'], style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['badge'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item['color'],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(item['time'], style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
