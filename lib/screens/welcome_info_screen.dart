import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/pixel_service.dart';

class WelcomeInfoScreen extends StatefulWidget {
  final bool isFromSettings;

  const WelcomeInfoScreen({super.key, this.isFromSettings = false});

  @override
  State<WelcomeInfoScreen> createState() => _WelcomeInfoScreenState();
}

class _WelcomeInfoScreenState extends State<WelcomeInfoScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<WelcomePage> _pages = [
    WelcomePage(
      icon: Icons.celebration,
      title: '🎯 ÇARKIGO\'ya Hoş Geldiniz!',
      description:
          'ÇARKIGO, günlük hayatınızı renklendiren, motivasyonunuzu artıran ve eğlence dolu görevlerle dolu bir platformdur. Her gün yeni fırsatlar, yeni maceralar ve yeni başarılar sizi bekliyor!',
      color: Colors.purple,
      features: [
        '🎲 Günlük Çark Çevirme Sistemi',
        '✨ Kişiselleştirilmiş Görevler',
        '🏆 Başarı Rozetleri',
      ],
    ),
    WelcomePage(
      icon: Icons.casino,
      title: '🎲 Çarkı Çevir, Görev Kazan',
      description:
          'Her gün çarkınızı çevirin ve size özel olarak seçilmiş eğlenceli görevler kazanın. Görevler kategorilere ayrılmıştır ve her biri farklı becerilerinizi geliştirmenize yardımcı olur. Tamamladığınız her görev sizi daha güçlü, daha mutlu ve daha başarılı yapar!',
      color: Colors.blue,
      features: [
        '📅 Her Gün Yeni Fırsatlar',
        '🎯 Kategorize Edilmiş Görevler',
        '⚡ Hızlı ve Eğlenceli Aktiviteler',
      ],
    ),
    WelcomePage(
      icon: Icons.emoji_events,
      title: '🏆 Rozetlerle Başarını Kanıtla',
      description:
          'Tamamladığınız her görev, kazandığınız her rozet sizin kişisel başarı koleksiyonunuzun bir parçasıdır. Rozetleriniz sadece süs değil, gerçek başarılarınızın somut kanıtlarıdır. Arkadaşlarınızla paylaşın ve ilham verin!',
      color: Colors.orange,
      features: [
        '🥇 Özel Başarı Rozetleri',
        '📊 Detaylı İstatistikler',
        '👥 Sosyal Paylaşım',
      ],
    ),
    WelcomePage(
      icon: Icons.quiz,
      title: '🧠 Oyunlar ve Quizler',
      description:
          'Zihinsel gelişiminizi destekleyen eğlenceli oyunlar ve bilgi dolu quizlerle öğrenmeyi bir maceraya dönüştürün. Tetris\'ten Sudoku\'ya, hafıza oyunlarından mantık bulmacalarına kadar geniş bir oyun yelpazesi sizi bekliyor!',
      color: Colors.green,
      features: [
        '🎮 15+ Farklı Oyun Türü',
        '🧩 Zeka Geliştirici Bulmacalar',
        '📚 Bilgi Dolu Quizler',
      ],
    ),
    WelcomePage(
      icon: Icons.trending_up,
      title: '📈 İlerlemeni Takip Et ve Geliş',
      description:
          'Kazandığınız her puan, tamamladığınız her görev ve yükseldiğiniz her seviye sizin kişisel gelişim yolculuğunuzun bir parçasıdır. Detaylı istatistiklerle ilerlemenizi izleyin, hedeflerinizi belirleyin ve sürekli olarak kendinizi geliştirin. ÇARKIGO ile her gün daha iyi bir versiyonunuzu yaratın!',
      color: Colors.red,
      features: [
        '📊 Detaylı İlerleme Takibi',
        '🎯 Kişisel Hedefler',
        '🚀 Sürekli Gelişim',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _goToHome,
                    child: const Text(
                      'Geç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _previousPage,
                        child: const Text(
                          'Geri',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                    ElevatedButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? _goToHome
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? (widget.isFromSettings ? 'Tamam' : 'Başla!')
                            : 'İleri',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(WelcomePage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Icon with enhanced design
          Container(
            width: PixelService.instance.getResponsiveSize(context, 140),
            height: PixelService.instance.getResponsiveSize(context, 140),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  page.color.withOpacity(0.3),
                  page.color.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.color,
                width: PixelService.instance.getResponsiveSize(context, 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: PixelService.instance.getResponsiveIconSize(context, 70),
              color: page.color,
            ),
          )
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 40),

          // Title with enhanced styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              page.title,
              style: TextStyle(
                fontSize:
                    PixelService.instance.getResponsiveFontSize(context, 26),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // Description with enhanced styling
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize:
                    PixelService.instance.getResponsiveFontSize(context, 16),
                color: Colors.white.withOpacity(0.95),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
                delay: 200.ms,
              )
              .fadeIn(
                duration: 500.ms,
                delay: 200.ms,
              ),

          // Features list
          if (page.features != null && page.features!.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...page.features!.map((feature) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: page.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: page.color.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white.withOpacity(0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: PixelService.instance
                              .getResponsiveFontSize(context, 14),
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .slideX(
                    begin: -0.2,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                    delay: 300.ms,
                  )
                  .fadeIn(
                    duration: 400.ms,
                    delay: 300.ms,
                  );
            }).toList(),
          ],
        ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToHome() async {
    // Eğer ayarlardan geliyorsa sadece geri dön, yoksa ana sayfaya git
    if (widget.isFromSettings) {
      Navigator.of(context).pop();
    } else {
      // Kullanıcının bilgilendirme sayfasını gördüğünü kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
  }
}

class WelcomePage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<String>? features;

  WelcomePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.features,
  });
}
