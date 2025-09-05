import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../models/user_profile.dart';
import '../models/quiz.dart';
import '../data/quiz_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizGameScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final UserProfile profile;

  const QuizGameScreen({
    super.key,
    required this.questions,
    required this.profile,
  });

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionAnimationController;
  late AnimationController _timerAnimationController;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _timerScaleAnimation;

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _totalPoints = 0;
  int _timeSpent = 0;
  bool _isAnswered = false;
  int? _selectedAnswerIndex;
  Timer? _timer;
  int _remainingTime = 30;
  // bool _isGameOver = false; // kaldırıldı

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestions();
    _startTimer();
  }

  void _initializeAnimations() {
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _timerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _timerScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _timerAnimationController,
      curve: Curves.elasticOut,
    ));

    _questionAnimationController.forward();
  }

  void _loadQuestions() {
    _questions = List<QuizQuestion>.from(widget.questions);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0 && !_isAnswered) {
        setState(() {
          _remainingTime--;
          _timeSpent++;
        });
        if (_remainingTime <= 5) {
          _timerAnimationController.repeat(reverse: true);
        }
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

    _timer?.cancel();

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = answerIndex == currentQuestion.correctAnswerIndex;

    if (isCorrect) {
      _correctAnswers++;
      _totalPoints += _calculatePoints(currentQuestion);
    }

    _showAnswerResult(isCorrect, currentQuestion);
  }

  int _calculatePoints(QuizQuestion question) {
    int basePoints = question.basePoints;
    int timeBonus = (_remainingTime * 2).clamp(0, 20); // Hız bonusu
    return basePoints + timeBonus;
  }

  void _showAnswerResult(bool isCorrect, QuizQuestion question) {
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

  void _endGame() async {
    _timer?.cancel();
    // setState(() {
    //   _isGameOver = true;
    // });

    final accuracy = (_correctAnswers / _questions.length) * 100;
    final averageTime = _timeSpent / _questions.length;

    // Çözülen soruları solvedQuestionIds'e ekle
    final solvedIds = List<String>.from(widget.profile.solvedQuestionIds);
    for (final q in _questions) {
      if (!solvedIds.contains(q.id)) {
        solvedIds.add(q.id);
      }
    }
    // Eğer tüm sorular çözülmüşse solvedQuestionIds sıfırlanır
    final allQuestions = QuizData.getAllQuestions();
    if (solvedIds.length >= allQuestions.length) {
      solvedIds.clear();
    }

    // Quiz puanlarını UserProfile'a ekle
    final updatedProfile = widget.profile.copyWith(
      totalQuizzes: (widget.profile.totalQuizzes ?? 0) + 1,
      correctQuizAnswers:
          (widget.profile.correctQuizAnswers ?? 0) + _correctAnswers,
      totalQuizPoints: (widget.profile.totalQuizPoints ?? 0) + _totalPoints,
      points: widget.profile.points + _totalPoints, // Ana puan sistemine ekle
      highestQuizScore: widget.profile.highestQuizScore == null ||
              _totalPoints > widget.profile.highestQuizScore!
          ? _totalPoints
          : widget.profile.highestQuizScore,
      quizAccuracy: widget.profile.quizAccuracy == null
          ? accuracy / 100
          : ((widget.profile.quizAccuracy! + accuracy / 100) / 2),
      averageQuizTime: widget.profile.averageQuizTime == null
          ? averageTime.round()
          : ((widget.profile.averageQuizTime! + averageTime.round()) / 2)
              .round(),
      solvedQuestionIds: solvedIds,
    );

    // UserProfile'ı kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(updatedProfile.toJson()));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quiz Tamamlandı! 🎉'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Doğru Cevap: $_correctAnswers/${_questions.length}',
                    softWrap: true),
                Text('Doğruluk: ${accuracy.toStringAsFixed(1)}%',
                    softWrap: true),
                Text('Quiz Puanı: $_totalPoints', softWrap: true),
                Text('Ana Sisteme Eklenen: $_totalPoints', softWrap: true),
                Text('Yeni Toplam Puan: ${updatedProfile.points}',
                    softWrap: true),
                Text('Ortalama Süre: ${averageTime.toStringAsFixed(1)}s',
                    softWrap: true),
                const SizedBox(height: 8),
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
                      Expanded(
                        child: Text(
                          'Quiz puanları ana sisteme eklendi!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, updatedProfile); // güncel profili dön
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartQuiz();
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _totalPoints = 0;
      _timeSpent = 0;
      // _isGameOver = false; // kaldırıldı
      _selectedAnswerIndex = null;
      _isAnswered = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _questionAnimationController.dispose();
    _timerAnimationController.dispose();
    _timer?.cancel();
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  'Quiz',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                Text(
                  'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
              '$_totalPoints puan',
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
      margin: const EdgeInsets.all(12),
      child: ScaleTransition(
        scale: _timerScaleAnimation,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              '$_remainingTime',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(QuizQuestion question) {
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
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 2),
              ),
              elevation: showResult ? 0 : 4,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.left,
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
