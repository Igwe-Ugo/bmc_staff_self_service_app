import 'dart:ui';

class ChatUser {
  final String name;
  final String subtitle;
  final bool isYou;
  final bool hasNotification;
  final Color avatarColor;
  final String initials;

  const ChatUser({
    required this.name,
    required this.subtitle,
    this.isYou = false,
    this.hasNotification = false,
    required this.avatarColor,
    required this.initials,
  });
}
