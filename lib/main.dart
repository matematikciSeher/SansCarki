import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_page.dart';
import 'screens/welcome_info_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/performance_service.dart';
import 'services/pixel_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Performans seviyesini tespit et
  await PerformanceService.instance.detectPerformanceLevel();

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
        // Pixel perfect ayarları
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Pixel perfect rendering
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              PixelService.instance.getResponsiveFontScale(context),
            ),
          ),
          child: child!,
        );
      },
      home: const AuthWrapper(),
    );
  }
}

/// Firebase Auth durumunu dinleyen ve kullanıcıyı doğru sayfaya yönlendiren wrapper
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasSeenWelcome = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
  }

  Future<void> _checkWelcomeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

    if (mounted) {
      setState(() {
        _hasSeenWelcome = hasSeenWelcome;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı durumu kontrol ediliyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı oturumu varsa
        if (snapshot.hasData && snapshot.data != null) {
          // İlk giriş yapıyorsa bilgilendirme sayfasına yönlendir
          if (!_hasSeenWelcome) {
            return const WelcomeInfoScreen();
          }
          return const HomeScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
