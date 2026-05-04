// lib/features/common/nav_visibility.dart
import 'package:flutter/material.dart';

/// Single source of truth for bottom nav visibility.
/// Import this wherever you need to show/hide the nav bar.
final ValueNotifier<bool> navBarVisible = ValueNotifier(true);
