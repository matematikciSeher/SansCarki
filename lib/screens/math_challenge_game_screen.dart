import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class MathChallengeGameScreen extends StatefulWidget {
  final UserProfile profile;

  const MathChallengeGameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<MathChallengeGameScreen> createState() => _MathChallengeGameScreenState();
}

class _MathChallengeGameScreenState extends State<MathChallengeGameScreen> with TickerProviderStateMixin {
  late AnimationController _questionAnimationController;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;

  final List<MathQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _score = 0;
  Timer? _gameTimer;
  int _remainingTime = 30;
  bool _isAnswered = false;
  int? _selectedAnswerIndex;
  // bool _isGameComplete = false; // kullanılmıyor
  bool _showInfo = true;

  // Oyun parametreleri
  late int _startTime;

  @override
  void initState() {
    super.initState();
    _initializeGameParams();
    _initializeAnimations();
    _generateQuestions();
    _startTimer();
  }

  void _initializeGameParams() {
    // Süre: 30 sn
    _startTime = 30;
    _remainingTime = _startTime;
  }

  void _initializeAnimations() {
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _questionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeInOut,
    ));

    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeOutBack,
    ));

    _questionAnimationController.forward();
  }

  void _generateQuestions() {
    _questions.clear();
    final random = Random();
    // Bankadan 10 soru seç: en az 2 zor soru
    final hard = _questionBank.where((q) => q.isHard).toList();
    final normal = _questionBank.where((q) => !q.isHard).toList();
    hard.shuffle(random);
    normal.shuffle(random);
    final selected = <_QuestionDef>[];
    selected.addAll(hard.take(2));
    selected.addAll(normal.take(8));
    selected.shuffle(random);
    for (final def in selected) {
      _questions.add(MathQuestion(
        question: def.question,
        options: def.options,
        correctAnswerIndex: def.correctIndex,
      ));
    }
  }

  // Rastgele üretim kaldırıldı – sabit bankadan seçiliyor

  // Zorluk hesaplaması kaldırıldı

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0 && !_isAnswered) {
        setState(() {
          _remainingTime--;
        });
      } else if (_remainingTime <= 0 && !_isAnswered) {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    setState(() {
      _isAnswered = true;
      // Süre doldu: yanlış say ve 10 puan düş
      _score -= 10;
    });

    _showTimeoutDialog();
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Süre Doldu!'),
        content: const Text('Bu soru için süre doldu. Doğru cevap gösteriliyor.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _nextQuestion();
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int answerIndex) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _isAnswered = true;
    });

    _gameTimer?.cancel();

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = answerIndex == currentQuestion.correctAnswerIndex;

    if (isCorrect) {
      _correctAnswers++;
      _score += 10;
    } else {
      _score -= 10;
    }

    _showAnswerResult(isCorrect, currentQuestion);
  }

  // Puanlama fonksiyonu kullanılmıyor
  // int _calculatePoints(MathQuestion question) => 10;

  void _showAnswerResult(bool isCorrect, MathQuestion question) {
    final color = isCorrect ? Colors.green : Colors.red;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final message = isCorrect ? 'Doğru!' : 'Yanlış!';
    final pointsText = isCorrect ? '+10 puan' : '−10 puan';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    pointsText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (mounted) {
        await _nextQuestion();
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswerIndex = null;
        _remainingTime = _startTime;
      });

      // Yeni soru hemen gelsin
      _questionAnimationController.reset();
      _questionAnimationController.forward();
      _startTimer();
    } else {
      await _endGame();
    }
  }

  Future<void> _endGame() async {
    _gameTimer?.cancel();
    // Oyun bitti

    final accuracy = (_correctAnswers / _questions.length) * 100;

    // Bonus puanlar
    final accuracyBonus = accuracy.round();
    _score += accuracyBonus;

    // Önce güncel profili Firestore'dan çek
    UserProfile? currentProfile;
    try {
      currentProfile = await UserService.getCurrentUserProfile();
    } catch (e) {
      print('Güncel profil çekme hatası: $e');
      currentProfile = widget.profile; // Fallback
    }

    // Profil güncelleme - güncel profili kullan
    final updatedProfile = (currentProfile ?? widget.profile).copyWith(
      points: (currentProfile?.points ?? 0) + _score,
      totalGamePoints: ((currentProfile?.totalGamePoints ?? 0)) + _score,
    );

    // UserProfile'ı Firestore'a kaydet
    await _saveProfile(updatedProfile);

    _showGameCompleteDialog(updatedProfile, accuracy);
  }

  Future<void> _saveProfile(UserProfile profile) async {
    try {
      print('🎮 MATH CHALLENGE BİTTİ - Puan kaydediliyor...');
      print('   ✨ Kazanılan Puan: $_score');
      print('   📊 Yeni Oyun Puanı: ${profile.totalGamePoints ?? 0}');

      await UserService.updateCurrentUserProfile(profile);
      print('   ✅ Firestore\'a kaydedildi!');

      // Aktivite logla (opsiyonel)
      await UserService.logActivity(
        activityType: 'math_game_completed',
        data: {
          'score': _score,
          'correctAnswers': _correctAnswers,
          'totalQuestions': _questions.length,
        },
      );
    } catch (e) {
      print('❌ Matematik oyunu profil kaydetme hatası: $e');
    }
  }

  void _showGameCompleteDialog(UserProfile updatedProfile, double accuracy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Matematik mücadelesini tamamladın!'),
            const SizedBox(height: 16),
            _buildResultRow('🎯 Doğru Cevap', '$_correctAnswers/${_questions.length}'),
            _buildResultRow('📊 Doğruluk', '${accuracy.toStringAsFixed(1)}%'),
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
            onPressed: () async {
              Navigator.pop(context);
              // UserProfile'ı SharedPreferences'a kaydet
              await _saveProfile(updatedProfile);
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
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _score = 0;
      _remainingTime = _startTime;
      _isAnswered = false;
      _selectedAnswerIndex = null;
    });

    _generateQuestions();
    _questionAnimationController.reset();
    _questionAnimationController.forward();
    _startTimer();
  }

  @override
  void dispose() {
    _questionAnimationController.dispose();
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
            Colors.purple.shade900,
            Colors.purple.shade700,
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
                  '🔢 Matematik Mücadelesi',
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
                    'Kurallar:\n\n• Her etap 10 sorudan oluşur.\n• Her soru için 30 saniye süren var.\n• Çoktan seçmeli 4 şık arasından doğruyu işaretle.\n• Her etapta en az 2 zor soru bulunur.\n',
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
                    'Puanlama:\n\n• Doğru cevap: +10 puan\n• Yanlış cevap veya süre doldu: −10 puan\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showInfo = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
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
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.purple.shade700,
              Colors.purple.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // İlerleme çubuğu
              _buildProgressBar(),

              // Süre sayacı
              _buildTimer(),

              // Soru
              Expanded(
                child: FadeTransition(
                  opacity: _questionFadeAnimation,
                  child: SlideTransition(
                    position: _questionSlideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Soru kartı
                            _buildQuestionCard(currentQuestion),

                            const SizedBox(height: 24),

                            // Cevap seçenekleri
                            _buildAnswerOptions(currentQuestion),
                          ],
                        ),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '🔢 Matematik Mücadelesi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Hızlı matematik işlemleri yap!',
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

  Widget _buildProgressBar() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              Text(
                '$_correctAnswers doğru',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final color = _remainingTime <= 5 ? Colors.red : Colors.white;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Center(
          child: Text(
            '$_remainingTime',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(MathQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Zorluk rengi kaldırıldı

  Widget _buildAnswerOptions(MathQuestion question) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswerIndex == index;
        final isCorrect = index == question.correctAnswerIndex;
        final showResult = _isAnswered;

        Color backgroundColor = Colors.white.withOpacity(0.1);
        Color borderColor = Colors.white.withOpacity(0.3);

        if (showResult) {
          if (isCorrect) {
            backgroundColor = Colors.green.withOpacity(0.3);
            borderColor = Colors.green;
          } else if (isSelected && !isCorrect) {
            backgroundColor = Colors.red.withOpacity(0.3);
            borderColor = Colors.red;
          }
        } else if (isSelected) {
          backgroundColor = Colors.blue.withOpacity(0.3);
          borderColor = Colors.blue;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            onPressed: showResult ? null : () => _selectAnswer(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 2),
              ),
              elevation: showResult ? 0 : 4,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '$option',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (showResult && isCorrect) const Icon(Icons.check_circle, color: Colors.green),
                if (showResult && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MathQuestion {
  final String question;
  final List<int> options;
  final int correctAnswerIndex;
  final bool isHard;

  MathQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.isHard = false,
  });
}

class _QuestionDef {
  final String question;
  final List<int> options;
  final int correctIndex;
  final bool isHard;

  const _QuestionDef({required this.question, required this.options, required this.correctIndex, this.isHard = false});
}

// Kullanıcıdan gelen sabit soru bankası (örnek ilk bölümden bir kaç tanesi; tamamı eklenecek)
final List<_QuestionDef> _questionBank = [
  _QuestionDef(
    question: '245 + 378 işleminin sonucu kaçtır?',
    options: [513, 623, 633, 643],
    correctIndex: 3,
  ),
  _QuestionDef(
    question: '864 – 279 işleminin sonucu kaçtır?',
    options: [565, 585, 595, 605],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '36 ÷ 6 işleminin sonucu kaçtır?',
    options: [4, 5, 6, 7],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '48 × 7 işleminin sonucu kaçtır?',
    options: [326, 336, 346, 356],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir çiftçi 128 elmayı 8 çocuğa eşit paylaştırıyor. Her çocuk kaç elma alır?',
    options: [14, 15, 16, 18],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '450 + 275 – 120 işleminin sonucu kaçtır?',
    options: [595, 605, 615, 625],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '12’nin 8 katı kaçtır?',
    options: [84, 86, 94, 96],
    correctIndex: 3,
  ),
  _QuestionDef(
    question: '56 ÷ 8 işleminin sonucu kaçtır?',
    options: [6, 7, 8, 9],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '25 × 12 işleminin sonucu kaçtır?',
    options: [300, 310, 320, 330],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: 'Bir kalem 12 TL’dir. 8 kalem kaç TL eder?',
    options: [84, 94, 96, 106],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1024 – 768 işleminin sonucu kaçtır?',
    options: [246, 256, 266, 276],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '45 × 5 işleminin sonucu kaçtır?',
    options: [215, 220, 225, 230],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir otobüste 54 yolcu vardır. 19 yolcu indi, 23 yolcu bindi. Son durumda kaç yolcu vardır?',
    options: [56, 57, 58, 59],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: '72 ÷ 9 işleminin sonucu kaçtır?',
    options: [6, 7, 8, 9],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '15 × 14 işleminin sonucu kaçtır?',
    options: [200, 210, 215, 220],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '360’ın yarısı kaçtır?',
    options: [160, 170, 180, 190],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '84 ÷ 7 işleminin sonucu kaçtır?',
    options: [10, 11, 12, 13],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 12 cm, uzun kenarı 18 cm’dir. Çevresi kaç cm’dir?',
    options: [58, 60, 62, 64],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '9 × 19 işleminin sonucu kaçtır?',
    options: [161, 170, 171, 180],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '420 ÷ 6 işleminin sonucu kaçtır?',
    options: [68, 69, 70, 71],
    correctIndex: 2,
  ),
  // --- EKLENENLER: 81 - 135 ---
  _QuestionDef(
    question: '325 + 478 işleminin sonucu kaçtır?',
    options: [793, 803, 813, 823],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1000 – 675 işleminin sonucu kaçtır?',
    options: [315, 325, 335, 345],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '144 ÷ 9 işleminin sonucu kaçtır?',
    options: [14, 15, 16, 17],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '27 × 25 işleminin sonucu kaçtır?',
    options: [675, 680, 685, 690],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: 'Bir çiftçi 150 yumurtanın 48’ini sattı. Geriye kaç yumurta kaldı?',
    options: [98, 100, 102, 104],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '540 + 365 – 250 işleminin sonucu kaçtır?',
    options: [645, 655, 665, 675],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '22’nin 14 katı kaçtır?',
    options: [306, 308, 310, 312],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '256 ÷ 16 işleminin sonucu kaçtır?',
    options: [14, 15, 16, 17],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '125 × 12 işleminin sonucu kaçtır?',
    options: [1490, 1500, 1510, 1520],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir sınıfta 42 öğrenci vardır. 16’sı kız, gerisi erkek. Erkek öğrenci sayısı kaçtır?',
    options: [24, 25, 26, 27],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '875 – 645 işleminin sonucu kaçtır?',
    options: [220, 225, 230, 235],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '108 ÷ 6 işleminin sonucu kaçtır?',
    options: [16, 17, 18, 19],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '36 × 32 işleminin sonucu kaçtır?',
    options: [1148, 1152, 1156, 1160],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1280 ÷ 20 işleminin sonucu kaçtır?',
    options: [62, 63, 64, 65],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kenarları 14 cm ve 25 cm’dir. Alanı kaçtır?',
    options: [340, 345, 350, 355],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '85 × 14 işleminin sonucu kaçtır?',
    options: [1180, 1190, 1195, 1200],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '540 + 275 – 390 işleminin sonucu kaçtır?',
    options: [420, 425, 430, 435],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '990 – 865 işleminin sonucu kaçtır?',
    options: [115, 120, 125, 130],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '65 × 18 işleminin sonucu kaçtır?',
    options: [1160, 1170, 1175, 1180],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir okulda 240 öğrenci vardır. 85’i sabahçı, kalanı öğlenci. Öğlenci sayısı kaçtır?',
    options: [145, 150, 155, 160],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '625 ÷ 25 işleminin sonucu kaçtır?',
    options: [23, 24, 25, 26],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '45 × 35 işleminin sonucu kaçtır?',
    options: [1565, 1570, 1575, 1580],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '315 + 480 işleminin sonucu kaçtır?',
    options: [785, 790, 795, 800],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir karenin kenarı 22 cm’dir. Çevresi kaçtır?',
    options: [86, 88, 90, 92],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '324 ÷ 18 işleminin sonucu kaçtır?',
    options: [16, 17, 18, 19],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '72 × 19 işleminin sonucu kaçtır?',
    options: [1358, 1362, 1368, 1372],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1600 – 975 işleminin sonucu kaçtır?',
    options: [615, 620, 625, 630],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '84 ÷ 4 işleminin sonucu kaçtır?',
    options: [20, 21, 22, 23],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir üçgenin kenarları 7 cm, 24 cm ve 25 cm’dir. Çevresi kaçtır?',
    options: [54, 55, 56, 57],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '99 × 12 işleminin sonucu kaçtır?',
    options: [1178, 1188, 1198, 1208],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '475 + 425 işleminin sonucu kaçtır?',
    options: [895, 900, 905, 910],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '960 ÷ 30 işleminin sonucu kaçtır?',
    options: [30, 31, 32, 33],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '24 × 27 işleminin sonucu kaçtır?',
    options: [645, 648, 651, 654],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kenarları 16 cm ve 28 cm’dir. Çevresi kaçtır?',
    options: [86, 88, 90, 92],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1750 – 925 işleminin sonucu kaçtır?',
    options: [815, 820, 825, 830],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '128 × 8 işleminin sonucu kaçtır?',
    options: [1018, 1024, 1032, 1040],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '420 ÷ 7 işleminin sonucu kaçtır?',
    options: [58, 59, 60, 61],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir sınıfta 54 öğrenci vardır. 18 öğrenci başka okula gider, yerine 25 öğrenci gelir. Kaç öğrenci olur?',
    options: [60, 61, 62, 63],
    correctIndex: 3,
  ),
  // Zor problemler
  _QuestionDef(
    question: 'Bir işçi bir işi 12 günde bitirebiliyor. Aynı işten 3 işçi birlikte çalışırsa iş kaç günde biter?',
    options: [3, 4, 5, 6],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question:
        'Bir dikdörtgenin uzun kenarı kısa kenarının 3 katıdır. Çevresi 64 cm olduğuna göre kısa kenar kaç cm’dir?',
    options: [7, 8, 9, 10],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '480 + 275 işleminin sonucu kaçtır?',
    options: [745, 755, 765, 775],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '900 – 325 işleminin sonucu kaçtır?',
    options: [565, 575, 585, 595],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '72 ÷ 9 işleminin sonucu kaçtır?',
    options: [6, 7, 8, 9],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '36 × 14 işleminin sonucu kaçtır?',
    options: [484, 496, 504, 514],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir çiftçi 256 elmayı torbalara koyuyor. Her torbada 16 elma olacaksa kaç torba gerekir?',
    options: [12, 14, 15, 16],
    correctIndex: 3,
  ),
  // 🟥 Zor Sorular (126–130)
  _QuestionDef(
    question: 'Bir tren saatte 90 km hızla gidiyor. 4 saat 20 dakikada kaç km yol alır?',
    options: [380, 390, 400, 410],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin uzun kenarı 45 cm, kısa kenarı 27 cm’dir. Çevresi kaç cm’dir?',
    options: [138, 140, 144, 150],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir kitap 480 sayfadır. Ali günde 24 sayfa okursa kitabı kaç günde bitirir?',
    options: [18, 19, 20, 21],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir market 12 kg pirinci 144 TL’ye satıyor. 5 kg pirincin fiyatı kaç TL olur?',
    options: [55, 58, 60, 62],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir dik üçgenin dik kenarları 9 cm ve 12 cm’dir. Hipotenüs uzunluğu kaç cm’dir?',
    options: [14, 15, 16, 17],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '735 + 268 – 415 işleminin sonucu kaçtır?',
    options: [578, 588, 598, 608],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '540 ÷ 15 işleminin sonucu kaçtır?',
    options: [34, 35, 36, 37],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '64 × 25 işleminin sonucu kaçtır?',
    options: [1500, 1550, 1600, 1650],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir kenarı 18 cm olan karenin çevresi kaç cm’dir?',
    options: [68, 70, 72, 74],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir otobüste 45 yolcu vardır. 12 yolcu inip 23 yolcu binerse otobüste kaç yolcu olur?',
    options: [54, 55, 56, 57],
    correctIndex: 3,
  ),
  // ... Kullanıcının gönderdiği tüm sorular aynı formatta eklenebilir
  _QuestionDef(
    question: 'Bir manav, 3 kasa elmayı 8 TL’den, 5 kasa armudu 12 TL’den satıyor. Manav toplamda kaç TL kazanır?',
    options: [81, 82, 83, 84],
    correctIndex: 3,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir tren 120 m uzunlukta ve saatte 60 km hızla gidiyor. 300 m köprüyü kaç saniyede tamamen geçer?',
    options: [24, 25, 26, 27],
    correctIndex: 0,
    isHard: true,
  ),
  // --- EKLENENLER: 321 - 400 ---
  _QuestionDef(
    question: '650 + 385 işleminin sonucu kaçtır?',
    options: [1030, 1035, 1040, 1045],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '980 – 465 işleminin sonucu kaçtır?',
    options: [505, 515, 525, 535],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '180 ÷ 9 işleminin sonucu kaçtır?',
    options: [19, 20, 21, 22],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '72 × 23 işleminin sonucu kaçtır?',
    options: [1640, 1650, 1656, 1660],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir kenarı 26 cm olan karenin çevresi kaç cm’dir?',
    options: [100, 102, 104, 106],
    correctIndex: 2,
  ),
  // 🟥 Zor Sorular (326–330)
  _QuestionDef(
    question:
        'Bir işçi günde 7 saat çalışarak 21 günde bir işi bitiriyor. Aynı işi günde 9 saat çalışan işçi kaç günde tamamlar?',
    options: [16, 17, 18, 19],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 15 cm, uzun kenarı kısa kenarın 3 katıdır. Alanı kaç cm²’dir?',
    options: [675, 680, 690, 700],
    correctIndex: 0,
    isHard: true,
  ),
  _QuestionDef(
    question: '540 metre uzunluğundaki bir yol, 30 metre uzunluğunda bölümlere ayrılırsa kaç bölüm oluşur?',
    options: [17, 18, 19, 20],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir havuz 24 m uzunluğunda, 12 m genişliğinde ve 2 m derinliğindedir. Hacmi kaç m³’tür?',
    options: [550, 560, 576, 580],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: '20 günde bir işi bitiren işçi, 4 işçi birlikte çalışırsa kaç günde işi tamamlar?',
    options: [4, 5, 6, 7],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '720 + 285 işleminin sonucu kaçtır?',
    options: [1000, 1005, 1010, 1015],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '950 – 465 işleminin sonucu kaçtır?',
    options: [475, 485, 495, 505],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '360 ÷ 12 işleminin sonucu kaçtır?',
    options: [29, 30, 31, 32],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '64 × 28 işleminin sonucu kaçtır?',
    options: [1790, 1792, 1796, 1800],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 18 cm, uzun kenarı 40 cm’dir. Çevresi kaç cm’dir?',
    options: [112, 116, 118, 120],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '640 + 395 işleminin sonucu kaçtır?',
    options: [1030, 1035, 1040, 1045],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1020 – 485 işleminin sonucu kaçtır?',
    options: [525, 535, 545, 555],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '144 ÷ 12 işleminin sonucu kaçtır?',
    options: [11, 12, 13, 14],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '54 × 20 işleminin sonucu kaçtır?',
    options: [1060, 1080, 1085, 1090],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Çapı 14 cm olan bir dairenin yarıçapı kaç cm’dir?',
    options: [6, 7, 8, 9],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '720 + 345 işleminin sonucu kaçtır?',
    options: [1060, 1065, 1070, 1075],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '840 – 395 işleminin sonucu kaçtır?',
    options: [445, 455, 465, 475],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: '270 ÷ 15 işleminin sonucu kaçtır?',
    options: [16, 17, 18, 19],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '84 × 17 işleminin sonucu kaçtır?',
    options: [1420, 1425, 1428, 1430],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir kenarı 18 cm olan karenin alanı kaç cm²’dir?',
    options: [320, 324, 326, 328],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '640 + 325 işleminin sonucu kaçtır?',
    options: [960, 965, 970, 975],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1200 – 785 işleminin sonucu kaçtır?',
    options: [405, 415, 425, 435],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '360 ÷ 18 işleminin sonucu kaçtır?',
    options: [18, 19, 20, 21],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '72 × 19 işleminin sonucu kaçtır?',
    options: [1360, 1365, 1368, 1370],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 16 cm, uzun kenarı 36 cm’dir. Çevresi kaç cm’dir?',
    options: [100, 102, 104, 106],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '880 + 145 işleminin sonucu kaçtır?',
    options: [1015, 1020, 1025, 1030],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1020 – 465 işleminin sonucu kaçtır?',
    options: [545, 555, 565, 575],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '600 ÷ 20 işleminin sonucu kaçtır?',
    options: [28, 29, 30, 31],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '92 × 15 işleminin sonucu kaçtır?',
    options: [1370, 1380, 1385, 1390],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir kenarı 14 cm olan karenin çevresi kaç cm’dir?',
    options: [54, 56, 58, 60],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '750 + 365 işleminin sonucu kaçtır?',
    options: [1110, 1115, 1120, 1125],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '890 – 275 işleminin sonucu kaçtır?',
    options: [605, 615, 625, 635],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '144 ÷ 6 işleminin sonucu kaçtır?',
    options: [22, 23, 24, 25],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '68 × 26 işleminin sonucu kaçtır?',
    options: [1760, 1765, 1768, 1770],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir dik üçgenin dik kenarları 6 cm ve 8 cm’dir. Hipotenüs uzunluğu kaç cm’dir?',
    options: [9, 10, 11, 12],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '750 + 285 işleminin sonucu kaçtır?',
    options: [1030, 1035, 1040, 1045],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '980 – 475 işleminin sonucu kaçtır?',
    options: [495, 505, 515, 525],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '180 ÷ 10 işleminin sonucu kaçtır?',
    options: [17, 18, 19, 20],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '72 × 24 işleminin sonucu kaçtır?',
    options: [1700, 1720, 1728, 1730],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir kenarı 28 cm olan karenin çevresi kaç cm’dir?',
    options: [108, 110, 112, 114],
    correctIndex: 2,
  ),
  // 🟥 Zor Sorular (366–370)
  _QuestionDef(
    question:
        'Bir işçi günde 8 saat çalışarak 24 günde bir işi bitiriyor. Aynı işi günde 12 saat çalışan işçi kaç günde tamamlar?',
    options: [14, 15, 16, 17],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 16 cm, uzun kenarı kısa kenarın 2,5 katıdır. Alanı kaç cm²’dir?',
    options: [640, 650, 660, 670],
    correctIndex: 0,
    isHard: true,
  ),
  _QuestionDef(
    question: '600 metre uzunluğundaki bir yol 25 metre uzunluğundaki bölümlere ayrılırsa kaç bölüm oluşur?',
    options: [23, 24, 25, 26],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: 'Bir havuz 30 m uzunluğunda, 10 m genişliğinde ve 2 m derinliğindedir. Hacmi kaç m³’tür?',
    options: [580, 600, 620, 640],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '30 günde bir işi bitiren işçi, 5 işçi birlikte çalışırsa kaç günde işi tamamlar?',
    options: [5, 6, 7, 8],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '720 + 295 işleminin sonucu kaçtır?',
    options: [1010, 1015, 1020, 1025],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '950 – 465 işleminin sonucu kaçtır?',
    options: [475, 485, 495, 505],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '360 ÷ 12 işleminin sonucu kaçtır?',
    options: [29, 30, 31, 32],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '64 × 29 işleminin sonucu kaçtır?',
    options: [1850, 1856, 1860, 1865],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 18 cm, uzun kenarı 42 cm’dir. Çevresi kaç cm’dir?',
    options: [116, 120, 124, 126],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '640 + 405 işleminin sonucu kaçtır?',
    options: [1040, 1045, 1050, 1055],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1020 – 495 işleminin sonucu kaçtır?',
    options: [525, 535, 545, 555],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: '144 ÷ 12 işleminin sonucu kaçtır?',
    options: [11, 12, 13, 14],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '54 × 21 işleminin sonucu kaçtır?',
    options: [1130, 1134, 1136, 1140],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Çapı 16 cm olan bir dairenin yarıçapı kaç cm’dir?',
    options: [7, 8, 9, 10],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '720 + 355 işleminin sonucu kaçtır?',
    options: [1070, 1075, 1080, 1085],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '840 – 395 işleminin sonucu kaçtır?',
    options: [445, 455, 465, 475],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: '270 ÷ 15 işleminin sonucu kaçtır?',
    options: [16, 17, 18, 19],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '84 × 18 işleminin sonucu kaçtır?',
    options: [1510, 1512, 1515, 1520],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir kenarı 18 cm olan karenin alanı kaç cm²’dir?',
    options: [320, 324, 326, 328],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '640 + 345 işleminin sonucu kaçtır?',
    options: [980, 985, 990, 995],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1200 – 795 işleminin sonucu kaçtır?',
    options: [405, 405, 405, 405],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: '360 ÷ 18 işleminin sonucu kaçtır?',
    options: [18, 19, 20, 21],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '72 × 20 işleminin sonucu kaçtır?',
    options: [1400, 1440, 1445, 1450],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 16 cm, uzun kenarı 38 cm’dir. Çevresi kaç cm’dir?',
    options: [104, 108, 110, 112],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '880 + 155 işleminin sonucu kaçtır?',
    options: [1030, 1035, 1040, 1045],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1020 – 475 işleminin sonucu kaçtır?',
    options: [535, 545, 555, 565],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '600 ÷ 20 işleminin sonucu kaçtır?',
    options: [28, 29, 30, 31],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '92 × 16 işleminin sonucu kaçtır?',
    options: [1470, 1472, 1475, 1480],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir kenarı 14 cm olan karenin çevresi kaç cm’dir?',
    options: [54, 56, 58, 60],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '750 + 375 işleminin sonucu kaçtır?',
    options: [1110, 1120, 1125, 1130],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '890 – 285 işleminin sonucu kaçtır?',
    options: [605, 605, 605, 605],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: '144 ÷ 6 işleminin sonucu kaçtır?',
    options: [22, 23, 24, 25],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '68 × 27 işleminin sonucu kaçtır?',
    options: [1830, 1836, 1840, 1845],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir dik üçgenin dik kenarları 6 cm ve 8 cm’dir. Hipotenüs uzunluğu kaç cm’dir?',
    options: [9, 10, 11, 12],
    correctIndex: 1,
  ),
  // --- EKLENENLER: +100 Soru (rastgele havuza) ---
  _QuestionDef(
    question: '540 + 260 işleminin sonucu kaçtır?',
    options: [790, 800, 810, 820],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '930 – 245 işleminin sonucu kaçtır?',
    options: [675, 685, 695, 705],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '96 ÷ 12 işleminin sonucu kaçtır?',
    options: [6, 7, 8, 9],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '45 × 18 işleminin sonucu kaçtır?',
    options: [800, 810, 820, 830],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir kenarı 12 cm olan karenin çevresi kaç cm’dir?',
    options: [44, 46, 48, 50],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '720 + 180 işleminin sonucu kaçtır?',
    options: [880, 890, 900, 910],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '840 – 325 işleminin sonucu kaçtır?',
    options: [505, 515, 525, 535],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '144 ÷ 16 işleminin sonucu kaçtır?',
    options: [7, 8, 9, 10],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '36 × 22 işleminin sonucu kaçtır?',
    options: [780, 792, 800, 804],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Kısa kenarı 14 cm, uzun kenarı 20 cm olan dikdörtgenin alanı kaç cm²’dir?',
    options: [260, 270, 280, 290],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir işçi günde 8 saat çalışarak 18 günde işi bitiriyor. Günde 12 saat çalışan işçi kaç günde bitirir?',
    options: [10, 12, 14, 16],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '560 + 375 işleminin sonucu kaçtır?',
    options: [925, 935, 945, 955],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '1000 – 485 işleminin sonucu kaçtır?',
    options: [495, 505, 515, 525],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '180 ÷ 15 işleminin sonucu kaçtır?',
    options: [10, 11, 12, 13],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '64 × 18 işleminin sonucu kaçtır?',
    options: [1140, 1152, 1160, 1168],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Çapı 18 cm olan dairenin yarıçapı kaç cm’dir?',
    options: [7, 8, 9, 10],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '680 + 245 işleminin sonucu kaçtır?',
    options: [915, 920, 925, 930],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '960 – 525 işleminin sonucu kaçtır?',
    options: [425, 435, 445, 455],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '250 ÷ 10 işleminin sonucu kaçtır?',
    options: [20, 25, 30, 35],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '72 × 14 işleminin sonucu kaçtır?',
    options: [996, 1000, 1008, 1012],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Dik kenarları 9 cm ve 12 cm olan dik üçgende hipotenüs uzunluğu kaç cm’dir?',
    options: [14, 15, 16, 17],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '750 + 320 işleminin sonucu kaçtır?',
    options: [1060, 1065, 1070, 1075],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '880 – 465 işleminin sonucu kaçtır?',
    options: [405, 415, 425, 435],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '360 ÷ 24 işleminin sonucu kaçtır?',
    options: [14, 15, 16, 17],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '75 × 16 işleminin sonucu kaçtır?',
    options: [1180, 1190, 1200, 1210],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir kenarı 22 cm olan karenin alanı kaç cm²’dir?',
    options: [472, 480, 484, 488],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '540 + 415 işleminin sonucu kaçtır?',
    options: [945, 950, 955, 960],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1020 – 575 işleminin sonucu kaçtır?',
    options: [435, 445, 455, 465],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '600 ÷ 25 işleminin sonucu kaçtır?',
    options: [22, 23, 24, 25],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '92 × 12 işleminin sonucu kaçtır?',
    options: [1096, 1100, 1104, 1112],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '12 km uzunluğundaki bir yol, 400 m’lik parçalara bölünürse kaç parça olur?',
    options: [28, 29, 30, 31],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: '720 + 415 işleminin sonucu kaçtır?',
    options: [1125, 1130, 1135, 1140],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '950 – 345 işleminin sonucu kaçtır?',
    options: [595, 605, 615, 625],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '180 ÷ 9 işleminin sonucu kaçtır?',
    options: [18, 19, 20, 21],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '84 × 19 işleminin sonucu kaçtır?',
    options: [1584, 1590, 1596, 1600],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Kısa kenarı 18 cm, uzun kenarı 27 cm olan dikdörtgenin çevresi kaç cm’dir?',
    options: [84, 88, 90, 92],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '640 + 455 işleminin sonucu kaçtır?',
    options: [1085, 1090, 1095, 1100],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1020 – 640 işleminin sonucu kaçtır?',
    options: [370, 380, 390, 400],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '600 ÷ 15 işleminin sonucu kaçtır?',
    options: [35, 36, 40, 45],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '72 × 21 işleminin sonucu kaçtır?',
    options: [1500, 1512, 1520, 1524],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir işçi bir işi 15 günde bitiriyor. 3 işçi birlikte çalışırsa kaç günde biter?',
    options: [4, 5, 6, 7],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '880 + 225 işleminin sonucu kaçtır?',
    options: [1095, 1100, 1105, 1110],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1020 – 735 işleminin sonucu kaçtır?',
    options: [275, 280, 285, 290],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '360 ÷ 9 işleminin sonucu kaçtır?',
    options: [38, 39, 40, 41],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '64 × 24 işleminin sonucu kaçtır?',
    options: [1520, 1536, 1540, 1544],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Çapı 22 cm olan dairenin yarıçapı kaç cm’dir?',
    options: [9, 10, 11, 12],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '750 + 365 işleminin sonucu kaçtır?',
    options: [1110, 1115, 1120, 1125],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '890 – 315 işleminin sonucu kaçtır?',
    options: [555, 565, 575, 585],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '144 ÷ 18 işleminin sonucu kaçtır?',
    options: [6, 7, 8, 9],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '56 × 22 işleminin sonucu kaçtır?',
    options: [1220, 1232, 1240, 1244],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '36 km uzunluğundaki bir yol, 600 m’lik parçalara ayrılırsa kaç parça oluşur?',
    options: [55, 58, 60, 62],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: '930 + 145 işleminin sonucu kaçtır?',
    options: [1065, 1070, 1075, 1080],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '970 – 625 işleminin sonucu kaçtır?',
    options: [335, 345, 355, 365],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '180 ÷ 6 işleminin sonucu kaçtır?',
    options: [28, 30, 32, 34],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '92 × 22 işleminin sonucu kaçtır?',
    options: [2000, 2016, 2024, 2032],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Kısa kenarı 22 cm, uzun kenarı 35 cm olan dikdörtgenin çevresi kaç cm’dir?',
    options: [110, 112, 114, 116],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '680 + 415 işleminin sonucu kaçtır?',
    options: [1085, 1090, 1095, 1100],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '960 – 285 işleminin sonucu kaçtır?',
    options: [665, 675, 685, 695],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '250 ÷ 5 işleminin sonucu kaçtır?',
    options: [40, 45, 50, 55],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '72 × 26 işleminin sonucu kaçtır?',
    options: [1860, 1872, 1880, 1890],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir işi 12 günde bitiren 4 işçi aynı hızla birlikte çalışırsa kaç günde bitirir?',
    options: [2, 3, 4, 5],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '710 + 385 işleminin sonucu kaçtır?',
    options: [1085, 1090, 1095, 1100],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '920 – 475 işleminin sonucu kaçtır?',
    options: [435, 445, 455, 465],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '360 ÷ 30 işleminin sonucu kaçtır?',
    options: [10, 11, 12, 13],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '84 × 14 işleminin sonucu kaçtır?',
    options: [1160, 1170, 1176, 1184],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Çevresi 64 cm olan karenin bir kenarı kaç cm’dir?',
    options: [14, 15, 16, 17],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '640 + 465 işleminin sonucu kaçtır?',
    options: [1095, 1100, 1105, 1110],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1020 – 345 işleminin sonucu kaçtır?',
    options: [665, 675, 685, 695],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '600 ÷ 24 işleminin sonucu kaçtır?',
    options: [20, 24, 25, 30],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '56 × 24 işleminin sonucu kaçtır?',
    options: [1332, 1340, 1344, 1350],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Bir tren saatte 72 km hızla 2,5 saatte kaç km yol alır?',
    options: [160, 170, 180, 190],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: '540 + 365 işleminin sonucu kaçtır?',
    options: [895, 905, 915, 925],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '900 – 485 işleminin sonucu kaçtır?',
    options: [405, 415, 425, 435],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '200 ÷ 25 işleminin sonucu kaçtır?',
    options: [6, 7, 8, 9],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '48 × 26 işleminin sonucu kaçtır?',
    options: [1240, 1244, 1248, 1252],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: 'Kısa kenarı 17 cm, uzun kenarı 23 cm olan dikdörtgenin alanı kaç cm²’dir?',
    options: [380, 384, 391, 396],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '720 + 275 işleminin sonucu kaçtır?',
    options: [990, 995, 1000, 1005],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '860 – 315 işleminin sonucu kaçtır?',
    options: [535, 545, 555, 565],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '300 ÷ 12 işleminin sonucu kaçtır?',
    options: [24, 25, 26, 27],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '75 × 14 işleminin sonucu kaçtır?',
    options: [1040, 1045, 1050, 1055],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '20 m × 10 m taban ve 2 m derinlikte havuzun hacmi kaç m³’tür?',
    options: [380, 390, 400, 410],
    correctIndex: 2,
    isHard: true,
  ),
  _QuestionDef(
    question: '660 + 340 işleminin sonucu kaçtır?',
    options: [990, 1000, 1010, 1020],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '920 – 285 işleminin sonucu kaçtır?',
    options: [625, 635, 645, 655],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '144 ÷ 8 işleminin sonucu kaçtır?',
    options: [16, 17, 18, 19],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '96 × 12 işleminin sonucu kaçtır?',
    options: [1148, 1152, 1156, 1160],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: 'Bir kenarı 16 cm olan karenin alanı kaç cm²’dir?',
    options: [246, 252, 256, 260],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '570 + 430 işleminin sonucu kaçtır?',
    options: [990, 995, 1000, 1005],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1150 – 675 işleminin sonucu kaçtır?',
    options: [445, 465, 475, 485],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '420 ÷ 14 işleminin sonucu kaçtır?',
    options: [28, 29, 30, 31],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '65 × 17 işleminin sonucu kaçtır?',
    options: [1095, 1100, 1105, 1110],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '600 m uzunluğundaki yol 20 m’lik bölümlere ayrılırsa kaç bölüm oluşur?',
    options: [25, 30, 35, 40],
    correctIndex: 1,
    isHard: true,
  ),
  _QuestionDef(
    question: '480 + 340 işleminin sonucu kaçtır?',
    options: [820, 830, 840, 850],
    correctIndex: 0,
  ),
  _QuestionDef(
    question: '760 – 285 işleminin sonucu kaçtır?',
    options: [465, 475, 485, 495],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '360 ÷ 20 işleminin sonucu kaçtır?',
    options: [16, 17, 18, 19],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '68 × 14 işleminin sonucu kaçtır?',
    options: [940, 944, 948, 952],
    correctIndex: 3,
  ),
  _QuestionDef(
    question: 'Bir dikdörtgenin kısa kenarı 19 cm, uzun kenarı 33 cm’dir. Çevresi kaç cm’dir?',
    options: [100, 102, 104, 106],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '530 + 470 işleminin sonucu kaçtır?',
    options: [990, 995, 1000, 1005],
    correctIndex: 2,
  ),
  _QuestionDef(
    question: '1300 – 865 işleminin sonucu kaçtır?',
    options: [425, 435, 445, 455],
    correctIndex: 1,
  ),
  _QuestionDef(
    question: '225 ÷ 9 işleminin sonucu kaçtır?',
    options: [20, 22, 24, 25],
    correctIndex: 3,
  ),
  _QuestionDef(
    question: '88 × 12 işleminin sonucu kaçtır?',
    options: [1048, 1052, 1056, 1060],
    correctIndex: 2,
  ),
];
