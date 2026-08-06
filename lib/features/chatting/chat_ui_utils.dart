// chat_ui_utils.dart
//
// The old ChatUser mock model carried a fixed `avatarColor` / `initials` per
// person. SocketUser (from socket_models.dart) has neither — it's a pure data
// model seeded from the server roster. These helpers derive both
// deterministically from real user data so every screen renders the same
// avatar for the same person without storing UI state on the model.

import 'package:flutter/material.dart';

const List<Color> _avatarPalette = [
  Color(0xFF8D6E63),
  Color(0xFF5C6BC0),
  Color(0xFF66BB6A),
  Color(0xFFAB47BC),
  Color(0xFFEF5350),
  Color(0xFF26A69A),
  Color(0xFFFFA726),
  Color(0xFF42A5F5),
];

/// Deterministic color for a given seed (username or groupId) — same person
/// always gets the same color, with no server-side field required.
Color avatarColorFor(String seed) {
  if (seed.isEmpty) return _avatarPalette.first;
  final hash = seed.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return _avatarPalette[hash % _avatarPalette.length];
}

/// Up to two initials from a display name. Falls back gracefully for empty
/// or single-word names (usernames, group names, etc.).
String initialsFor(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "12:04 PM" — written by hand so this file has no dependency on `intl`.
/// Swap this for DateFormat('h:mm a').format(time) if the project already
/// depends on intl elsewhere.
String formatMessageTime(DateTime time) {
  final local = time.toLocal();
  final hour24 = local.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

/// "May 10, 2026" — used for date-divider rows between messages.
String formatDateDivider(DateTime time) {
  final local = time.toLocal();
  return '${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
}

bool isSameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}
