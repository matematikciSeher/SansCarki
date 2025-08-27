import 'package:flutter/material.dart';
import 'dart:math';
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
      duration: const Duration(seconds: 1),
    )..addListener(_updateBalloons);
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
      _isGameActive = true;
      _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
      x: _random.nextDouble() * 0.8 + 0.1,
      y: 1.2 + _random.nextDouble() * 0.2,
      isTarget: isTarget,
      isTrap: isTrap,
    );
  }

  void _updateBalloons() {
    if (!_isGameActive) return;
    setState(() {
      for (final balloon in _balloons) {
        if (!balloon.isPopped) {
          // Yavaşlatıldı: 0.01 + 0.003 * _level -> 0.006 + 0.0015 * _level
          balloon.y -= 0.006 + 0.0015 * _level;
        }
      }
      // Remove balloons that are out of screen
      _balloons.removeWhere((b) => b.y < -0.1);
      // Spawn new balloons
      if (_random.nextDouble() < 0.15 + 0.01 * _level) {
        _balloons.add(_createBalloon());
      }
      // Oyun bitiş kontrolü (örnek: 20 hedef balon patlatınca seviye tamam)
      if (_poppedTargetCount >= 20 + _level * 2) {
        _showWinDialog();
      }
      if (_missedCount > 10) {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Görev Tamam!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Puan: $nonNegativeScore'),
            Text('Patlatılan balon: $_poppedTargetCount'),
            if (_combo > 1) Text('Kombo: $_combo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + nonNegativeScore,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
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
            child: Stack(
              children: [
                // Balonlar
                ..._balloons.map((balloon) {
                  // Balonun ekranda kalmasını sağla
                  final bx = (balloon.x * width).clamp(24.0, width - 48.0);
                  final by =
                      (balloon.y * height - 80).clamp(0.0, height - 80.0);
                  return Positioned(
                    left: bx,
                    top: by,
                    child: GestureDetector(
                      onTap: () => _popBalloon(balloon),
                      child: AnimatedOpacity(
                        opacity: balloon.isPopped ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: _buildBalloonWidget(balloon),
                      ),
                    ),
                  );
                }),
                // Üst panel
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(),
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
      padding: const EdgeInsets.all(16),
      color: Colors.white.withOpacity(0.2),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Seviye: $_level | Puan: $_score',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  _missionText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBalloonWidget(Balloon balloon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 96,
          decoration: BoxDecoration(
            color: balloon.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: balloon.color.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color:
                  balloon.isTrap ? Colors.black : Colors.white.withOpacity(0.5),
              width: balloon.isTrap ? 3 : 2,
            ),
          ),
        ),
        if (balloon.isTrap)
          const Icon(Icons.warning, color: Colors.black, size: 32),
      ],
    );
  }
}
