import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordAgainController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final pass2 = _passwordAgainController.text.trim();
    if (email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      setState(() => _errorText = 'Tüm alanlar zorunlu');
      return;
    }
    if (pass != pass2) {
      setState(() => _errorText = 'Şifreler eşleşmiyor');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorText = 'Şifre en az 6 karakter olmalı');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      // Firebase Auth ile kullanıcı oluştur
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);

      // Firestore'da kullanıcı profili oluştur
      if (userCredential.user != null) {
        await UserService.createUser(
          uid: userCredential.user!.uid,
          email: email,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = _mapAuthError(e);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Kayıt başarısız: ${e.toString()}';
      });
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Bu e-posta ile bir hesap zaten var';
      case 'invalid-email':
        return 'Geçersiz e-posta formatı';
      case 'operation-not-allowed':
        return 'Kayıt geçici olarak devre dışı';
      case 'weak-password':
        return 'Şifre çok zayıf';
      default:
        return 'Hata: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üye Ol')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorText != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(color: Color(0xFFC62828)),
                    ),
                  ),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordAgainController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre (tekrar)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Üye Ol'),
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
