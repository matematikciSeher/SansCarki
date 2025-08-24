import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user_profile.dart';

class MathChallengeGameScreen extends StatefulWidget {
  final UserProfile profile;

  const MathChallengeGameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<MathChallengeGameScreen> createState() =>
      _MathChallengeGameScreenState();
}

class _MathChallengeGameScreenState extends State<MathChallengeGameScreen>
    with TickerProviderStateMixin {
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
  bool _isGameComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateQuestions();
    _startTimer();
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

    for (int i = 0; i < 10; i++) {
      final question = _generateRandomQuestion(random);
      _questions.add(question);
    }
  }

  MathQuestion _generateRandomQuestion(Random random) {
    final operation = random.nextInt(4); // 0: +, 1: -, 2: *, 3: /
    int num1, num2, correctAnswer;
    List<int> options;

    switch (operation) {
      case 0: // Toplama
        num1 = random.nextInt(50) + 10;
        num2 = random.nextInt(50) + 10;
        correctAnswer = num1 + num2;
        break;
      case 1: // Çıkarma
        num1 = random.nextInt(50) + 30;
        num2 = random.nextInt(num1 - 10) + 5;
        correctAnswer = num1 - num2;
        break;
      case 2: // Çarpma
        num1 = random.nextInt(12) + 1;
        num2 = random.nextInt(12) + 1;
        correctAnswer = num1 * num2;
        break;
      case 3: // Bölme
        num2 = random.nextInt(10) + 2;
        correctAnswer = random.nextInt(10) + 1;
        num1 = num2 * correctAnswer;
        break;
      default:
        num1 = 10;
        num2 = 5;
        correctAnswer = 15;
    }

    // Yanlış seçenekler oluştur
    options = [correctAnswer];
    while (options.length < 4) {
      int wrongAnswer;
      switch (operation) {
        case 0: // Toplama
          wrongAnswer = correctAnswer + random.nextInt(10) - 5;
          break;
        case 1: // Çıkarma
          wrongAnswer = correctAnswer + random.nextInt(10) - 5;
          break;
        case 2: // Çarpma
          wrongAnswer = correctAnswer + random.nextInt(8) - 4;
          break;
        case 3: // Bölme
          wrongAnswer = correctAnswer + random.nextInt(6) - 3;
          break;
        default:
          wrongAnswer = correctAnswer + 1;
      }

      if (wrongAnswer != correctAnswer &&
          wrongAnswer > 0 &&
          !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }

    options.shuffle(random);

    String questionText;
    switch (operation) {
      case 0:
        questionText = '$num1 + $num2 = ?';
        break;
      case 1:
        questionText = '$num1 - $num2 = ?';
        break;
      case 2:
        questionText = '$num1 × $num2 = ?';
        break;
      case 3:
        questionText = '$num1 ÷ $num2 = ?';
        break;
      default:
        questionText = '$num1 + $num2 = ?';
    }

    return MathQuestion(
      question: questionText,
      options: options,
      correctAnswerIndex: options.indexOf(correctAnswer),
      difficulty: _getDifficulty(operation, num1, num2),
    );
  }

  String _getDifficulty(int operation, int num1, int num2) {
    if (operation <= 1) {
      // Toplama/Çıkarma
      if (num1 < 20 && num2 < 20) return 'Kolay';
      if (num1 < 40 && num2 < 40) return 'Orta';
      return 'Zor';
    } else {
      // Çarpma/Bölme
      if (num1 <= 6 && num2 <= 6) return 'Kolay';
      if (num1 <= 10 && num2 <= 10) return 'Orta';
      return 'Zor';
    }
  }

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
    });

    _showTimeoutDialog();
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Süre Doldu!'),
        content:
            const Text('Bu soru için süre doldu. Doğru cevap gösteriliyor.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
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
      _score += _calculatePoints(currentQuestion);
    }

    _showAnswerResult(isCorrect, currentQuestion);
  }

  int _calculatePoints(MathQuestion question) {
    int basePoints = 100;
    int timeBonus = (_remainingTime * 3).clamp(0, 30);

    // Zorluk bonusu
    int difficultyBonus = 0;
    switch (question.difficulty) {
      case 'Kolay':
        difficultyBonus = 0;
        break;
      case 'Orta':
        difficultyBonus = 20;
        break;
      case 'Zor':
        difficultyBonus = 50;
        break;
    }

    return basePoints + timeBonus + difficultyBonus;
  }

  void _showAnswerResult(bool isCorrect, MathQuestion question) {
    final color = isCorrect ? Colors.green : Colors.red;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final message = isCorrect ? 'Doğru!' : 'Yanlış!';
    final points = isCorrect ? _calculatePoints(question) : 0;

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
                  if (isCorrect)
                    Text(
                      '+$points puan',
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

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswerIndex = null;
        _remainingTime = 30;
      });

      _questionAnimationController.reset();
      _questionAnimationController.forward();
      _startTimer();
    } else {
      _endGame();
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _isGameComplete = true;
    });

    final accuracy = (_correctAnswers / _questions.length) * 100;

    // Bonus puanlar
    final accuracyBonus = accuracy.round();
    _score += accuracyBonus;

    // Profil güncelleme
    final updatedProfile = widget.profile.copyWith(
      points: widget.profile.points + _score,
    );

    _showGameCompleteDialog(updatedProfile, accuracy);
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
            _buildResultRow(
                '🎯 Doğru Cevap', '$_correctAnswers/${_questions.length}'),
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
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _score = 0;
      _remainingTime = 30;
      _isAnswered = false;
      _selectedAnswerIndex = null;
      _isGameComplete = false;
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
                      child: Column(
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getDifficultyColor(question.difficulty).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.difficulty,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getDifficultyColor(question.difficulty),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Kolay':
        return Colors.green;
      case 'Orta':
        return Colors.orange;
      case 'Zor':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

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
                if (showResult && isCorrect)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (showResult && isSelected && !isCorrect)
                  const Icon(Icons.cancel, color: Colors.red),
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
  final String difficulty;

  MathQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.difficulty,
  });
}

