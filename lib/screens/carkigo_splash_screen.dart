import 'package:flutter/material.dart';
import 'home_screen.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/animated_login_wheel.dart';
import 'admin_quiz_panel_screen.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarkiGoSplashScreen extends StatefulWidget {
  const CarkiGoSplashScreen({super.key});

  @override
  State<CarkiGoSplashScreen> createState() => _CarkiGoSplashScreenState();
}

class _CarkiGoSplashScreenState extends State<CarkiGoSplashScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Otomatik giriş devre dışı: kullanıcı her zaman giriş ekranını görür
  }

  // _maybeAutoEnter() kaldırıldı

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        _errorText = 'E-posta ve şifre zorunludur';
      });
      return;
    }
    setState(() {
      _errorText = null;
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = _mapAuthError(e);
      });
    } catch (_) {
      setState(() {
        _errorText = 'Giriş başarısız. Lütfen tekrar deneyin';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Geçersiz e-posta formatı';
      case 'user-disabled':
        return 'Hesap devre dışı bırakılmış';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen biraz sonra tekrar deneyin';
      case 'network-request-failed':
        return 'Ağ hatası. İnternet bağlantınızı kontrol edin';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi şu anda kullanıma kapalı';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin';
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama için e-postayı girin')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e))),
      );
    }
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE1BEE7),
              Color(0xFFB3E5FC),
              Color(0xFFFFF59D),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedLoginWheel(
                      size: MediaQuery.of(context).size.width * 0.55,
                      enableIdleSpin: true,
                      entryDuration: Duration(milliseconds: 80000),
                      spinDuration: Duration(milliseconds: 70000),
                      idlePeriod: Duration(seconds: 40),
                      idleRampDuration: Duration(milliseconds: 15000),
                      iconDropDuration: Duration(milliseconds: 40000),
                      icons: const [
                        Icons.star,
                        Icons.sports_esports,
                        Icons.music_note,
                        Icons.school,
                        Icons.emoji_emotions,
                        Icons.rocket_launch,
                        Icons.palette,
                        Icons.lightbulb,
                      ],
                      iconSize: 20,
                    ),
                    const SizedBox(height: 16),
                    const Text('ÇARKI ÇEVİR, EĞLENCEYE GÖMÜL!'),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        errorText: _errorText,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'GİRİŞ YAP',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Hesabın yok mu? '),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Üye Ol'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _showAdminLogin,
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin olarak giriş yap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
