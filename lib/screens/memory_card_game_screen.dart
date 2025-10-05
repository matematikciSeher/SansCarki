import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class MemoryCardGameScreen extends StatefulWidget {
  final UserProfile profile;

  const MemoryCardGameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<MemoryCardGameScreen> createState() => _MemoryCardGameScreenState();
}

class _MemoryCardGameScreenState extends State<MemoryCardGameScreen> with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _flipAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _flipAnimation;

  final List<MemoryCard> _cards = [];
  MemoryCard? _firstCard;
  MemoryCard? _secondCard;
  bool _canFlip = true;
  int _moves = 0;
  int _pairsFound = 0;
  int _score = 0;
  Timer? _gameTimer;
  int _elapsedTime = 0;
  bool _isGameComplete = false;
  bool _showInfo = true;

  final List<String> _cardSymbols = ['🌟', '🎈', '🎨', '🎭', '🎪', '🎯', '🎲', '🎮', '🎸', '🎹', '🎺', '🎻'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGame();
    _startTimer();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardAnimationController.forward();
  }

  void _initializeGame() {
    _cards.clear();
    final random = Random();

    // 6 çift kart oluştur (toplam 12 kart)
    for (int i = 0; i < 6; i++) {
      _cards.add(MemoryCard(
        id: i * 2,
        symbol: _cardSymbols[i],
        color: _getRandomColor(),
      ));
      _cards.add(MemoryCard(
        id: i * 2 + 1,
        symbol: _cardSymbols[i],
        color: _getRandomColor(),
      ));
    }

    // Kartları karıştır
    _cards.shuffle(random);
  }

  Color _getRandomColor() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameComplete) {
        setState(() {
          _elapsedTime++;
        });
      }
    });
  }

  void _onCardTap(MemoryCard card) {
    if (!_canFlip || card.isMatched || card.isFlipped) return;

    setState(() {
      card.isFlipped = true;
    });

    if (_firstCard == null) {
      _firstCard = card;
    } else {
      _secondCard = card;
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    _canFlip = false;

    if (_firstCard!.symbol == _secondCard!.symbol) {
      // Eşleşme bulundu
      _firstCard!.isMatched = true;
      _secondCard!.isMatched = true;
      _pairsFound++;
      _score += 100 + (100 - _elapsedTime).clamp(0, 50); // Hız bonusu

      if (_pairsFound == 6) {
        _endGame();
      }
    } else {
      // Eşleşme bulunamadı
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _firstCard!.isFlipped = false;
            _secondCard!.isFlipped = false;
            _firstCard = null;
            _secondCard = null;
            _canFlip = true;
          });
        }
      });
      return;
    }

    _firstCard = null;
    _secondCard = null;
    _canFlip = true;
  }

  void _endGame() async {
    _isGameComplete = true;
    _gameTimer?.cancel();

    // Bonus puanlar
    final timeBonus = (300 - _elapsedTime).clamp(0, 200);
    final moveBonus = (50 - _moves).clamp(0, 100);
    _score += timeBonus + moveBonus;

    // Güncel profili Firestore'dan çek
    UserProfile? currentProfile;
    try {
      currentProfile = await UserService.getCurrentUserProfile();
    } catch (e) {
      print('Güncel profil çekme hatası: $e');
      currentProfile = widget.profile; // Fallback
    }

    final baseProfile = currentProfile ?? widget.profile;

    // Profil güncelleme
    final updatedProfile = baseProfile.copyWith(
      points: baseProfile.points + _score,
      totalGamePoints: (baseProfile.totalGamePoints ?? 0) + _score,
    );

    // Firestore'a kaydet
    try {
      print('🎮 MEMORY CARD BİTTİ - Puan kaydediliyor...');
      print('   ✨ Kazanılan Puan: $_score');
      print('   📊 Yeni Oyun Puanı: ${updatedProfile.totalGamePoints ?? 0}');

      await UserService.updateCurrentUserProfile(updatedProfile);
      print('   ✅ Firestore\'a kaydedildi!');

      await UserService.logActivity(
        activityType: 'memory_game_completed',
        data: {
          'score': _score,
          'moves': _moves,
          'time': _elapsedTime,
        },
      );
    } catch (e) {
      print('❌ Memory card profil kaydetme hatası: $e');
    }

    _showGameCompleteDialog(updatedProfile);
  }

  void _showGameCompleteDialog(UserProfile updatedProfile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hafıza kartı oyununu tamamladın!'),
            const SizedBox(height: 16),
            _buildResultRow('⏱️ Süre', '${_elapsedTime} saniye'),
            _buildResultRow('🔄 Hamle', '$_moves'),
            _buildResultRow('🎯 Çift', '$_pairsFound'),
            _buildResultRow('⭐ Puan', '$_score'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Puanlar ana sisteme eklendi!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, updatedProfile);
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

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _firstCard = null;
      _secondCard = null;
      _canFlip = true;
      _moves = 0;
      _pairsFound = 0;
      _score = 0;
      _elapsedTime = 0;
      _isGameComplete = false;
    });

    _initializeGame();
    _startTimer();
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
    });
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _flipAnimationController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showInfo ? _buildInfoPage() : _buildGameBody(),
    );
  }

  Widget _buildInfoPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade400,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '🧠 Hafıza Kartı',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Kurallar:\n\n• Kartları çevirerek eşleşen çiftleri bul.\n• Her doğru eşleşme puan kazandırır.\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Puanlama:\n\n• Her doğru eşleşme: +10 puan\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Başla', style: TextStyle(fontSize: 22)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Oyun bilgileri
            _buildGameInfo(),

            // Kartlar
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Daha fazla sütun
                    crossAxisSpacing: 8, // Sabit boşluk
                    mainAxisSpacing: 8, // Sabit boşluk
                    childAspectRatio: 0.8, // Daha küçük kartlar
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(_cards[index]);
                  },
                ),
              ),
            ),
          ],
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
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '🧠 Hafıza Kartı',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Eşleşen kartları bul!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_score',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('⏱️', 'Süre', '${_elapsedTime}s'),
          _buildInfoItem('🔄', 'Hamle', '$_moves'),
          _buildInfoItem('🎯', 'Çift', '$_pairsFound/6'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(MemoryCard card) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: GestureDetector(
        onTap: () => _onCardTap(card),
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final flipValue = card.isFlipped ? 1.0 : 0.0;
            final rotation = flipValue * 0.5;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotation),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: card.isFlipped ? _buildCardFront(card) : _buildCardBack(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(MemoryCard card) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.color,
            card.color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          card.symbol,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.question_mark,
          size: 32,
          color: Colors.blue.shade600,
        ),
      ),
    );
  }
}

class MemoryCard {
  final int id;
  final String symbol;
  final Color color;
  bool isFlipped = false;
  bool isMatched = false;

  MemoryCard({
    required this.id,
    required this.symbol,
    required this.color,
  });
}
