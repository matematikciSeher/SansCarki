import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/carkigo_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
