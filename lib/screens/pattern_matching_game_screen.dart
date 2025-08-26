import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user_profile.dart';

class PatternMatchingGameScreen extends StatefulWidget {
  final UserProfile profile;

  const PatternMatchingGameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<PatternMatchingGameScreen> createState() =>
      _PatternMatchingGameScreenState();
}

class _PatternMatchingGameScreenState extends State<PatternMatchingGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _patternAnimationController;
  late Animation<double> _patternScaleAnimation;

  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
  ];

  List<int> _pattern = [];
  List<int> _userPattern = [];
  int _currentLevel = 1;
  int _score = 0;
  bool _isShowingPattern = false;
  bool _isUserTurn = false;
  bool _isGameOver = false;
  Timer? _patternTimer;
  int _patternIndex = 0;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNewGame();
  }

  void _initializeAnimations() {
    _patternAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _patternScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _patternAnimationController,
      curve: Curves.elasticOut,
    ));

    _patternAnimationController.forward();
  }

  void _startNewGame() {
    setState(() {
      _showInfo = false;
      _pattern.clear();
      _userPattern.clear();
      _isShowingPattern = false;
      _isUserTurn = false;
      _isGameOver = false;
      _patternIndex = 0;
    });

    _generatePattern();
    _showPattern();
  }

  void _generatePattern() {
    final random = Random();
    for (int i = 0; i < _currentLevel + 2; i++) {
      _pattern.add(random.nextInt(_colors.length));
    }
  }

  void _showPattern() {
    setState(() {
      _isShowingPattern = true;
    });

    _showNextPatternItem();
  }

  void _showNextPatternItem() {
    if (_patternIndex < _pattern.length) {
      setState(() {
        _patternIndex = _patternIndex;
      });

      _patternAnimationController.reset();
      _patternAnimationController.forward();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _patternIndex++;
          _showNextPatternItem();
        }
      });
    } else {
      _startUserTurn();
    }
  }

  void _startUserTurn() {
    setState(() {
      _isShowingPattern = false;
      _isUserTurn = true;
      _userPattern.clear();
    });
  }

  void _onColorTap(int colorIndex) {
    if (!_isUserTurn || _isGameOver) return;

    setState(() {
      _userPattern.add(colorIndex);
    });

    _patternAnimationController.reset();
    _patternAnimationController.forward();

    // Kontrol et
    if (_userPattern.length == _pattern.length) {
      _checkPattern();
    } else {
      // Kısmi kontrol
      if (_userPattern[_userPattern.length - 1] !=
          _pattern[_userPattern.length - 1]) {
        _gameOver();
      }
    }
  }

  void _checkPattern() {
    bool isCorrect = true;
    for (int i = 0; i < _pattern.length; i++) {
      if (_userPattern[i] != _pattern[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _levelComplete();
    } else {
      _gameOver();
    }
  }

  void _levelComplete() {
    _score += _currentLevel * 100;

    if (_currentLevel >= 10) {
      _gameWon();
    } else {
      _currentLevel++;
      _showLevelCompleteDialog();
    }
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 Seviye $_currentLevel Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Harika! Deseni doğru hatırladın.'),
            const SizedBox(height: 8),
            Text('Puan: ${_currentLevel * 100}'),
            const SizedBox(height: 8),
            Text('Sonraki seviye: ${_currentLevel + 1}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewLevel();
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      _isUserTurn = false;
    });

    _showGameOverDialog();
  }

  void _gameWon() {
    _score += 1000; // Bonus puan
    setState(() {
      _isGameOver = true;
      _isUserTurn = false;
    });

    _showGameWonDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('❌ Oyun Bitti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Deseni yanlış hatırladın.'),
            const SizedBox(height: 8),
            Text('Seviye: $_currentLevel'),
            Text('Puan: $_score'),
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

  void _showGameWonDialog() {
    // Profil güncelleme
    final updatedProfile = widget.profile.copyWith(
      points: widget.profile.points + _score,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tüm seviyeleri tamamladın!'),
            const SizedBox(height: 8),
            Text('Toplam Puan: $_score'),
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
    setState(() {
      _currentLevel = 1;
      _score = 0;
    });
    _startNewLevel();
  }

  @override
  void dispose() {
    _patternAnimationController.dispose();
    _patternTimer?.cancel();
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
            Colors.pink.shade900,
            Colors.pink.shade400,
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
                  '🎨 Desen Eşleştir',
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
                    'Kurallar:\n\n• Ekranda gösterilen desenleri sırayla hatırla ve tekrar et.\n• Her doğru tekrar puan kazandırır.\n',
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
                    'Puanlama:\n\n• Her doğru tekrar: +10 puan\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
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
            Colors.pink.shade900,
            Colors.pink.shade400,
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

            // Ana oyun alanı
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Desen gösterimi
                    if (_isShowingPattern) _buildPatternDisplay(),

                    // Kullanıcı deseni
                    if (_isUserTurn) _buildUserPatternDisplay(),

                    const SizedBox(height: 32),

                    // Renk butonları
                    Expanded(child: _buildColorGrid()),
                  ],
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
                  '🎨 Desen Eşleştir',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Desenleri hatırla ve tekrarla!',
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
          _buildInfoItem('🎯', 'Seviye', '$_currentLevel'),
          _buildInfoItem('🔢', 'Desen', '${_pattern.length}'),
          _buildInfoItem('⭐', 'Puan', '$_score'),
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

  Widget _buildPatternDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '👁️ Deseni İzle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _pattern.asMap().entries.map((entry) {
              final index = entry.key;
              final colorIndex = entry.value;
              final isActive = index == _patternIndex;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? _colors[colorIndex]
                      : _colors[colorIndex].withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPatternDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '🔄 Deseni Tekrarla',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _userPattern.map((colorIndex) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colors[colorIndex],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_userPattern.isEmpty)
            Text(
              'Renkleri sırayla dokun',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _colors.length,
      itemBuilder: (context, index) {
        return _buildColorButton(index);
      },
    );
  }

  Widget _buildColorButton(int index) {
    final isActive = _isUserTurn && !_isGameOver;
    final isHighlighted = _isShowingPattern && _patternIndex == index;

    return ScaleTransition(
      scale: _patternScaleAnimation,
      child: GestureDetector(
        onTap: isActive ? () => _onColorTap(index) : null,
        child: Container(
          decoration: BoxDecoration(
            color: isHighlighted
                ? _colors[index]
                : _colors[index].withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _colors[index].withOpacity(0.3),
                blurRadius: isHighlighted ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isActive
              ? const Icon(
                  Icons.touch_app,
                  color: Colors.white,
                  size: 32,
                )
              : null,
        ),
      ),
    );
  }
}
