import 'package:alliance_one/notification.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'webview_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _lastPageBeforeResults = 0;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _createNotificationChannel();
    _setupFCM();
    FirebaseMessaging.instance.subscribeToTopic('all');
    _listenForUnreadNotifications();
  }

  void _listenForUnreadNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastViewed = prefs.getInt('last_viewed_notifications') ?? 0;
        
        // Check if any notification is newer than last viewed
        bool hasNew = false;
        for (var doc in snapshot.docs) {
          final Timestamp? ts = doc['time'];
          if (ts != null && ts.millisecondsSinceEpoch > lastViewed) {
             hasNew = true;
             break;
          }
        }

        if (mounted) {
          setState(() {
            _hasUnreadNotifications = hasNew;
          });
        }
      }
    });
  }

  // 🔔 Setup FCM and save notifications to Firestore
  void _setupFCM() {
    FirebaseMessaging.instance.requestPermission();

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        // Save to Firestore handled by cloud function or admin app usually, 
        // but keeping existing logic if Admin App doesn't double-write?
        // Actually Admin App writes to Firestore. 
        // We shouldn't duplicate write here if the sender (Admin) already writes.
        // Assuming Admin writes to Firestore, we just listen. 
        // BUT current code wrote to Firestore on receipt. 
        // If Admin writes to Firestore AND sends FCM, and we write to Firestore on FCM...
        // We get duplicates. 
        // Since Admin App writes to Firestore, we should REMOVE writing here.
        // However, user said "make this work correctly".
        // I will COMMENT OUT the write here to prevent duplicates if Admin writes.
        // Wait, Admin App DOES write to Firestore.
        // So Main App should NOT write on receipt.
        
        // Just show local notification or let system handle it.
      }
    });

    // Background & Terminated handled by system tray usually.
  }


  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // MUST MATCH FCM
      'Alliance One Notifications',
      description: 'Notifications for Alliance One',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }


  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('❌ Notification permission denied');
    } else {
      debugPrint('✅ Notification permission granted');
    }
  }

  void _goToPage(int page) {
    if (_currentPage == page) return;

    // Track where we came from if going to Results (Page 2)
    if (page == 2) {
      _lastPageBeforeResults = _currentPage;
    }

    // If skipping a page (e.g., 0 -> 2 or 2 -> 0), jump instantly to avoid showing the middle page
    if ((_currentPage - page).abs() > 1) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _openNotifications() async {
    // Save current time as last viewed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_viewed_notifications', DateTime.now().millisecondsSinceEpoch);
    
    setState(() {
      _hasUnreadNotifications = false;
    });

    _goToPage(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
              // ⬅️➡️ TOP BAR WITH 🔔
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. CENTER TITLE
                    Text(
                      _currentPage == 0
                          ? 'Alliance One'
                          : _currentPage == 1
                              ? 'Notifications'
                              : 'Results',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // 2. LEFT ACTION (Back)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _currentPage > 0
                          ? IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: () {
                                if (_currentPage == 2) {
                                  _goToPage(_lastPageBeforeResults);
                                } else {
                                  _goToPage(0);
                                }
                              },
                            )
                          : const SizedBox.shrink(),
                    ),

                    // 3. RIGHT ACTIONS (Bell + Chevron/Trophy)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentPage == 0)
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                                  onPressed: _openNotifications,
                                ),
                                if (_hasUnreadNotifications)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 10,
                                        minHeight: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          
                          if (_currentPage == 0)
                            IconButton(
                              icon: const Icon(Icons.emoji_events, color: Colors.white),
                              onPressed: () => _goToPage(2), // Skips to Results
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  WebViewScreen(
                    url: 'https://one.alliance.edu.in',
                  ),
                  NotificationsPage(
                    onResultClick: () => _goToPage(2), // Redirect to Results
                  ),
                  const ResultsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
