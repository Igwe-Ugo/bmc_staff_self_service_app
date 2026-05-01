import 'dart:async';
import 'package:go_router/go_router.dart';

import '../common/widget.dart';
import 'widget.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isVisible = false;
  bool _showText = false;
  bool _moveImage = false;

  @override
  void initState() {
    super.initState();

    // Fade in
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _isVisible = true);
    });

    // Move image first
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _moveImage = true);
    });

    // THEN show text slightly after movement starts
    Future.delayed(const Duration(milliseconds: 2300), () {
      setState(() => _showText = true);
    });

    // Navigate
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      GoRouter.of(context).go(BMCRouter.landingPagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        child: Stack(
          children: [
            /// 🔹 IMAGE (moves up)
            AnimatedAlign(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              alignment:
              _moveImage ? Alignment(0, -0.15) : Alignment.center,
              child: Image.asset(
                'assets/images/bmc_image.png',
                width: 80,
                height: 80,
              ),
            ),

            /// 🔹 TEXT (fades + slides in)
            Align(
              alignment: Alignment(0, 0),
              child: AnimatedOpacity(
                opacity: _showText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: AnimatedSlide(
                  offset: _showText
                      ? const Offset(0, 0)
                      : const Offset(0, 0.5),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  child: Text(
                    "Staff Self-Service",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
