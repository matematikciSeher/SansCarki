import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/animated_login_wheel.dart';
import 'admin_quiz_panel_screen.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../services/pixel_service.dart';
import '../services/user_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _rememberPassword = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberPassword = prefs.getBool('remember_password') ?? false;

    if (mounted) {
      setState(() {
        if (savedEmail != null) _emailController.text = savedEmail;
        if (savedPassword != null && rememberPassword) {
          _passwordController.text = savedPassword;
        }
        _rememberPassword = rememberPassword;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberPassword) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
      await prefs.setBool('remember_password', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_password', false);
    }
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
      // Şifre kaydetme seçeneği varsa kaydet
      await _saveCredentials();
      // AuthWrapper otomatik olarak HomeScreen'e yönlendirecek
      // Navigator kullanmaya gerek yok
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

  Future<void> _signInWithGoogle() async {
    final serverClientId = DefaultFirebaseOptions.googleWebClientId;
    if (serverClientId == null || serverClientId.isEmpty) {
      setState(() {
        _errorText = 'Google girişi için yapılandırma eksik. '
            'Firebase Console → Authentication → Sign-in method → Google\'ı açın, '
            'Web client ID\'yi kopyalayıp lib/firebase_options.dart dosyasındaki '
            'googleWebClientId alanına ekleyin.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isGoogleLoading = true;
    });
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: serverClientId,
        scopes: ['email'],
      );
      // Önceki oturumu temizle (cache sorunlarını önlemek için)
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) {
        if (mounted) {
          setState(() {
            _errorText = 'Google girişi için Web Client ID gerekli. '
                'Firebase Console → Authentication → Google → Web client ID değerini '
                'lib/firebase_options.dart içindeki googleWebClientId alanına ekleyin.';
            _isGoogleLoading = false;
          });
        }
        return;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await UserService.ensureUserExists();
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _mapAuthError(e);
          _isGoogleLoading = false;
        });
      }
    } catch (e, stack) {
      if (mounted) {
        final msg = e.toString();
        String userMessage = 'Google ile giriş başarısız. Lütfen tekrar deneyin.';
        if (msg.contains('12501') || msg.contains('sign_in_canceled')) {
          userMessage = 'Giriş iptal edildi.';
        } else if (msg.contains('10') || msg.contains('developer_error')) {
          userMessage = 'Yapılandırma hatası: Firebase Console\'da Google girişi açın, '
              'Android uygulamasına SHA-1 parmak izini ekleyin ve googleWebClientId\'yi firebase_options.dart\'a ekleyin.';
        } else if (msg.contains('network')) {
          userMessage = 'Ağ hatası. İnternet bağlantınızı kontrol edin.';
        }
        setState(() {
          _errorText = userMessage;
          _isGoogleLoading = false;
        });
        debugPrint('Google sign-in error: $e\n$stack');
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
    final radius = PixelService.instance.getResponsiveBorderRadius(context, 20);
    final compact = PixelService.instance.isCompactWidth(context);
    final wheelSize = (MediaQuery.of(context).size.width * 0.5).clamp(150.0, 220.0);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B4EAA),
              Color(0xFF8E7CC3),
              Color(0xFFB8A9D4),
              Color(0xFFE8D5F2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 24,
                  vertical: compact ? 16 : 24,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedLoginWheel(
                        size: wheelSize,
                        enableIdleSpin: true,
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
                        iconSize: PixelService.instance
                            .getResponsiveIconSize(context, compact ? 18 : 20),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ÇARKI ÇEVİR, EĞLENCEYE GÖMÜL!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A3F6E),
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.8),
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Üye ol uyarısı banner
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(radius * 0.8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF8A65),
                                const Color(0xFFFF7043),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(radius * 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7043).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Üye olmadınız mı?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Hemen üye olun!',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                        TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          filled: true,
                          fillColor: const Color(0xFFF5F0FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radius * 0.7),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radius * 0.7),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8D5F2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radius * 0.7),
                            borderSide: const BorderSide(
                              color: Color(0xFF6B4EAA),
                              width: 2,
                            ),
                          ),
                          errorText: _errorText,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          filled: true,
                          fillColor: const Color(0xFFF5F0FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radius * 0.7),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radius * 0.7),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8D5F2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radius * 0.7),
                            borderSide: const BorderSide(
                              color: Color(0xFF6B4EAA),
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _rememberPassword = !_rememberPassword;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _rememberPassword,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberPassword = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF6B4EAA),
                                    fillColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return const Color(0xFF6B4EAA);
                                      }
                                      return Colors.grey.shade300;
                                    }),
                                  ),
                                  Text(
                                    'Şifremi hatırla',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _forgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6B4EAA),
                            ),
                            child: const Text('Şifremi unuttum'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4EAA),
                            foregroundColor: Colors.white,
                            padding: PixelService.instance.getResponsivePadding(
                              context,
                              basePadding: 14,
                              top: 16,
                              bottom: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radius * 0.7),
                            ),
                            elevation: 2,
                            shadowColor: const Color(0xFF6B4EAA).withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Giriş yap',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'veya',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_isLoading || _isGoogleLoading)
                              ? null
                              : _signInWithGoogle,
                          icon: _isGoogleLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: const Color(0xFF4285F4),
                                  ),
                                )
                              : const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 24,
                                  color: Color(0xFF4285F4),
                                ),
                          label: Text(
                            _isGoogleLoading
                                ? 'Giriş yapılıyor...'
                                : 'Google ile giriş yap',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _isGoogleLoading
                                  ? Colors.grey
                                  : Colors.grey.shade800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade800,
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                            padding: PixelService.instance.getResponsivePadding(
                              context,
                              basePadding: 14,
                              top: 14,
                              bottom: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(radius * 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hesabın yok mu? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6B4EAA),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text('Üye ol'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAdminLogin,
                        icon: Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          'Admin olarak giriş yap',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
