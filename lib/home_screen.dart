import 'package:alliance_one/notification.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: const [
                  // Page 1 – Alliance One
                  WebViewScreen(
                    url: 'https://one.alliance.edu.in',
                    title: 'Alliance One',
                  ),

                  // Page 2 – Notifications
                  NotificationsPage(),

                  // Page 3 – Results
                  WebViewScreen(
                    url: 'https://results.pmk.codes',
                    title: 'Results',
                  ),
                ],
              ),
            ),

            // 🔹 Dots Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: const Color(0xFF6C63FF),
                  dotColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
