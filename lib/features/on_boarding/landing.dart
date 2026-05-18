import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../authentication/widget.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentPage = 0;
  late final List<MapEntry<String, String>> entries = staffServiceFeatures.entries.toList();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: staffServiceFeatures.length,
      vsync: this,
    );

    _tabController.addListener(() {
      setState(() {
        _currentPage = _tabController.index;
      });
    });
  }

  final Map<String, String> staffServiceFeatures = {
    "Set Your Availability":
    "Mark the days you’re available or unavailable in seconds. Stay in control of your schedule before the submission window closes.",
    "View Your Shifts Instantly":
    "Check your weekly schedule at a glance. See shift times, locations, and request swaps when needed.",
    "Request Leave with Clarity":
    "Submit leave requests with required details. Track approvals and avoid scheduling conflicts.",
    "Your Profile & Documents":
    "Access your personal details, upload documents, and keep everything verified and up to date in one place.",
  };

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = staffServiceFeatures.entries.toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
          child: Column(
            children: [
              /// 🔹 HEADER IMAGE + TITLE
              Column(
                children: [
                  Image.asset(
                    'assets/images/bmc_image.png',
                    width: 80,
                    height: 80,
                  ),
                  Text(
                    "Welcome!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// 🔹 ILLUSTRATION
              Image.asset(
                'assets/images/on_boarding_image.png',
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 50),

              Expanded(
                child: DefaultTabController(
                  length: entries.length,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        /// 🔹 SWIPE CONTENT
                        _landingInfo(),
                        const SizedBox(height: 30),

                        /// 🔹 STATIC BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Get Started",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Featured books carousel ─────────────────────────────────────────────

  Widget _landingInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carousel ────────────────────────────────────────────────────
          CarouselSlider.builder(
            itemCount: entries.length,
            options: CarouselOptions(
              height: 135,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 10),
              viewportFraction: 1,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                // 3. Update _currentPage whenever the slide changes
                setState(() => _currentPage = index);
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final entry = entries[index]; // one entry per slide
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: "Montserrat",
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Lexend',
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ── Dot indicator ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(entries.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white54,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
