import 'package:alliance_one/notification.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
      _requestNotificationPermission();
        _createNotificationChannel();


    _setupFCM();
  }

  // 🔔 Setup FCM and save notifications to Firestore
  void _setupFCM() {
  FirebaseMessaging.instance.requestPermission();

  // Foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.notification != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification!.title ?? 'No title',
        'body': message.notification!.body ?? '',
        'time': FieldValue.serverTimestamp(),
      });
    }
  });

  // Background (app opened from tray)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    if (message.notification != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification!.title ?? 'No title',
        'body': message.notification!.body ?? '',
        'time': FieldValue.serverTimestamp(),
      });
    }
  });

  // ❗ Terminated state (THIS WAS MISSING)
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async {
    if (message != null && message.notification != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification!.title ?? 'No title',
        'body': message.notification!.body ?? '',
        'time': FieldValue.serverTimestamp(),
      });
    }
  });
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
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = page;
    });
  }

  void _openNotifications() => _goToPage(1);

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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _currentPage > 0
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                  ),

                  Expanded(
                    child: Text(
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
                  ),

                  if (_currentPage == 0)
                    IconButton(
                      icon: const Icon(Icons.notifications_none,
                          color: Colors.white),
                      onPressed: _openNotifications,
                    )
                  else
                    const SizedBox(width: 48),

                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _currentPage < 2
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  WebViewScreen(
                    url: 'https://one.alliance.edu.in',
                  ),
                  NotificationsPage(),
                  WebViewScreen(
                    url: 'https://results.pmk.codes',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
