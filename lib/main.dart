import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/carkigo_splash_screen.dart';

void main() {
  runApp(const CarkiGoApp());
}

class CarkiGoApp extends StatelessWidget {
  const CarkiGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ÇarkıGO!',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Montserrat',
      ),
      debugShowCheckedModeBanner: false,
      home: const CarkiGoSplashScreen(),
    );
  }
}
