import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'admin_quiz_panel_screen.dart';

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
    // Otomatik giriş devre dışı: kullanıcı her zaman giriş ekranını görür
  }

  // _maybeAutoEnter() kaldırıldı

  Future<void> _login() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _errorText = 'Lütfen bir kullanıcı adı veya e-posta girin';
      });
      return;
    }

    // Sınıf seçim ekranı kaldırıldı; doğrudan ana sayfaya geç
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _showAdminLogin() async {
    final TextEditingController passCtrl = TextEditingController();
    String? error;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Admin Girişi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passCtrl,
                  autofocus: true,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Admin şifresi',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final pass = passCtrl.text.trim();
                  if (pass == 'admin123') {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminQuizPanelScreen(),
                      ),
                    );
                  } else {
                    setStateDialog(() {
                      error = 'Hatalı şifre';
                    });
                  }
                },
                child: const Text('Giriş'),
              ),
            ],
          );
        });
      },
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
                // Logo (full width, auto-fit)
                SvgPicture.asset(
                  'assets/branding/logo.svg',
                  width: MediaQuery.of(context).size.width * 0.9,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text(
                      'GİRİŞ YAP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showAdminLogin,
                  icon: const Icon(Icons.lock),
                  label: const Text('Admin olarak giriş yap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
