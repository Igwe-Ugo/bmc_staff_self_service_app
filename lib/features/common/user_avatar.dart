import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? image;
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final Color? initialsColor;

  const UserAvatar({
    super.key,
    required this.image,
    required this.initials,
    this.radius = 24,
    this.backgroundColor,
    this.initialsColor,
  });

  /// Returns true if the string is a base64-encoded image.
  /// Base64 images either start with a data URI prefix or are
  /// a raw base64 string (no "http" and no file path).
  static bool _isBase64(String value) {
    return value.startsWith('data:image') ||
        (!value.startsWith('http') &&
            !value.startsWith('/') &&
            !value.startsWith('assets'));
  }

  /// Strips the data URI prefix if present:
  /// "data:image/png;base64,ABC123" → "ABC123"
  static String _extractBase64(String value) {
    if (value.contains(',')) {
      return value.split(',').last;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.05);
    final fgColor = initialsColor ?? Theme.of(context).primaryColor;

    // ── No image: show initials ──────────────────────────────────────────────
    if (image == null || image!.isEmpty) {
      return _initialsAvatar(bgColor, fgColor);
    }

    // ── Base64 image ─────────────────────────────────────────────────────────
    if (_isBase64(image!)) {
      return _base64Avatar(image!, bgColor, fgColor);
    }

    // ── Network URL: use CachedNetworkImage ──────────────────────────────────
    return CachedNetworkImage(
      imageUrl: image!,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) => _loadingAvatar(bgColor),
      errorWidget: (context, url, error) => _initialsAvatar(bgColor, fgColor),
    );
  }

  // ── Builders ─────────────────────────────────────────────────────────────────

  Widget _base64Avatar(String raw, Color bgColor, Color fgColor) {
    try {
      final bytes = base64Decode(_extractBase64(raw));
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
        backgroundColor: bgColor,
      );
    } catch (_) {
      // Decoding failed — fall back to initials
      return _initialsAvatar(bgColor, fgColor);
    }
  }

  Widget _initialsAvatar(Color bgColor, Color fgColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
      ),
    );
  }

  Widget _loadingAvatar(Color bgColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: SizedBox(
        width: radius,
        height: radius,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
