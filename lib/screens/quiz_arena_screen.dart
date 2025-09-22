import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../models/quiz.dart';
import '../models/user_profile.dart';
import '../data/quiz_repository.dart';
import '../widgets/profile_page.dart';
import '../widgets/fancy_bottom_buttons.dart';
import 'game_selection_screen.dart';
import 'quiz_game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizArenaScreen extends StatefulWidget {
  final UserProfile profile;

  const QuizArenaScreen({
    super.key,
    required this.profile,
  });

  @override
  State<QuizArenaScreen> createState() => _QuizArenaScreenState();
}

class _QuizArenaScreenState extends State<QuizArenaScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppHeaderBar(
        title: '🏆 Quiz Arena',
        subtitle: 'Bilgi yarışmasında kendini test et!',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => _showProfile(context),
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900,
              Colors.orange.shade800,
              Colors.amber.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Ana içerik
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Hoş geldin kartı
                          _buildWelcomeCard(),

                          const SizedBox(height: 24),

                          // İstatistik kartları
                          _buildStatsCards(),

                          const SizedBox(height: 24),

                          // Sadece rastgele quiz başlat butonu
                          _buildQuickStartButton(),

                          const SizedBox(height: 24),

                          // Son quiz sonuçları
                          _buildRecentResults(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: FancyBottomButtons(
          onWheelTap: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
          onGamesTap: () async {
            final updatedProfile = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GameSelectionScreen(profile: widget.profile),
              ),
            );
            if (updatedProfile != null) {
              Navigator.pop(context, updatedProfile);
            }
          },
          onQuizTap: () {},
          onProfileTap: () => _showProfile(context),
        ),
      ),
    );
  }

  // Header kaldırıldı; AppHeaderBar kullanılıyor

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade400.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.quiz,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '🏆 Quiz Arena\'ya Hoş Geldin!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bilgi yarışmasında kendini test et ve puanlarını artır!',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '🎯 Toplam Quiz',
            '${widget.profile.totalQuizzes ?? 0}',
            Colors.blue,
            Icons.quiz,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            '🏆 En Yüksek',
            '${widget.profile.highestQuizScore ?? 0}',
            Colors.green,
            Icons.emoji_events,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            '⭐ Quiz Puanı',
            '${widget.profile.totalQuizPoints ?? 0}',
            Colors.purple,
            Icons.stars,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startRandomQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shuffle, size: 24),
            const SizedBox(width: 12),
            const Text(
              '🎲 Rastgele Quiz Başlat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '📊 Son Sonuçlar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Son Quiz Skoru',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${widget.profile.highestQuizScore ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam Quiz Puanı',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${widget.profile.totalQuizPoints ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startRandomQuiz() async {
    final all = await QuizRepository.fetchAll();
    // Sınıf seviyesi filtreleri kaldırıldı: tüm sorular havuzda
    List<QuizQuestion> filtered = all;
    filtered.shuffle();
    // 5 soru, mümkünse 5 farklı kategoriden gelsin
    final Map<QuizCategory, List<QuizQuestion>> byCategory = {};
    for (final q in filtered) {
      byCategory.putIfAbsent(q.category, () => []).add(q);
    }

    final List<QuizQuestion> selected = [];
    final categories = byCategory.keys.toList()..shuffle();
    for (final cat in categories) {
      final list = byCategory[cat]!;
      list.shuffle();
      selected.add(list.first);
      if (selected.length == 5) break;
    }

    if (selected.length < 5) {
      final usedIds = selected.map((e) => e.id).toSet();
      final remaining = filtered.where((q) => !usedIds.contains(q.id)).toList()
        ..shuffle();
      selected.addAll(remaining.take(5 - selected.length));
    }

    // Son oynanan soruları hariç tutmaya çalış (tek oturumda tekrar ihtimalini azalt)
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList('quiz_recent_ids') ?? <String>[];
      final recentSet = recent.toSet();
      final filteredSelected =
          selected.where((q) => !recentSet.contains(q.id)).toList();
      if (filteredSelected.length >= 5) {
        selected
          ..clear()
          ..addAll(filteredSelected.take(5));
      }
    } catch (_) {}

    final quizQuestions = selected;
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizGameScreen(
          questions: quizQuestions,
          profile: widget.profile,
        ),
      ),
    );
    if (updatedProfile != null && updatedProfile is UserProfile) {
      Navigator.pop(context, updatedProfile);
    }
  }

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProfilePage(
        profile: widget.profile,
        completedTasks: const [],
      ),
    );
  }
}
