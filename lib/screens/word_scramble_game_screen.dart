import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user_profile.dart';

class WordScrambleGameScreen extends StatefulWidget {
  final UserProfile profile;

  const WordScrambleGameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<WordScrambleGameScreen> createState() => _WordScrambleGameScreenState();
}

class _WordScrambleGameScreenState extends State<WordScrambleGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _letterAnimationController;
  late Animation<double> _letterScaleAnimation;

  final List<WordPuzzle> _wordPuzzles = [
    WordPuzzle(word: 'KALEM', hint: 'Yazı yazmak için kullanılır'),
    WordPuzzle(word: 'KITAP', hint: 'Okumak için sayfalar halinde'),
    WordPuzzle(word: 'BILGISAYAR', hint: 'Elektronik hesaplama aracı'),
    WordPuzzle(word: 'TELEFON', hint: 'Uzaktan konuşma aracı'),
    WordPuzzle(word: 'ARABA', hint: 'Yolcu taşıma aracı'),
    WordPuzzle(word: 'EV', hint: 'İnsanların yaşadığı yer'),
    WordPuzzle(word: 'OKUL', hint: 'Eğitim yapılan yer'),
    WordPuzzle(word: 'HOSPITAL', hint: 'Sağlık kurumu'),
    WordPuzzle(word: 'RESTORAN', hint: 'Yemek yenen yer'),
    WordPuzzle(word: 'PARK', hint: 'Yeşil alan, dinlenme yeri'),
  ];

  late WordPuzzle _currentPuzzle;
  String _scrambledWord = '';
  String _userAnswer = '';
  int _currentPuzzleIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  Timer? _gameTimer;
  int _elapsedTime = 0;
  bool _isGameComplete = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGame();
    _startTimer();
  }

  void _initializeAnimations() {
    _letterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _letterScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterAnimationController,
      curve: Curves.elasticOut,
    ));

    _letterAnimationController.forward();
  }

  void _initializeGame() {
    _currentPuzzleIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _elapsedTime = 0;
    _isGameComplete = false;
    _loadCurrentPuzzle();
  }

  void _loadCurrentPuzzle() {
    if (_currentPuzzleIndex < _wordPuzzles.length) {
      _currentPuzzle = _wordPuzzles[_currentPuzzleIndex];
      _scrambledWord = _scrambleWord(_currentPuzzle.word);
      _userAnswer = '';
      _showHint = false;
    } else {
      _endGame();
    }
  }

  String _scrambleWord(String word) {
    final List<String> letters = word.split('');
    letters.shuffle(Random());
    return letters.join();
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

  void _onLetterTap(String letter) {
    if (_isGameComplete) return;

    setState(() {
      _userAnswer += letter;
    });

    if (_userAnswer.length == _currentPuzzle.word.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    if (_userAnswer.toUpperCase() == _currentPuzzle.word) {
      // Doğru cevap
      _correctAnswers++;
      final timeBonus = (60 - _elapsedTime).clamp(0, 30);
      _score += 100 + timeBonus;

      if (_currentPuzzleIndex < _wordPuzzles.length - 1) {
        _nextPuzzle();
      } else {
        _endGame();
      }
    } else {
      // Yanlış cevap
      _showWrongAnswerDialog();
    }
  }

  void _nextPuzzle() {
    setState(() {
      _currentPuzzleIndex++;
      _elapsedTime = 0;
    });
    _loadCurrentPuzzle();
  }

  void _showWrongAnswerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Yanlış Cevap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Doğru kelime: ${_currentPuzzle.word}'),
            const SizedBox(height: 8),
            Text('İpucu: ${_currentPuzzle.hint}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextPuzzle();
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  void _endGame() {
    _isGameComplete = true;
    _gameTimer?.cancel();

    // Bonus puanlar
    final accuracyBonus = (_correctAnswers / _wordPuzzles.length * 100).round();
    _score += accuracyBonus;

    // Profil güncelleme
    final updatedProfile = widget.profile.copyWith(
      points: widget.profile.points + _score,
    );

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
            Text('Kelime karıştırma oyununu tamamladın!'),
            const SizedBox(height: 16),
            _buildResultRow('⏱️ Toplam Süre', '${_elapsedTime} saniye'),
            _buildResultRow(
                '🎯 Doğru Cevap', '$_correctAnswers/${_wordPuzzles.length}'),
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
    _initializeGame();
    _startTimer();
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });
  }

  @override
  void dispose() {
    _letterAnimationController.dispose();
    _gameTimer?.cancel();
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
              Colors.orange.shade900,
              Colors.orange.shade700,
              Colors.orange.shade500,
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
                      // İpucu
                      _buildHintSection(),

                      const SizedBox(height: 24),

                      // Karışık kelime
                      _buildScrambledWord(),

                      const SizedBox(height: 32),

                      // Kullanıcı cevabı
                      _buildUserAnswer(),

                      const SizedBox(height: 32),

                      // Harf butonları
                      Expanded(child: _buildLetterButtons()),
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
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '📝 Kelime Karıştır',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Karışık harflerden kelime oluştur!',
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
          _buildInfoItem('🎯', 'Kelime',
              '${_currentPuzzleIndex + 1}/${_wordPuzzles.length}'),
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

  Widget _buildHintSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '💡 İpucu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _toggleHint,
                icon: Icon(
                  _showHint ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (_showHint)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _currentPuzzle.hint,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrambledWord() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Text(
        _scrambledWord,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 8,
        ),
      ),
    );
  }

  Widget _buildUserAnswer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Cevabın: ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            _userAnswer.isEmpty ? '_____' : _userAnswer,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterButtons() {
    final letters = _scrambledWord.split('');

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        return _buildLetterButton(letters[index]);
      },
    );
  }

  Widget _buildLetterButton(String letter) {
    return ScaleTransition(
      scale: _letterScaleAnimation,
      child: GestureDetector(
        onTap: () => _onLetterTap(letter),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WordPuzzle {
  final String word;
  final String hint;

  WordPuzzle({
    required this.word,
    required this.hint,
  });
}

