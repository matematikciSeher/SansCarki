import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'grade_select_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

class CarkiGoSplashScreen extends StatefulWidget {
  const CarkiGoSplashScreen({super.key});

  @override
  State<CarkiGoSplashScreen> createState() => _CarkiGoSplashScreenState();
}

class _CarkiGoSplashScreenState extends State<CarkiGoSplashScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoEnter());
  }

  Future<void> _maybeAutoEnter() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    if (profileJson == null) return;
    final profile = UserProfile.fromJson(json.decode(profileJson));
    if (!mounted) return;
    if (profile.grade != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _errorText = 'Lütfen bir kullanıcı adı veya e-posta girin';
      });
      return;
    }

    // Login'den sonra sınıf seçim ekranına REPLACE olarak git
    if (!mounted) return;
    final selected = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const GradeSelectScreen()),
    );
    if (!mounted) return;
    if (selected == null) return; // kullanıcı geri döndüyse bekle
    // Seçimi kaydet ve ana sayfaya yönlen
    final prefs = await SharedPreferences.getInstance();
    UserProfile profile;
    final profileJson = prefs.getString('user_profile');
    profile = profileJson != null
        ? UserProfile.fromJson(json.decode(profileJson))
        : UserProfile();
    profile = profile.copyWith(grade: selected);
    await prefs.setString('user_profile', json.encode(profile.toJson()));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '🎡',
                      style: TextStyle(fontSize: 80, shadows: [
                        Shadow(color: Colors.purple.shade200, blurRadius: 12)
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Proje ismi
                const Text(
                  'ÇARKIGO!',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Colors.purpleAccent, blurRadius: 8)
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Slogan
                const Text(
                  'ÇARKI ÇEVİR, EĞLENCEYE GÖMÜL!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 36),
                // Login alanı
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı adı veya e-posta',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                    errorText: _errorText,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text(
                      'GİRİŞ YAP',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2),
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
}
