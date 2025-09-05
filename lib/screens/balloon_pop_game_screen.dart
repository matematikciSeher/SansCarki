import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Balloon {
  final int id;
  final Color color;
  double x;
  double y;
  bool isTarget;
  bool isTrap;
  bool isPopped;
  double lifeTime; // Balonun yaşam süresi (saniye)
  double maxLifeTime; // Balonun maksimum yaşam süresi

  Balloon({
    required this.id,
    required this.color,
    required this.x,
    required this.y,
    this.isTarget = false,
    this.isTrap = false,
    this.isPopped = false,
    required this.maxLifeTime,
  }) : lifeTime = 0.0;
}

class BalloonPopGameScreen extends StatefulWidget {
  final UserProfile profile;
  const BalloonPopGameScreen({super.key, required this.profile});

  @override
  State<BalloonPopGameScreen> createState() => _BalloonPopGameScreenState();
}

class _BalloonPopGameScreenState extends State<BalloonPopGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Balloon> _balloons;
  int _score = 0;
  int _combo = 0;
  int _level = 1;
  int _targetColorIndex = 0;
  int _poppedTargetCount = 0;
  int _missedCount = 0;
  bool _isGameActive = false;
  bool _showInfo = true;
  late Color _targetColor;
  late List<Color> _colorPalette;
  late String _missionText;
  Random _random = Random();
  int _maxLevel = 5;
  int _totalPoppedBalloons = 0;
  int _totalScore = 0;
  int _timeLeft = 40; // 40 saniye süre
  Timer? _timer;
  Timer? _speedIncreaseTimer;
  double _currentSpeedMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _colorPalette = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    _startLevel();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50), // Daha sık güncelleme
    )..addListener(_updateBalloons);
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
      _isGameActive = true;
      _timeLeft = 40; // Süreyi sıfırla
      _currentSpeedMultiplier = 1.0; // Hız çarpanını sıfırla
      _controller.repeat();
    });

    // Süre sayacını başlat
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameActive) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 0) {
            _showTimeUpDialog();
            timer.cancel();
          }
        });
      }
    });

    // Her 10 saniyede bir hızı artır
    _speedIncreaseTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isGameActive) {
        setState(() {
          _currentSpeedMultiplier += 0.1; // Hızı %10 artır
        });
      }
    });
  }

  void _showTimeUpDialog() {
    _isGameActive = false;
    _controller.stop();
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Süre Doldu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Puan: $_score'),
            Text('Patlatılan hedef balon: $_poppedTargetCount / 30'),
            if (_combo > 1) Text('Son kombo: $_combo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + _score,
              );
              // UserProfile'ı SharedPreferences'a kaydet
              await _saveProfile(updated);
              Navigator.pop(context, updated);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _level++;
                _score = 0;
                _combo = 0;
                _timeLeft = 40;
              });
              _startLevel();
              _controller.repeat();
            },
            child: const Text('Sonraki Seviye'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _speedIncreaseTimer?.cancel();
    super.dispose();
  }

  void _startLevel() {
    _balloons = [];
    _combo = 0;
    _poppedTargetCount = 0;
    _missedCount = 0;
    _isGameActive = false;
    _targetColorIndex = _random.nextInt(_colorPalette.length);
    _targetColor = _colorPalette[_targetColorIndex];
    if (_level <= 3) {
      _missionText = '30 tane ${_colorName(_targetColor)} balon patlat!';
    } else {
      _missionText = '30 tane ${_colorName(_targetColor)} balon patlat!';
    }
    _spawnInitialBalloons();
  }

  void _spawnInitialBalloons() {
    for (int i = 0; i < 6 + _level; i++) {
      _balloons.add(_createBalloon());
    }
  }

  Balloon _createBalloon() {
    final colorIdx = _random.nextInt(_colorPalette.length);
    final color = _colorPalette[colorIdx];
    final isTarget = colorIdx == _targetColorIndex;
    final isTrap = _level > 3 && _random.nextDouble() < 0.15 && !isTarget;

    // Balon yaşam süresini belirle (3-8 saniye arası)
    double maxLifeTime = 3.0 + _random.nextDouble() * 5.0;

    return Balloon(
      id: _random.nextInt(1000000),
      color: color,
      x: _random.nextDouble(), // 0.0-1.0 arası oran
      y: 0.9 + _random.nextDouble() * 0.1, // 0.9-1.0 arası oran
      isTarget: isTarget,
      isTrap: isTrap,
      maxLifeTime: maxLifeTime,
    );
  }

  void _updateBalloons() {
    if (!_isGameActive) return;
    setState(() {
      for (final balloon in _balloons) {
        if (!balloon.isPopped) {
          // Balon yaşam süresini güncelle
          balloon.lifeTime += 0.05; // 50ms = 0.05 saniye

          // Balon süresi doldu mu kontrol et
          if (balloon.lifeTime >= balloon.maxLifeTime) {
            balloon.isPopped = true;
            if (!balloon.isTarget) {
              _missedCount++;
            }
            continue;
          }

          double speed =
              (0.005 + 0.001 * _level) * _currentSpeedMultiplier; // Hızı artır
          speed = speed.clamp(0.005, 0.018); // Minimum ve maksimum hızı artır
          balloon.y -= speed;
          // Balonlar yukarıda birikmesin, yukarı doğru akarken kaybolsun
          if (balloon.y < -0.1) {
            balloon.isPopped = true;
            if (!balloon.isTarget) {
              _missedCount++;
            }
          }
        }
      }
      _balloons.removeWhere((b) => b.isPopped);

      // Balon sayısını artır - 40 saniyede 30 hedef balon çıkacak şekilde
      double spawnRate = (0.12 + 0.008 * _level) * 1.5; // %50 artır
      spawnRate = spawnRate.clamp(0.10, 0.25);
      if (_random.nextDouble() < spawnRate) {
        _balloons.add(_createBalloon());
      }

      // Hedef balon sayısını kontrol et (sadece bilgi amaçlı)
      int targetCount = 30;
      // if (_poppedTargetCount >= targetCount) {
      //   _showWinDialog(); // Oyun bitmesin, sadece süre dolduğunda bitsin
      // }

      // Oyun sadece süre dolduğunda bitsin, yanlış balon sayısına göre bitmesin
      // int missLimit = 15;
      // if (_missedCount > missLimit) {
      //   _showGameOverDialog();
      // }
    });
  }

  void _popBalloon(Balloon balloon) {
    if (!_isGameActive || balloon.isPopped) return;
    setState(() {
      balloon.isPopped = true;
      if (balloon.isTrap) {
        // Tuzak balon patlatılırsa sadece kombo sıfırlanır, puan düşmez
        _combo = 0;
      } else if (balloon.isTarget) {
        _score += 5 + _combo;
        _combo++;
        _poppedTargetCount++;
        if (_combo % 5 == 0) {
          _score += 10; // Kombo bonusu
        }
      } else {
        // Yanlış balon patlatılırsa sadece kombo sıfırlanır, puan düşmez
        _combo = 0;
        _missedCount++;
      }
    });
  }

  String _colorName(Color color) {
    if (color == Colors.red) return 'kırmızı';
    if (color == Colors.blue) return 'mavi';
    if (color == Colors.green) return 'yeşil';
    if (color == Colors.yellow) return 'sarı';
    if (color == Colors.purple) return 'mor';
    if (color == Colors.orange) return 'turuncu';
    if (color == Colors.pink) return 'pembe';
    if (color == Colors.cyan) return 'camgöbeği';
    return 'renkli';
  }

  void _showWinDialog() {
    _isGameActive = false;
    _controller.stop();
    final int nonNegativeScore = max(0, _score);
    final bool finishedAll = _level >= _maxLevel;

    // Toplam istatistikleri güncelle
    _totalScore += nonNegativeScore;
    _totalPoppedBalloons += _poppedTargetCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
            finishedAll ? '🎉 Tüm Seviyeler Tamamlandı!' : '🎉 Görev Tamam!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Puan: $nonNegativeScore'),
            Text('Patlatılan balon: $_poppedTargetCount'),
            if (_combo > 1) Text('Kombo: $_combo'),
            if (finishedAll) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏆 Final İstatistikleri:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Toplam Patlatılan Balon: $_totalPoppedBalloons'),
                    Text('Toplam Puan: $_totalScore'),
                    Text('Tamamlanan Seviye: $_maxLevel'),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + _totalScore,
                totalGamePoints:
                    (widget.profile.totalGamePoints ?? 0) + _totalScore,
              );
              // UserProfile'ı SharedPreferences'a kaydet
              await _saveProfile(updated);
              Navigator.pop(context, updated);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          if (!finishedAll)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _level++;
                  _score = 0;
                  _combo = 0;
                });
                _startLevel();
                _controller.repeat();
              },
              child: const Text('Sonraki Seviye'),
            ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    _isGameActive = false;
    _controller.stop();
    final int nonNegativeScore = max(0, _score);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('💥 Oyun Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Puan: $nonNegativeScore'),
            Text('Patlatılan balon: $_poppedTargetCount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + nonNegativeScore,
                totalGamePoints:
                    (widget.profile.totalGamePoints ?? 0) + nonNegativeScore,
              );
              // UserProfile'ı SharedPreferences'a kaydet
              await _saveProfile(updated);
              Navigator.pop(context, updated);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _level = 1;
                _score = 0;
                _combo = 0;
              });
              _startLevel();
              _controller.repeat();
            },
            child: const Text('Yeniden Başla'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
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
            Colors.red.shade900,
            Colors.orange.shade200,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      '🎈 Balon Patlat',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Kurallar:\n\n• Ekranda farklı renklerde balonlar yükselecek.\n• Görevde belirtilen renkteki balonlara dokunarak patlat.\n• Yanlış renge dokunursan puan kaybedersin.\n• Zor seviyede tuzak balonlar ve hız artışı olabilir.',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.left,
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
                        'Puanlama:\n\n• Doğru balon: +5 puan (+kombo bonusu)\n• Yanlış balon: -5 puan\n• Tuzak balon: -10 puan\n• 5\'li kombo: +10 bonus',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child:
                          const Text('Başla', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final balloonSize = (width * 0.15).clamp(40.0, 72.0); // %25 daha büyük
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade900,
                Colors.orange.shade200,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Üst panel - sabit
                _buildHeader(),

                // Oyun alanı - scroll edilebilir
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      final balloonSize =
                          (width * 0.15).clamp(40.0, 72.0); // %25 daha büyük
                      return Stack(
                        children: [
                          // Balonlar
                          ..._balloons.map((balloon) {
                            final left = (balloon.x * (width - balloonSize))
                                .clamp(0.0, width - balloonSize);
                            final top = (balloon.y * (height - balloonSize))
                                .clamp(0.0, height - balloonSize);
                            return Positioned(
                              left: left,
                              top: top,
                              child: GestureDetector(
                                onTap: () => _popBalloon(balloon),
                                child:
                                    _buildBalloonWidget(balloon, balloonSize),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  '🎈 Balon Patlat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Seviye: $_level | Puan: $_score',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  _missionText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _timeLeft <= 10
                  ? Colors.red.withOpacity(0.8)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '⏰ $_timeLeft',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _timeLeft <= 10 ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalloonWidget(Balloon balloon, double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: balloon.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: balloon.color.withOpacity(0.3),
                blurRadius: size * 0.15,
                offset: Offset(0, size * 0.08),
              ),
            ],
            border: Border.all(
              color:
                  balloon.isTrap ? Colors.black : Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        if (balloon.isTrap)
          Icon(Icons.warning, color: Colors.black, size: size * 0.4),
      ],
    );
  }
}
