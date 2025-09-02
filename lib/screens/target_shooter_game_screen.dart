import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  int _levelTimeSeconds() {
    // Daha makul: taban 20 sn, seviyeye göre +4 sn, üst sınır 40 sn
    return min(20 + _level * 4, 40);
  }

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
    _timeLeft = _levelTimeSeconds();
    _startTime = DateTime.now();
    _spawnInitialTargets();
  }

  void _spawnInitialTargets() {
    _targets.clear(); // Clear any existing targets
    for (int i = 0; i < 3 + _level; i++) {
      _targets.add(_createTarget());
    }
  }

  Target _createTarget() {
    final isFake = _level > 3 && _random.nextDouble() < 0.2;
    final color = isFake ? Colors.grey : Colors.redAccent;
    // radius: 0.10 * ekran genişliği, min 24, max 56 px (ekran boyutuna göre ayarlanacak)
    final radiusRatio = 0.10;
    // Ensure targets don't spawn too close to edges (considering radius)
    final margin = radiusRatio * 0.5;
    final x = margin + _random.nextDouble() * (1.0 - 2 * margin);
    final y = margin + _random.nextDouble() * (1.0 - 2 * margin);
    final speed = 0.0015 + 0.001 * _level + _random.nextDouble() * 0.0015;
    final angle = _random.nextDouble() * 2 * pi;
    return Target(
      id: _random.nextInt(1000000),
      x: x,
      y: y,
      dx: cos(angle) * speed,
      dy: sin(angle) * speed,
      radius: radiusRatio, // oran olarak tut
      color: color,
      isFake: isFake,
    );
  }

  void _updateTargets() {
    if (!_isGameActive || _targets.isEmpty) return;
    setState(() {
      for (final target in _targets) {
        if (!target.isHit) {
          target.x += target.dx;
          target.y += target.dy;

          // Consider target radius when bouncing off walls
          final radiusRatio = target.radius;
          final margin = radiusRatio * 0.5;

          // Bounce off walls with proper boundary checking
          if (target.x <= margin || target.x >= 1.0 - margin) {
            target.dx = -target.dx;
            target.x = target.x.clamp(margin, 1.0 - margin);
          }
          if (target.y <= margin || target.y >= 1.0 - margin) {
            target.dy = -target.dy;
            target.y = target.y.clamp(margin, 1.0 - margin);
          }
        }
      }
      final elapsed = DateTime.now().difference(_startTime).inSeconds;
      _timeLeft = max(0, _levelTimeSeconds() - elapsed).toInt();
      if (_timeLeft <= 0 || _shots >= _maxShots) {
        _isGameActive = false;
        _controller.stop();
        // Add a small delay to show final state before dialog
        Future.delayed(const Duration(milliseconds: 500), _showEndDialog);
      }
    });
  }

  void _shoot(Offset pos, Size size) {
    if (!_isGameActive || _shots >= _maxShots || _targets.isEmpty) return;
    setState(() {
      _shots++;
      bool hit = false;
      for (final target in _targets) {
        if (target.isHit) continue;
        final tx = target.x * size.width;
        final ty = target.y * size.height;
        final dist = (pos - Offset(tx, ty)).distance;
        // Convert radius ratio to actual pixels
        final actualRadius = (size.width * target.radius).clamp(24.0, 56.0);
        if (dist < actualRadius) {
          target.isHit = true;
          if (!target.isFake) {
            _hits++;
            // Seviye zorluğuna göre puanlama + merkeze yakınlık bonusu
            final baseScore = 10 +
                (_level * 5); // Seviye 1: 15, Seviye 2: 20, Seviye 3: 25...
            final centerDist = dist;
            final maxBonus = 15;
            final bonus = (maxBonus - (centerDist / actualRadius * maxBonus))
                .round()
                .toInt();
            final totalScore = (baseScore + max(0, bonus)).toInt();
            _score += totalScore;
          } else {
            // Sahte hedefler için sadece bonus puan yok, temel puan var
            final baseScore =
                5 + (_level * 2); // Seviye 1: 7, Seviye 2: 9, Seviye 3: 11...
            _score += baseScore;
            _fakesHit++;
            _perfect = false;
          }
          hit = true;
          break;
        }
      }
      if (!hit) {
        // Kaçan atışlar için minimal puan (negatif değil)
        final missScore =
            max(1, _level); // Seviye 1: 1, Seviye 2: 2, Seviye 3: 3...
        _score += missScore;
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
                totalGamePoints:
                    (widget.profile.totalGamePoints ?? 0) + _totalScore,
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
            Colors.deepPurple.shade900,
            Colors.deepPurple.shade400,
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
                      '🎯 Hedef Avı',
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
                        'Kurallar:\n\n• Ekranda hareket eden hedeflere dokunarak/tıklayarak vur.\n• Her oyunda 10 atış hakkın var.\n• Hedefin merkezine ne kadar yakın vurursan, o kadar yüksek bonus alırsın.\n• Tüm atışlar puan kazandırır, seviye arttıkça puanlar artar!',
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
                        'Puanlama:\n\n• Doğru hedef: Seviye bazlı puan + bonus\n• Sahte hedef: Seviye bazlı puan\n• Kaçan atış: Seviye bazlı puan\n• %100 isabet: Ekstra ödül\n• Seviye arttıkça puanlar artar!',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child:
                          const Text('Başla', style: TextStyle(fontSize: 20)),
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
              ..._targets.map((target) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final radius = (screenWidth * target.radius).clamp(24.0, 56.0);

                // Hedeflerin ekran sınırları içinde kalmasını sağla
                final maxLeft = screenWidth - 2 * radius;
                final maxTop = screenHeight - 2 * radius;
                final left = (target.x * maxLeft).clamp(0.0, maxLeft);
                final top = (target.y * maxTop).clamp(0.0, maxTop);

                return Positioned(
                  left: left,
                  top: top,
                  child: Opacity(
                    opacity: target.isHit ? 0.3 : 1.0,
                    child: _buildTargetWidget(target, radius),
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
              // Atış hakkı göstergesi
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Atış: $_shots/$_maxShots | Süre: $_timeLeft sn',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
      color: Colors.white.withOpacity(0.2),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Expanded(
            child: Text(
              '🎯 Hedef Avı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTargetWidget(Target target, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: target.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: target.color.withOpacity(0.3),
            blurRadius: radius * 0.3,
            offset: Offset(0, radius * 0.15),
          ),
        ],
        border: Border.all(
          color: target.isFake ? Colors.black : Colors.white,
          width: 1,
        ),
      ),
      child: target.isFake
          ? Icon(Icons.warning, color: Colors.black, size: radius * 0.6)
          : null,
    );
  }
}
