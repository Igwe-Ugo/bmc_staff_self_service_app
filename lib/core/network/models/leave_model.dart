import 'dart:ui';

enum LeaveType {
  compassionate('Compassionate Leave', Color(0xFF6C47FF)),
  sick('Sick Leave', Color(0xFFFF6B6B)),
  emergency('Emergency Leave', Color(0xFFF39C12)),
  rest('Rest Leave', Color(0xFF27AE60));

  final String label;
  final Color color;
  const LeaveType(this.label, this.color);
}

class LeaveEvent {
  final String title;
  final LeaveType type;
  final DateTime from;
  final DateTime to;
  final String description;

  const LeaveEvent({
    required this.title,
    required this.type,
    required this.from,
    required this.to,
    required this.description,
  });

  List<DateTime> get days {
    final list = <DateTime>[];
    var d = from;
    while (!d.isAfter(to)) {
      list.add(DateTime(d.year, d.month, d.day));
      d = d.add(const Duration(days: 1));
    }
    return list;
  }
}

class LeaveBalance {
  final LeaveType type;
  final int total;
  final int used;
  final int carriedOver;
  final int pending;

  const LeaveBalance({
    required this.type,
    required this.total,
    required this.used,
    this.carriedOver = 0,
    this.pending = 0,
  });

  int get estimated => total - used;
  double get progress => total == 0 ? 0 : used / total;

  Color get progressColor {
    if (progress <= 1 / 3) return const Color(0xFF27AE60);
    if (progress <= 2 / 3) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }
}
