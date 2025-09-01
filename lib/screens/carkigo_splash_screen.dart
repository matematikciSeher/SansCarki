import 'package:flutter/material.dart';
import 'home_screen.dart';

class CarkiGoSplashScreen extends StatefulWidget {
  const CarkiGoSplashScreen({super.key});

  @override
  State<CarkiGoSplashScreen> createState() => _CarkiGoSplashScreenState();
}

class _CarkiGoSplashScreenState extends State<CarkiGoSplashScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _login() {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _errorText = 'Lütfen bir kullanıcı adı veya e-posta girin';
      });
      return;
    }
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
