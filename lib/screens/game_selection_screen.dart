import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_profile.dart';
import 'memory_card_game_screen.dart';
import 'puzzle_game_screen.dart';
import 'word_scramble_game_screen.dart';
import 'math_challenge_game_screen.dart';
import 'pattern_matching_game_screen.dart';
import '../widgets/profile_page.dart';

class GameSelectionScreen extends StatefulWidget {
  final UserProfile profile;

  const GameSelectionScreen({
    super.key,
    required this.profile,
  });

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<GameInfo> _games = [
    GameInfo(
      id: 'memory',
      name: 'Hafıza Kartı',
      description: 'Eşleşen kartları bul ve hafızanı test et!',
      emoji: '🧠',
      color: Colors.blue,
      difficulty: 'Kolay',
      estimatedTime: '3-5 dk',
    ),
    GameInfo(
      id: 'puzzle',
      name: 'Sayı Bulmaca',
      description: 'Sayıları doğru sıraya diz ve bulmacayı çöz!',
      emoji: '🧩',
      color: Colors.green,
      difficulty: 'Orta',
      estimatedTime: '5-8 dk',
    ),
    GameInfo(
      id: 'word',
      name: 'Kelime Karıştır',
      description: 'Karışık harflerden anlamlı kelimeler oluştur!',
      emoji: '📝',
      color: Colors.orange,
      difficulty: 'Orta',
      estimatedTime: '4-6 dk',
    ),
    GameInfo(
      id: 'math',
      name: 'Matematik Mücadelesi',
      description: 'Hızlı matematik işlemleri yap ve puan kazan!',
      emoji: '🔢',
      color: Colors.purple,
      difficulty: 'Zor',
      estimatedTime: '6-10 dk',
    ),
    GameInfo(
      id: 'pattern',
      name: 'Desen Eşleştir',
      description: 'Desenleri hatırla ve tekrarla!',
      emoji: '🎨',
      color: Colors.pink,
      difficulty: 'Orta',
      estimatedTime: '4-7 dk',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startRandomGame() {
    final random = Random();
    final randomGame = _games[random.nextInt(_games.length)];
    _navigateToGame(randomGame.id);
  }

  void _navigateToGame(String gameId) {
    switch (gameId) {
      case 'memory':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemoryCardGameScreen(profile: widget.profile),
          ),
        );
        break;
      case 'puzzle':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PuzzleGameScreen(profile: widget.profile),
          ),
        );
        break;
      case 'word':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WordScrambleGameScreen(profile: widget.profile),
          ),
        );
        break;
      case 'math':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MathChallengeGameScreen(profile: widget.profile),
          ),
        );
        break;
      case 'pattern':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PatternMatchingGameScreen(profile: widget.profile),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade900,
              Colors.purple.shade800,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Ana içerik
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Hoş geldin kartı
                          _buildWelcomeCard(),

                          const SizedBox(height: 24),

                          // Rastgele oyun butonu

                          const SizedBox(height: 24),

                          // Oyun listesi
                          _buildGamesList(),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '🎮 Oyun Merkezi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Eğlenceli oyunlarla eğlen ve öğren!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showProfile(context),
              icon: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.games,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '🎯 Oyun Merkezine Hoş Geldin!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '5 farklı eğlenceli oyun seni bekliyor!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('🎮', 'Toplam Oyun', '5'),
              _buildStatItem(
                  '🏆', 'En Yüksek', '${widget.profile.highestQuizScore ?? 0}'),
              _buildStatItem('⭐', 'Puan', '${widget.profile.points}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
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
            '🎯 Mevcut Oyunlar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._games.map((game) => _buildGameCard(game)).toList(),
      ],
    );
  }

  Widget _buildGameCard(GameInfo game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToGame(game.id),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  game.color.withOpacity(0.3),
                  game.color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: game.color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: game.color.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: game.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    game.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: game.color.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              game.difficulty,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: game.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              game.estimatedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  color: game.color,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProfilePage(
        profile: widget.profile,
        completedTasks: const [], // Boş liste olarak geçiyoruz
      ),
    );
  }
}

class GameInfo {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final String difficulty;
  final String estimatedTime;

  GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.difficulty,
    required this.estimatedTime,
  });
}
