import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import 'memory_card_game_screen.dart';
import 'puzzle_game_screen.dart';
import 'word_scramble_game_screen.dart';
import 'math_challenge_game_screen.dart';
import 'pattern_matching_game_screen.dart';
import 'quiz_game_screen.dart';
import 'quiz_arena_screen.dart';
import 'avatar_adventure_screen.dart';

import 'target_shooter_game_screen.dart';
import 'logic_gates_puzzle_screen.dart';
import 'maze_game_screen.dart';
import 'tetris_game_screen.dart';
import 'wheel_of_fortune_screen.dart';
// import 'shape_shift_game_screen.dart';
// import 'ice_breaker_game_screen.dart';

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

  late UserProfile _profile;

  final List<GameInfo> _games = [
    GameInfo(
      id: 'memory',
      name: 'Hafıza Kartı',
      description: 'Eşleşen kartları bul ve hafızanı test et!',
      emoji: '🧠',
      color: Colors.blue,
      estimatedTime: '3-5 dk',
    ),
    GameInfo(
      id: 'tetris',
      name: 'Tetris',
      description: 'Düşen bloklarla satırları tamamla, yüksek skor yap!',
      emoji: '🧱',
      color: Colors.green,
      estimatedTime: '5-10 dk',
    ),
    GameInfo(
      id: 'word',
      name: '💣 Word Bomb',
      description: 'İngilizce kelimeleri öğren, bombadan kaç!',
      emoji: '💣',
      color: Colors.red,
      estimatedTime: '2-4 dk',
    ),
    GameInfo(
      id: 'math',
      name: 'Matematik Mücadelesi',
      description: 'Hızlı matematik işlemleri yap ve puan kazan!',
      emoji: '🔢',
      color: Colors.purple,
      estimatedTime: '6-10 dk',
    ),
    GameInfo(
      id: 'pattern',
      name: 'Desen Eşleştir',
      description: 'Desenleri hatırla ve tekrarla!',
      emoji: '🎨',
      color: Colors.pink,
      estimatedTime: '4-7 dk',
    ),
    GameInfo(
      id: 'maze',
      name: 'Labirent',
      description: 'Çıkışı bul, süreyle yarış!',
      emoji: '🌀',
      color: Colors.blueGrey,
      estimatedTime: '3-6 dk',
    ),
    
    GameInfo(
      id: 'target_shooter',
      name: 'Hedef Avı',
      description: 'Hareketli hedefleri vur, isabetli atışlarla puan topla!',
      emoji: '🎯',
      color: Colors.deepPurple,
      estimatedTime: '1-2 dk',
    ),
    GameInfo(
      id: 'logic_gates',
      name: 'Mantık Kapıları',
      description: 'Girişleri ayarla, kapıları çöz, enerjiyi çıkışa ulaştır!',
      emoji: '🔌',
      color: Colors.blueGrey,
      estimatedTime: '2-5 dk',
    ),
    GameInfo(
      id: 'wheel_fortune',
      name: 'Çarkıfelek',
      description: 'Çarkı çevir, harf tahmin et, puanları topla!',
      emoji: '🎡',
      color: Colors.orange,
      estimatedTime: '3-6 dk',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
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

  Future<void> _navigateToGame(String gameId) async {
    dynamic result;
    switch (gameId) {
      case 'memory':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemoryCardGameScreen(profile: _profile),
          ),
        );
        break;
      case 'tetris':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TetrisGameScreen(profile: _profile),
          ),
        );
        break;
      case 'word':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordBombGameScreen(profile: _profile),
          ),
        );
        break;
      case 'math':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MathChallengeGameScreen(profile: _profile),
          ),
        );
        break;
      case 'pattern':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatternMatchingGameScreen(profile: _profile),
          ),
        );
        break;
      case 'maze':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MazeGameScreen(profile: _profile),
          ),
        );
        break;
      
      case 'target_shooter':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetShooterGameScreen(profile: _profile),
          ),
        );
        break;
      case 'logic_gates':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LogicGatesPuzzleScreen(profile: _profile),
          ),
        );
        break;
      case 'wheel_fortune':
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WheelOfFortuneScreen(profile: _profile),
          ),
        );
        break;
    }
    if (result is UserProfile) {
      setState(() {
        _profile = result;
      });
    } else {
      // Son profil durumunu tercihlerden çek (oyunlar kendi kendine kaydedebilir)
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('user_profile');
        if (raw != null) {
          setState(() {
            _profile = UserProfile.fromJson(json.decode(raw));
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _profile);
        return false;
      },
      child: Scaffold(
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
            '${_games.length} farklı eğlenceli oyun seni bekliyor!',
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
              _buildStatItem('🎮', 'Toplam Oyun', '${_games.length}'),
              _buildStatItem(
                  '🏆', 'En Yüksek', '${_profile.highestQuizScore ?? 0}'),
              _buildStatItem('⭐', 'Görev Puanı', '${_profile.points}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                  '🎲', 'Oyun Puanı', '${_profile.totalGamePoints ?? 0}'),
              _buildStatItem(
                  '🧠', 'Quiz Puanı', '${_profile.totalQuizPoints ?? 0}'),
              _buildStatItem('💎', 'Toplam', '${_profile.totalAllPoints}'),
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
    // Profil sayfası henüz mevcut değil, sadece profil bilgilerini göster
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👤 Profil Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProfileInfo('⭐ Puan', '${_profile.points}'),
            _buildProfileInfo(
                '🏆 En Yüksek Quiz', '${_profile.highestQuizScore ?? 0}'),
            _buildProfileInfo(
                '🎯 Tamamlanan Görev', '${_profile.completedTasks ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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
  final String estimatedTime;

  GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.estimatedTime,
  });
}
