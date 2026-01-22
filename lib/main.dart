
import 'package:flutter/material.dart';
import 'theme.dart';
import 'home_screen.dart';

void main() {
  runApp(const AllianceOneApp());
}

class AllianceOneApp extends StatelessWidget {
  const AllianceOneApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alliance One',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
