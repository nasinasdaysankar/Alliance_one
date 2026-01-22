import 'package:flutter/material.dart';
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'No Notifications Yet',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
