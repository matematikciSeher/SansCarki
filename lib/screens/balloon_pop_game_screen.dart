import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/user_profile.dart';

class Balloon {
  final int id;
  final Color color;
  double x;
  double y;
  bool isTarget;
  bool isTrap;
  bool isPopped;

  Balloon({
    required this.id,
    required this.color,
    required this.x,
    required this.y,
    this.isTarget = false,
    this.isTrap = false,
    this.isPopped = false,
  });
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
  int _timeLeft = 45; // 45 saniye süre
  Timer? _timer;

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
      _timeLeft = 45; // Süreyi sıfırla
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
            Text('Patlatılan balon: $_poppedTargetCount'),
            if (_combo > 1) Text('Son kombo: $_combo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + _score,
              );
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
                _timeLeft = 45;
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
      _missionText = 'Tüm ${_colorName(_targetColor)} balonları patlat!';
    } else {
      _missionText = 'Sırayla ${_colorName(_targetColor)} balonları patlat!';
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
    return Balloon(
      id: _random.nextInt(1000000),
      color: color,
      x: _random.nextDouble(), // 0.0-1.0 arası oran
      y: 0.9 + _random.nextDouble() * 0.1, // 0.9-1.0 arası oran
      isTarget: isTarget,
      isTrap: isTrap,
    );
  }

  void _updateBalloons() {
    if (!_isGameActive) return;
    setState(() {
      for (final balloon in _balloons) {
        if (!balloon.isPopped) {
          double speed = 0.003 + 0.0008 * _level;
          speed = speed.clamp(0.003, 0.012);
          balloon.y -= speed;
          if (balloon.y < 0.0) balloon.y = 0.0;
        }
      }
      _balloons.removeWhere((b) => b.y < -0.15);
      double spawnRate = 0.06 + 0.004 * _level;
      spawnRate = spawnRate.clamp(0.06, 0.15);
      if (_random.nextDouble() < spawnRate) {
        _balloons.add(_createBalloon());
      }
      int targetCount = 15 + _level * 3;
      if (_poppedTargetCount >= targetCount) {
        _showWinDialog();
      }
      int missLimit = 8 + _level;
      if (_missedCount > missLimit) {
        _showGameOverDialog();
      }
    });
  }

  void _popBalloon(Balloon balloon) {
    if (!_isGameActive || balloon.isPopped) return;
    setState(() {
      balloon.isPopped = true;
      if (balloon.isTrap) {
        _score -= 10;
        _combo = 0;
      } else if (balloon.isTarget) {
        _score += 5 + _combo;
        _combo++;
        _poppedTargetCount++;
        if (_combo % 5 == 0) {
          _score += 10; // Kombo bonusu
        }
      } else {
        _score -= 5;
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
            onPressed: () {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + _totalScore,
              );
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '🎈 Balon Patlat',
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
                    'Kurallar:\n\n• Ekranda farklı renklerde balonlar yükselecek.\n• Görevde belirtilen renkteki balonlara dokunarak patlat.\n• Yanlış renge dokunursan puan kaybedersin.\n• Zor seviyede tuzak balonlar ve hız artışı olabilir.\n',
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
                    'Puanlama:\n\n• Doğru balon: +5 puan (+kombo bonusu)\n• Yanlış balon: -5 puan\n• Tuzak balon: -10 puan\n• 5’li kombo: +10 bonus\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Başla', style: TextStyle(fontSize: 20)),
                ),
              ],
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
        final balloonSize = (width * 0.12).clamp(32.0, 64.0);
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
                      final balloonSize = (width * 0.12).clamp(32.0, 64.0);
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
