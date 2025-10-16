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
      title: '🎯 ÇARKIGO\'ya Hoş Geldin!',
      description:
          'Her güne özel güzel eğlenceli mini görevlerle hayatını motive et!',
      color: Colors.purple,
    ),
    WelcomePage(
      icon: Icons.casino,
      title: '🎲 Çarkı Çevir, Görev Kazan',
      description:
          'Günlük çarkını çevir ve sana özel görevler kazan. Her görev seni bir adım daha ileriye taşır!',
      color: Colors.blue,
    ),
    WelcomePage(
      icon: Icons.emoji_events,
      title: '🏆 Rozetlerle Başarını Kanıtla',
      description:
          'Tamamladığın görevlerle özel rozetler kazan. Her rozet senin başarının bir kanıtı!',
      color: Colors.orange,
    ),
    WelcomePage(
      icon: Icons.quiz,
      title: '🧠 Oyunlar ve Quizler',
      description:
          'Eğlenceli oyunlar ve bilgi dolu quizlerle öğrenmeyi eğlenceye dönüştür!',
      color: Colors.green,
    ),
    WelcomePage(
      icon: Icons.trending_up,
      title: '📈 İlerlemeni Takip Et',
      description:
          'Puanlarını topla, seviyeni yükselt ve kendini sürekli geliştir!',
      color: Colors.red,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: PixelService.instance.getResponsiveSize(context, 120),
            height: PixelService.instance.getResponsiveSize(context, 120),
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.color,
                width: PixelService.instance.getResponsiveSize(context, 3),
              ),
            ),
            child: Icon(
              page.icon,
              size: PixelService.instance.getResponsiveIconSize(context, 60),
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

          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize:
                  PixelService.instance.getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: 600.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 500.ms),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize:
                  PixelService.instance.getResponsiveFontSize(context, 16),
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
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
        ],
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

  WelcomePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
