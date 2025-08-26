import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_profile.dart';

class ShapePiece {
  final int id;
  double rotation;
  Offset position;
  final ShapeType type;
  final Color color;
  final double targetRotation;

  ShapePiece({
    required this.id,
    required this.rotation,
    required this.position,
    required this.type,
    required this.color,
    required this.targetRotation,
  });
}

enum ShapeType { square, triangle, star, circle, hexagon }

class ShapeShiftGameScreen extends StatefulWidget {
  final UserProfile profile;

  const ShapeShiftGameScreen({super.key, required this.profile});

  @override
  State<ShapeShiftGameScreen> createState() => _ShapeShiftGameScreenState();
}

class _ShapeShiftGameScreenState extends State<ShapeShiftGameScreen>
    with TickerProviderStateMixin {
  late List<ShapePiece> _pieces;
  late List<ShapePiece> _targetPieces;
  int _currentLevel = 1;
  int _score = 0;
  int _timeLeft = 30;
  bool _isGameActive = true;
  late AnimationController _timerController;
  late AnimationController _rotationController;
  ShapePiece? _selectedPiece;
  Offset? _dragStart;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _generateLevel();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerController.forward();
    _timerController.addListener(() {
      if (mounted) {
        setState(() {
          _timeLeft = (30 * (1 - _timerController.value)).round();
          if (_timeLeft <= 0) {
            _isGameActive = false;
            _showGameOverDialog();
          }
        });
      }
    });
  }

  void _generateLevel() {
    final random = Random();
    final pieceCount = _currentLevel <= 3 ? 3 : (_currentLevel <= 6 ? 4 : 5);
    final shapeTypes = ShapeType.values;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    _targetPieces = [];
    _pieces = [];

    // Hedef şekli oluştur
    for (int i = 0; i < pieceCount; i++) {
      final type = shapeTypes[random.nextInt(shapeTypes.length)];
      final color = colors[random.nextInt(colors.length)];
      final targetRotation = random.nextDouble() * 2 * pi;

      _targetPieces.add(ShapePiece(
        id: i,
        rotation: targetRotation,
        position: Offset(
          (i % 3) * 120.0 + 60,
          (i ~/ 3) * 120.0 + 200,
        ),
        type: type,
        color: color,
        targetRotation: targetRotation,
      ));
    }

    // Karışık parçaları oluştur
    final shuffledPieces = List<ShapePiece>.from(_targetPieces);
    shuffledPieces.shuffle(random);

    for (int i = 0; i < shuffledPieces.length; i++) {
      final piece = shuffledPieces[i];
      _pieces.add(ShapePiece(
        id: piece.id,
        rotation: random.nextDouble() * 2 * pi, // Rastgele rotasyon
        position: Offset(
          (i % 3) * 120.0 + 60,
          (i ~/ 3) * 120.0 + 400,
        ),
        type: piece.type,
        color: piece.color,
        targetRotation: piece.targetRotation,
      ));
    }
  }

  void _rotatePiece(ShapePiece piece) {
    setState(() {
      piece.rotation += pi / 2; // 90 derece döndür
      if (piece.rotation >= 2 * pi) {
        piece.rotation -= 2 * pi;
      }
    });
    _checkWin();
  }

  void _onPanStart(DragStartDetails details, ShapePiece piece) {
    _selectedPiece = piece;
    _dragStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_selectedPiece != null && _dragStart != null) {
      setState(() {
        _selectedPiece!.position += details.delta;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _selectedPiece = null;
    _dragStart = null;
    _checkWin();
  }

  void _checkWin() {
    bool allCorrect = true;
    for (final piece in _pieces) {
      final targetPiece = _targetPieces.firstWhere((p) => p.id == piece.id);
      final rotationDiff = (piece.rotation - targetPiece.targetRotation).abs();
      final isRotationCorrect =
          rotationDiff < 0.3 || rotationDiff > 2 * pi - 0.3;

      if (!isRotationCorrect) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    final timeBonus = _timeLeft * 2;
    final levelBonus = _currentLevel * 10;
    final totalEarned = 50 + timeBonus + levelBonus;

    _timerController.stop();
    _isGameActive = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Şekil Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_currentLevel'),
            Text('Kalan Süre: $_timeLeft saniye'),
            Text('Süre Bonusu: $timeBonus'),
            Text('Seviye Bonusu: $levelBonus'),
            const SizedBox(height: 8),
            Text('Toplam Kazanılan: $totalEarned puan',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final updated = widget.profile.copyWith(
                points: widget.profile.points + totalEarned,
              );
              Navigator.pop(context, updated);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentLevel++;
                _score += totalEarned;
                _timeLeft = 30;
                _isGameActive = true;
              });
              _generateLevel();
              _timerController.reset();
              _startTimer();
            },
            child: const Text('Sonraki Seviye'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Süre Doldu!'),
        content: Text('Seviye: $_currentLevel\nToplam Puan: $_score'),
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
                _currentLevel = 1;
                _score = 0;
                _timeLeft = 30;
                _isGameActive = true;
              });
              _generateLevel();
              _timerController.reset();
              _startTimer();
            },
            child: const Text('Yeniden Başla'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
      _timerController.reset();
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showInfo ? _buildInfoPage() : _buildGameBody(),
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
          Expanded(
            child: Column(
              children: [
                const Text(
                  '🔷 Şekil Dönüştürme',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Seviye: $_currentLevel | Süre: $_timeLeft',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
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

  Widget _buildGameArea() {
    return Expanded(
      child: Stack(
        children: [
          // Hedef alan
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Center(
                child: Text(
                  'Hedef Şekil',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Hedef parçalar
          ..._targetPieces.map((piece) => Positioned(
                left: piece.position.dx,
                top: piece.position.dy,
                child: _buildShapeWidget(piece, false),
              )),

          // Oynanabilir parçalar
          ..._pieces.map((piece) => Positioned(
                left: piece.position.dx,
                top: piece.position.dy,
                child: GestureDetector(
                  onPanStart: (details) => _onPanStart(details, piece),
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTap: () => _rotatePiece(piece),
                  child: _buildShapeWidget(piece, true),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildShapeWidget(ShapePiece piece, bool isInteractive) {
    return Transform.rotate(
      angle: piece.rotation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: piece.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInteractive ? Colors.white : Colors.white54,
            width: isInteractive ? 4 : 3,
          ),
          boxShadow: isInteractive
              ? [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(4, 4),
                  ),
                ]
              : null,
        ),
        child: _buildShapeIcon(piece.type),
      ),
    );
  }

  Widget _buildShapeIcon(ShapeType type) {
    switch (type) {
      case ShapeType.square:
        return const Icon(Icons.square, color: Colors.white, size: 50);
      case ShapeType.triangle:
        return const Icon(Icons.change_history, color: Colors.white, size: 50);
      case ShapeType.star:
        return const Icon(Icons.star, color: Colors.white, size: 50);
      case ShapeType.circle:
        return const Icon(Icons.circle, color: Colors.white, size: 50);
      case ShapeType.hexagon:
        return const Icon(Icons.hexagon, color: Colors.white, size: 50);
    }
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _isGameActive ? _generateLevel : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Yenile'),
          ),
          Text(
            'Puan: $_score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
            Colors.teal.shade900,
            Colors.teal.shade700,
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
                  '🔷 Şekil Dönüştürme',
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
                    'Kurallar:\n\n• Parçaları dokunarak döndür ve sürükleyerek hareket ettir.\n• Tüm parçaları doğru açıya getirip şekli tamamla.\n• Süre bitmeden tamamlamaya çalış!\n',
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
                    'Puanlama:\n\n• Her tamamlanan şekil: +50 puan\n• Kalan süre × 2 puan\n• Seviye bonusu: Seviye × 10 puan\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.shade900,
            Colors.teal.shade700,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildGameArea(),
            _buildControls(),
          ],
        ),
      ),
    );
  }
}
