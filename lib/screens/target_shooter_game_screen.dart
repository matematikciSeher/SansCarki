import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_profile.dart';

class Target {
  final int id;
  double x;
  double y;
  double dx;
  double dy;
  final double radius;
  final Color color;
  bool isFake;
  bool isHit;

  Target({
    required this.id,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.radius,
    required this.color,
    this.isFake = false,
    this.isHit = false,
  });
}

class TargetShooterGameScreen extends StatefulWidget {
  final UserProfile profile;
  const TargetShooterGameScreen({super.key, required this.profile});

  @override
  State<TargetShooterGameScreen> createState() =>
      _TargetShooterGameScreenState();
}

class _TargetShooterGameScreenState extends State<TargetShooterGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Target> _targets;
  int _score = 0;
  int _shots = 0;
  int _maxShots = 10;
  int _level = 1;
  int _hits = 0;
  int _fakesHit = 0;
  bool _isGameActive = true;
  bool _perfect = true;
  late int _timeLeft;
  late DateTime _startTime;
  Random _random = Random();
  bool _showInfo = true;
  int _totalShots = 0;
  int _totalHits = 0;
  int _totalScore = 0;
  int _maxLevel = 5;

  @override
  void initState() {
    super.initState();
    _startLevel();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(_updateTargets)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startLevel() {
    _targets = [];
    _score = 0;
    _shots = 0;
    _hits = 0;
    _fakesHit = 0;
    _isGameActive = true;
    _perfect = true;
    _timeLeft = 40 + min(_level * 3, 20); // Süre uzatıldı: 40-60 sn
    _startTime = DateTime.now();
    _spawnInitialTargets();
  }

  void _spawnInitialTargets() {
    for (int i = 0; i < 3 + _level; i++) {
      _targets.add(_createTarget());
    }
  }

  Target _createTarget() {
    final isFake = _level > 3 && _random.nextDouble() < 0.2;
    final color = isFake ? Colors.grey : Colors.redAccent;
    final radius = 32.0 + _random.nextDouble() * 16.0;
    final x = _random.nextDouble() * 0.7 + 0.15;
    final y = _random.nextDouble() * 0.5 + 0.2;
    // Hedefler daha yavaş hareket etsin
    final speed = 0.0015 + 0.001 * _level + _random.nextDouble() * 0.0015;
    final angle = _random.nextDouble() * 2 * pi;
    return Target(
      id: _random.nextInt(1000000),
      x: x,
      y: y,
      dx: cos(angle) * speed,
      dy: sin(angle) * speed,
      radius: radius,
      color: color,
      isFake: isFake,
    );
  }

  void _updateTargets() {
    if (!_isGameActive) return;
    setState(() {
      for (final target in _targets) {
        if (!target.isHit) {
          target.x += target.dx;
          target.y += target.dy;
          // Duvara çarpınca yön değiştir
          if (target.x < 0.05 || target.x > 0.95) target.dx = -target.dx;
          if (target.y < 0.1 || target.y > 0.8) target.dy = -target.dy;
        }
      }
      // Zaman kontrolü
      final elapsed = DateTime.now().difference(_startTime).inSeconds;
      _timeLeft = max(0, 40 + min(_level * 3, 20) - elapsed).toInt();
      if (_timeLeft <= 0 || _shots >= _maxShots) {
        _isGameActive = false;
        _controller.stop();
        Future.delayed(const Duration(milliseconds: 300), _showEndDialog);
      }
    });
  }

  void _shoot(Offset pos, Size size) {
    if (!_isGameActive || _shots >= _maxShots) return;
    setState(() {
      _shots++;
      bool hit = false;
      for (final target in _targets) {
        if (target.isHit) continue;
        final tx = target.x * size.width;
        final ty = target.y * size.height;
        final dist = (pos - Offset(tx, ty)).distance;
        if (dist < target.radius) {
          target.isHit = true;
          if (!target.isFake) {
            _hits++;
            // Merkeze yakınlık puanı
            final centerDist = dist;
            final maxScore = 20;
            final score =
                maxScore - (centerDist / target.radius * maxScore).round();
            _score += max(5, score);
          } else {
            _score -= 10;
            _fakesHit++;
            _perfect = false;
          }
          hit = true;
          break;
        }
      }
      if (!hit) {
        _score -= 2;
        _perfect = false;
      }
    });
  }

  void _showEndDialog() {
    final isPerfect = _hits == _shots && _shots > 0 && _fakesHit == 0;
    _totalShots += _shots;
    _totalHits += _hits;
    _totalScore += _score;
    bool finishedAll = _level >= _maxLevel;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(finishedAll
            ? '🎯 Oyun Sonu!\nToplam Puan: $_totalScore'
            : '🎯 Oyun Bitti!\nToplam Puan: $_totalScore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Bu seviyede isabet: $_hits/$_shots'),
            if (isPerfect) const Text('Mükemmel! Ekstra ödül kazandın 🎁'),
            if (finishedAll) ...[
              const SizedBox(height: 12),
              Text('Toplam Atış: $_totalShots'),
              Text('Toplam İsabet: $_totalHits'),
              Text('Toplam Puan: $_totalScore'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + _totalScore,
                // İstatistikleri UserProfile'a eklemek istersen burada ekle
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

  void _startGame() {
    setState(() {
      _showInfo = false;
      _controller.repeat();
    });
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
            Colors.deepPurple.shade900,
            Colors.deepPurple.shade400,
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
                  '🎯 Hedef Avı',
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
                    'Kurallar:\n\n• Ekranda hareket eden hedeflere dokunarak/tıklayarak vur.\n• Her oyunda 10 atış hakkın var.\n• Hedefin merkezine ne kadar yakın vurursan, o kadar yüksek puan alırsın.\n• Sahte hedeflere veya boşluğa tıklarsan puan kaybedersin.\n',
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
                    'Puanlama:\n\n• Merkeze yakın isabet: +5 ila +20 puan\n• Sahte hedef: -10 puan\n• Kaçan atış: -2 puan\n• %100 isabet: Ekstra ödül\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
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
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(details.globalPosition);
        _shoot(local, box.size);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Hedefler
              ..._targets.map((target) => AnimatedPositioned(
                    duration: const Duration(milliseconds: 16),
                    left: MediaQuery.of(context).size.width * target.x -
                        target.radius,
                    top: MediaQuery.of(context).size.height * target.y -
                        target.radius,
                    child: Opacity(
                      opacity: target.isHit ? 0.3 : 1.0,
                      child: _buildTargetWidget(target),
                    ),
                  )),
              // Üst panel
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(),
              ),
              // Atış hakkı göstergesi
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Atış:  $_shots/$_maxShots | Süre: $_timeLeft sn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
      color: Colors.white.withOpacity(0.2),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              '🎯 Hedef Avı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTargetWidget(Target target) {
    return Container(
      width: target.radius * 2,
      height: target.radius * 2,
      decoration: BoxDecoration(
        color: target.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: target.color.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: target.isFake ? Colors.black : Colors.white,
          width: target.isFake ? 3 : 2,
        ),
      ),
      child: target.isFake
          ? const Icon(Icons.warning, color: Colors.black, size: 32)
          : null,
    );
  }
}
