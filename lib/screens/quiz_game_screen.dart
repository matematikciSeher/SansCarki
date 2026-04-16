import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_profile.dart';
import '../models/quiz.dart';
// Quiz questions are now provided by caller (e.g., fetched from Firestore)
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quiz_repository.dart';
import '../services/admob_service.dart';
import '../services/user_service.dart';

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

class _QuizGameScreenState extends State<QuizGameScreen> with TickerProviderStateMixin {
  late AnimationController _questionAnimationController;
  late AnimationController _timerAnimationController;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  bool _slideFromRight = true;
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
  final Set<int> _hiddenOptionIndexes = <int>{};
  bool _usedFiftyFiftyForCurrentQuestion = false;
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

    _updateSlideAnimation();

    _timerScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _timerAnimationController,
      curve: Curves.elasticOut,
    ));

    _questionAnimationController.forward();
  }

  void _updateSlideAnimation() {
    // Alternating slide: right->left then left->right
    final begin = _slideFromRight ? const Offset(0.2, 0) : const Offset(-0.2, 0);
    _questionSlideAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _loadQuestions() {
    final all = List<QuizQuestion>.from(widget.questions);
    all.shuffle();
    final desiredCount = all.length >= 10 ? 10 : all.length;
    _questions = all.take(desiredCount).toList();
    _currentQuestionIndex = 0;
  }

  Future<List<String>> _getRecentQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('quiz_recent_ids') ?? <String>[];
  }

  Future<void> _appendRecentQuestionIds(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('quiz_recent_ids') ?? <String>[];
    final set = <String>{...current};
    set.addAll(ids);
    // Son 100 kaydı tut
    final list = set.toList();
    if (list.length > 100) {
      list.removeRange(0, list.length - 100);
    }
    await prefs.setStringList('quiz_recent_ids', list);
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
        content: const Text('Bu soru için süre doldu. Doğru cevap gösteriliyor.'),
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

    // Doğru cevapta kısa bekleme, yanlışta doğru seçeneği görebilmek için daha uzun bekleme
    final delayMs = isCorrect ? 800 : 3000;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      if (isCorrect) {
        _nextQuestion();
      } else {
        _endGame();
      }
    });
  }

  int _calculatePoints(QuizQuestion question) {
    int basePoints = question.basePoints;
    int timeBonus = (_remainingTime * 2).clamp(0, 20); // Hız bonusu
    return basePoints + timeBonus;
  }

  // Önceden cevap sonrası görsel geri bildirim için kullanılıyordu. Artık anında geçiş yapıldığı için kaldırıldı.

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswerIndex = null;
        _remainingTime = 30;
        _slideFromRight = !_slideFromRight;
        _hiddenOptionIndexes.clear();
        _usedFiftyFiftyForCurrentQuestion = false;
      });

      _questionAnimationController.reset();
      _updateSlideAnimation();
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
    // En son oynanan soruları tekrarları azaltmak için sakla
    await _appendRecentQuestionIds(_questions.map((e) => e.id));

    // Eğer tüm havuz çözülmüşse solvedQuestionIds sıfırlanır
    try {
      final all = await QuizRepository.fetchAll();
      final totalBankCount = all.length;
      if (totalBankCount > 0 && solvedIds.length >= totalBankCount) {
        solvedIds.clear();
      }
    } catch (_) {
      // çevrimdışı/erişim hatası: temizleme yapma
    }

    // Önce güncel profili Firestore'dan çek
    UserProfile? currentProfile;
    try {
      currentProfile = await UserService.getCurrentUserProfile();
    } catch (e) {
      print('Güncel profil çekme hatası: $e');
      currentProfile = widget.profile; // Fallback
    }

    // Quiz puanlarını güncel profile ekle
    final baseProfile = currentProfile ?? widget.profile;
    final updatedProfile = baseProfile.copyWith(
      totalQuizzes: (baseProfile.totalQuizzes ?? 0) + 1,
      correctQuizAnswers: (baseProfile.correctQuizAnswers ?? 0) + _correctAnswers,
      totalQuizPoints: (baseProfile.totalQuizPoints ?? 0) + _totalPoints,
      points: baseProfile.points + _totalPoints, // Ana puan sistemine ekle
      highestQuizScore: baseProfile.highestQuizScore == null || _totalPoints > baseProfile.highestQuizScore!
          ? _totalPoints
          : baseProfile.highestQuizScore,
      quizAccuracy:
          baseProfile.quizAccuracy == null ? accuracy / 100 : ((baseProfile.quizAccuracy! + accuracy / 100) / 2),
      averageQuizTime: baseProfile.averageQuizTime == null
          ? averageTime.round()
          : ((baseProfile.averageQuizTime! + averageTime.round()) / 2).round(),
      solvedQuestionIds: solvedIds,
    );

    // UserProfile'ı Firestore'a kaydet
    try {
      print('🎮 QUIZ BİTTİ - Puan kaydediliyor...');
      print('   📊 Eski profil:');
      print('      - Görev: ${baseProfile.points}');
      print('      - Oyun: ${baseProfile.totalGamePoints ?? 0}');
      print('      - Quiz: ${baseProfile.totalQuizPoints ?? 0}');
      print('   ✨ Kazanılan Quiz Puanı: $_totalPoints');
      print('   📊 Yeni profil:');
      print('      - Görev: ${updatedProfile.points}');
      print('      - Oyun: ${updatedProfile.totalGamePoints ?? 0}');
      print('      - Quiz: ${updatedProfile.totalQuizPoints ?? 0}');

      await UserService.updateCurrentUserProfile(updatedProfile);
      print('   ✅ Firestore\'a kaydedildi!');

      // Aktivite logla (opsiyonel)
      await UserService.logActivity(
        activityType: 'quiz_completed',
        data: {
          'points': _totalPoints,
          'correctAnswers': _correctAnswers,
          'totalQuestions': _questions.length,
          'accuracy': accuracy,
        },
      );
    } catch (e) {
      print('❌ Quiz profil kaydetme hatası: $e');
    }

    if (!mounted) return;
    await AdMobService.instance.showQuizInterstitialAdIfAvailable();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade400,
                      Colors.pink.shade400,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '🎉 Quiz Bitti! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Doğru: $_correctAnswers/${_questions.length}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Doğruluk: ${accuracy.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white)),
                          Text('Quiz Puanı: $_totalPoints', style: const TextStyle(color: Colors.white)),
                          Text('Toplam Puan: ${updatedProfile.points}', style: const TextStyle(color: Colors.white)),
                          Text('Ortalama Süre: ${averageTime.toStringAsFixed(1)}s',
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context, updatedProfile);
                            },
                            child: const Text('Ana Menü'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _restartQuiz();
                            },
                            child: const Text('Tekrar Oyna'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.yellow.shade400,
                          Colors.orange.shade400,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.celebration, color: Colors.white, size: 34),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _restartQuiz() async {
    _timer?.cancel();
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _totalPoints = 0;
      _timeSpent = 0;
      // _isGameOver = false; // kaldırıldı
      _selectedAnswerIndex = null;
      _isAnswered = false;
      _remainingTime = 30;
      _hiddenOptionIndexes.clear();
      _usedFiftyFiftyForCurrentQuestion = false;
    });

    final desiredCount = widget.questions.isNotEmpty ? widget.questions.length : 10;
    final recent = await _getRecentQuestionIds();
    final fresh = await QuizRepository.fetchRandom(
      count: desiredCount,
      excludeIds: recent.toSet(),
    );
    if (!mounted) return;

    setState(() {
      _questions = fresh;
    });

    _questionAnimationController.reset();
    _updateSlideAnimation();
    _questionAnimationController.forward();
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 32,
                            ),
                            child: Column(
                              children: [
                                // Soru kartı
                                _buildQuestionCard(currentQuestion),

                                const SizedBox(height: 24),

                                _buildFiftyFiftyCard(currentQuestion),

                                // Cevap seçenekleri
                                _buildAnswerOptions(currentQuestion),
                              ],
                            ),
                          ),
                        );
                      },
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
    final catColor = question.category.color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor.withOpacity(0.35),
            catColor.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: catColor.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  question.category.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  bool _canUseFiftyFifty(QuizQuestion question) {
    if (_isAnswered || _usedFiftyFiftyForCurrentQuestion) return false;
    final wrongIndexes = question.options.asMap().keys.where(
      (index) => index != question.correctAnswerIndex,
    );
    return wrongIndexes.length >= 2;
  }

  Future<void> _watchAdForFiftyFifty(QuizQuestion question) async {
    if (!_canUseFiftyFifty(question)) return;

    if (!AdMobService.instance.isRewardedAdReady(RewardedPlacement.quizFiftyFifty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('50/50 reklami yukleniyor, biraz sonra tekrar dene.'),
        ),
      );
      return;
    }

    final success = await AdMobService.instance.showRewardedAd(
      placement: RewardedPlacement.quizFiftyFifty,
      onRewarded: () {
        final wrongIndexes = question.options.asMap().keys.where(
          (index) => index != question.correctAnswerIndex,
        ).toList()
          ..shuffle();

        if (!mounted) return;
        setState(() {
          _hiddenOptionIndexes
            ..clear()
            ..addAll(wrongIndexes.take(2));
          _usedFiftyFiftyForCurrentQuestion = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('50/50 jokeri aktif. Iki yanlis şık kaldırıldı.'),
          ),
        );
      },
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam tamamlanmadi. 50/50 kullanilamadi.'),
        ),
      );
    }
  }

  Widget _buildFiftyFiftyCard(QuizQuestion question) {
    final adReady =
        AdMobService.instance.isRewardedAdReady(RewardedPlacement.quizFiftyFifty);
    final canUse = _canUseFiftyFifty(question);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '50/50 Jokeri',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _usedFiftyFiftyForCurrentQuestion
                ? 'Bu soruda 50/50 kullanildi.'
                : 'Reklam izle, iki yanlis sik otomatik kalksin.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: (!adReady || !canUse)
                ? null
                : () => _watchAdForFiftyFifty(question),
            icon: const Icon(Icons.smart_display_outlined),
            label: Text(
              adReady ? 'Reklam Izle + 50/50' : 'Reklam Yukleniyor...',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withOpacity(0.15),
              disabledForegroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
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
        if (_hiddenOptionIndexes.contains(index)) {
          return const SizedBox.shrink();
        }
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
