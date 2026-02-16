import 'dart:ui';
import 'package:alliance_one/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'webview_screen.dart';
import 'results_screen.dart';
import 'find_venue_screen.dart';
import 'alliance_bot_screen.dart';
import '../theme/theme.dart';
import 'settings_screen.dart';
import 'legal_documents_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
//it is the main screen of the app which contains the webview, notifications and results pages. It also handles the navigation between these pages and the chatbot floating action button. It also handles the notification permissions and FCM setup.
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _lastPageBeforeResults = 0;
  bool _hasUnreadNotifications = false;
  late AnimationController _bellAnimController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();
    _setupBellAnimation();
    _requestNotificationPermission();
    _createNotificationChannel();
    _setupFCM();
    FirebaseMessaging.instance.subscribeToTopic('all');
    _listenForUnreadNotifications();
  }

  void _setupBellAnimation() {
    _bellAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bellAnimation = Tween<double>(begin: 0, end: 0.15).animate(
      CurvedAnimation(parent: _bellAnimController, curve: Curves.elasticIn),
    );
  }

  void _listenForUnreadNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastViewed = prefs.getInt('last_viewed_notifications') ?? 0;
        
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
          if (hasNew) {
            _bellAnimController.repeat(reverse: true);
          } else {
            _bellAnimController.stop();
            _bellAnimController.reset();
          }
        }
      }
    });
  }

  void _setupFCM() {
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Notification received - handled by system
    });
  }

  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
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

    if (page == 2) {
      _lastPageBeforeResults = _currentPage;
    }

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_viewed_notifications', DateTime.now().millisecondsSinceEpoch);
    
    setState(() {
      _hasUnreadNotifications = false;
    });
    _bellAnimController.stop();
    _bellAnimController.reset();

    _goToPage(1);
  }

  void _openChatBot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllianceBotScreen(
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bellAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentPage == 2) {
          _goToPage(_lastPageBeforeResults);
        } else if (_currentPage == 1) {
           _goToPage(0);
        } else {
           _goToPage(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Modern glassmorphism top bar
                    _buildTopBar(),

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
                            onResultClick: () => _goToPage(2),
                          ),
                          const ResultsScreen(),
                        ],
                      ),
                    ),
                  ],
                ),

                // 🤖 CHATBOT FLOATING ACTION BUTTON
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: _openChatBot,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 3,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.8),
                    ],
                  ).createShader(bounds),
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
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Left action
                Align(
                  alignment: Alignment.centerLeft,
                  child: _currentPage > 0
                      ? _buildIconButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () {
                            if (_currentPage == 2) {
                              _goToPage(_lastPageBeforeResults);
                            } else {
                              _goToPage(0);
                            }
                          },
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          color: AppTheme.surfaceColor,
                          offset: const Offset(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'find_venues') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FindVenueScreen(),
                                  ),
                                );
                            } else if (value == 'results') {
                              _goToPage(2);
                            } else if (value == 'privacy_policy') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicyScreen(),
                                  ),
                                );
                            } else if (value == 'terms_conditions') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsConditionsScreen(),
                                  ),
                                );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'find_venues',
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Find Venues', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'results',
                              child: Row(
                                children: [
                                  Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Results', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'privacy_policy',
                              child: Row(
                                children: [
                                  Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'terms_conditions',
                              child: Row(
                                children: [
                                  Icon(Icons.description_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Terms & Conditions', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                // Right actions
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentPage == 0)
                        AnimatedBuilder(
                          animation: _bellAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _bellAnimation.value,
                              child: Stack(
                                children: [
                                  _buildIconButton(
                                    icon: Icons.notifications_rounded,
                                    onPressed: _openNotifications,
                                  ),
                                  if (_hasUnreadNotifications)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.accentSecondary,
                                              AppTheme.accentSecondary.withOpacity(0.8),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentSecondary.withOpacity(0.5),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isAccent = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAccent 
                ? AppTheme.primaryColor.withOpacity(0.2) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            icon,
            color: isAccent ? AppTheme.primaryColor : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}