import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/user_profile.dart';

class AvatarAdventureScreen extends StatefulWidget {
  final UserProfile profile;

  const AvatarAdventureScreen({
    super.key,
    required this.profile,
  });

  @override
  State<AvatarAdventureScreen> createState() => _AvatarAdventureScreenState();
}

class _AvatarAdventureScreenState extends State<AvatarAdventureScreen>
    with TickerProviderStateMixin {
  late AnimationController _avatarAnimationController;
  late Animation<double> _avatarScaleAnimation;
  late Animation<Offset> _avatarSlideAnimation;

  late UserProfile _currentProfile;
  int _score = 0;
  int _moves = 0;
  int _bestScore = 0;
  bool _isGameActive = false;
  List<int> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _firstCard;
  int? _secondCard;
  Timer? _flipTimer;

  // Avatar özellikleri
  int _intelligencePoints = 0;
  int _strengthPoints = 0;
  int _wisdomPoints = 0;
  int _creativityPoints = 0;
  int _socialPoints = 0;
  int _techPoints = 0;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _intelligencePoints = _currentProfile.intelligencePoints;
    _strengthPoints = _currentProfile.strengthPoints;
    _wisdomPoints = _currentProfile.wisdomPoints;
    _creativityPoints = _currentProfile.creativityPoints;
    _socialPoints = _currentProfile.socialPoints;
    _techPoints = _currentProfile.techPoints;

    _initializeAnimations();
    _initializeGame();
  }

  void _initializeAnimations() {
    _avatarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _avatarScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _avatarAnimationController,
      curve: Curves.elasticOut,
    ));

    _avatarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _avatarAnimationController,
      curve: Curves.easeOutBack,
    ));

    _avatarAnimationController.forward();
  }

  void _initializeGame() {
    _cards = [];
    _flipped = [];
    _matched = [];

    // 8 çift kart (16 kart toplam)
    for (int i = 0; i < 8; i++) {
      _cards.addAll([i, i]);
    }
    _cards.shuffle();

    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
    _firstCard = null;
    _secondCard = null;
    _score = 0;
    _moves = 0;
    _isGameActive = true;
  }

  void _flipCard(int index) {
    if (!_isGameActive || _flipped[index] || _matched[index]) return;

    setState(() {
      _flipped[index] = true;

      if (_firstCard == null) {
        _firstCard = index;
      } else if (_secondCard == null && _firstCard != index) {
        _secondCard = index;
        _moves++;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (_firstCard != null && _secondCard != null) {
      if (_cards[_firstCard!] == _cards[_secondCard!]) {
        // Eşleşme bulundu
        _matched[_firstCard!] = true;
        _matched[_secondCard!] = true;
        _score += 10;

        // Avatar puanları ekle
        _updateAvatarPoints();

        // Oyun bitti mi kontrol et
        if (_matched.every((match) => match)) {
          _endGame();
        }
      } else {
        // Eşleşme bulunamadı, kartları geri çevir
        _flipTimer = Timer(const Duration(milliseconds: 1000), () {
          setState(() {
            _flipped[_firstCard!] = false;
            _flipped[_secondCard!] = false;
            _firstCard = null;
            _secondCard = null;
          });
        });
      }
    }
  }

  void _updateAvatarPoints() {
    // Rastgele avatar özelliği seç ve puan ekle
    final random = Random();
    final attribute = random.nextInt(6);
    final points = random.nextInt(3) + 1; // 1-3 puan

    setState(() {
      switch (attribute) {
        case 0:
          _intelligencePoints += points;
          break;
        case 1:
          _strengthPoints += points;
          break;
        case 2:
          _wisdomPoints += points;
          break;
        case 3:
          _creativityPoints += points;
          break;
        case 4:
          _socialPoints += points;
          break;
        case 5:
          _techPoints += points;
          break;
      }
    });
  }

  void _endGame() {
    _isGameActive = false;
    if (_score > _bestScore) {
      _bestScore = _score;
    }

    // Quiz puanlarını UserProfile'a ekle
    final updatedProfile = _currentProfile.copyWith(
      totalQuizzes: (_currentProfile.totalQuizzes ?? 0) + 1,
      totalQuizPoints: (_currentProfile.totalQuizPoints ?? 0) + _score,
      points: _currentProfile.points + _score, // Ana puan sistemine ekle
      // Avatar puanlarını güncelle
      intelligencePoints: _intelligencePoints,
      strengthPoints: _strengthPoints,
      wisdomPoints: _wisdomPoints,
      creativityPoints: _creativityPoints,
      socialPoints: _socialPoints,
      techPoints: _techPoints,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎭 Macera Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Skor: $_score'),
            Text('Hamle: $_moves'),
            Text('En İyi Skor: $_bestScore'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Oyun puanları ana sisteme eklendi!',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Avatar Gelişimi:'),
            _buildAvatarSummary(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    _initializeGame();
    _avatarAnimationController.reset();
    _avatarAnimationController.forward();
  }

  Widget _buildAvatarSummary() {
    return Column(
      children: [
        _buildStatRow('🧠 Zeka', _intelligencePoints, Colors.blue),
        _buildStatRow('💪 Güç', _strengthPoints, Colors.red),
        _buildStatRow('📚 Bilgelik', _wisdomPoints, Colors.orange),
        _buildStatRow('🎨 Yaratıcılık', _creativityPoints, Colors.pink),
        _buildStatRow('🤝 Sosyal', _socialPoints, Colors.green),
        _buildStatRow('🔬 Teknoloji', _techPoints, Colors.purple),
      ],
    );
  }

  Widget _buildStatRow(String label, int points, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text('$points',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _avatarAnimationController.dispose();
    _flipTimer?.cancel();
    super.dispose();
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
              Colors.purple.shade800,
              Colors.indigo.shade900,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Ana içerik - ScrollView ile
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar ve İstatistikler
                      _buildAvatarSection(),

                      const SizedBox(height: 16),

                      // Oyun istatistikleri
                      _buildGameStats(),

                      const SizedBox(height: 24),

                      // Hafıza kartları
                      _buildMemoryCards(),

                      const SizedBox(height: 20),
                    ],
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  '🎭 Avatar Macerası',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Hafıza Kartı Oyunu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar görseli
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 30,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          // Avatar bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seviye ${_currentProfile.avatarLevel}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hafıza Oyunu',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Toplam puan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_score puan',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('🎯 Skor', '$_score', Colors.green),
          _buildStatItem('🔄 Hamle', '$_moves', Colors.blue),
          _buildStatItem('🏆 En İyi', '$_bestScore', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🎴 Hafıza Kartları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              return _buildCard(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final isFlipped = _flipped[index];
    final isMatched = _matched[index];
    final cardValue = _cards[index];

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isMatched
              ? Colors.green.withOpacity(0.8)
              : isFlipped
                  ? Colors.white
                  : Colors.blue.shade400,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: isFlipped || isMatched
              ? Text(
                  '🎯',
                  style: TextStyle(
                    fontSize: 20,
                    color: isMatched ? Colors.white : Colors.blue.shade800,
                  ),
                )
              : const Text(
                  '❓',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
