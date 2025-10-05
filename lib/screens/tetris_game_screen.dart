import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class TetrisGameScreen extends StatefulWidget {
  final UserProfile profile;

  const TetrisGameScreen({super.key, required this.profile});

  @override
  State<TetrisGameScreen> createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends State<TetrisGameScreen> with TickerProviderStateMixin {
  static const int gridWidth = 10;
  static const int gridHeight = 20;

  // Grid stores color index; -1 empty
  late List<List<int>> _grid;

  // Tetromino definitions (rotation states as list of points)
  // Coordinates are (x, y) within a 4x4 box
  final Map<String, List<List<Point<int>>>> _tetrominoes = {
    'I': [
      [const Point(0, 1), const Point(1, 1), const Point(2, 1), const Point(3, 1)],
      [const Point(2, 0), const Point(2, 1), const Point(2, 2), const Point(2, 3)],
      [const Point(0, 2), const Point(1, 2), const Point(2, 2), const Point(3, 2)],
      [const Point(1, 0), const Point(1, 1), const Point(1, 2), const Point(1, 3)],
    ],
    'O': [
      [const Point(1, 1), const Point(2, 1), const Point(1, 2), const Point(2, 2)],
      [const Point(1, 1), const Point(2, 1), const Point(1, 2), const Point(2, 2)],
      [const Point(1, 1), const Point(2, 1), const Point(1, 2), const Point(2, 2)],
      [const Point(1, 1), const Point(2, 1), const Point(1, 2), const Point(2, 2)],
    ],
    'T': [
      [const Point(1, 1), const Point(0, 2), const Point(1, 2), const Point(2, 2)],
      [const Point(1, 1), const Point(1, 2), const Point(2, 1), const Point(1, 0)],
      [const Point(0, 1), const Point(1, 1), const Point(2, 1), const Point(1, 2)],
      [const Point(1, 1), const Point(1, 2), const Point(0, 1), const Point(1, 0)],
    ],
    'S': [
      [const Point(1, 1), const Point(2, 1), const Point(0, 2), const Point(1, 2)],
      [const Point(1, 0), const Point(1, 1), const Point(2, 1), const Point(2, 2)],
      [const Point(1, 1), const Point(2, 1), const Point(0, 2), const Point(1, 2)],
      [const Point(1, 0), const Point(1, 1), const Point(2, 1), const Point(2, 2)],
    ],
    'Z': [
      [const Point(0, 1), const Point(1, 1), const Point(1, 2), const Point(2, 2)],
      [const Point(2, 0), const Point(1, 1), const Point(2, 1), const Point(1, 2)],
      [const Point(0, 1), const Point(1, 1), const Point(1, 2), const Point(2, 2)],
      [const Point(2, 0), const Point(1, 1), const Point(2, 1), const Point(1, 2)],
    ],
    'J': [
      [const Point(0, 1), const Point(0, 2), const Point(1, 2), const Point(2, 2)],
      [const Point(1, 0), const Point(2, 0), const Point(1, 1), const Point(1, 2)],
      [const Point(0, 1), const Point(1, 1), const Point(2, 1), const Point(2, 2)],
      [const Point(1, 0), const Point(1, 1), const Point(0, 2), const Point(1, 2)],
    ],
    'L': [
      [const Point(2, 1), const Point(0, 2), const Point(1, 2), const Point(2, 2)],
      [const Point(1, 0), const Point(1, 1), const Point(1, 2), const Point(2, 2)],
      [const Point(0, 1), const Point(1, 1), const Point(2, 1), const Point(0, 2)],
      [const Point(0, 0), const Point(1, 0), const Point(1, 1), const Point(1, 2)],
    ],
  };

  final List<Color> _colors = [
    Colors.cyan,
    Colors.yellow,
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.orange,
  ];

  String _currentType = 'I';
  int _currentRot = 0;
  int _currentX = 3; // spawn x (within grid)
  int _currentY = 0;
  int _currentColorIndex = 0;

  Timer? _timer;
  int _tickMs = 600;
  bool _isRunning = false;
  bool _isGameOver = false;
  bool _showInfo = true;

  int _score = 0;
  int _linesCleared = 0;
  final Random _rng = Random();
  List<String> _bag = [];

  @override
  void initState() {
    super.initState();
    _resetGrid();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetGrid() {
    _grid = List.generate(
      gridHeight,
      (_) => List<int>.filled(gridWidth, -1),
    );
    _score = 0;
    _linesCleared = 0;
    _isGameOver = false;
    _spawnNewPiece();
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
      _isRunning = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) {
      _stepDown();
    });
  }

  void _pauseResume() {
    setState(() {
      _isRunning = !_isRunning;
    });
    _timer?.cancel();
    if (_isRunning && !_isGameOver) {
      _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) {
        _stepDown();
      });
    }
  }

  void _spawnNewPiece() {
    if (_bag.isEmpty) {
      _bag = _tetrominoes.keys.toList()..shuffle(_rng);
    }
    _currentType = _bag.removeAt(0);
    _currentRot = _rng.nextInt(4); // rastgele başlangıç yönü (dikey I dahil)
    _currentX = 3;
    _currentY = -2; // spawn slightly above
    _currentColorIndex = _tetrominoIndex(_currentType);
    if (_collides(_currentX, _currentY, _currentRot)) {
      _gameOver();
    }
  }

  int _tetrominoIndex(String t) {
    switch (t) {
      case 'I':
        return 0;
      case 'O':
        return 1;
      case 'T':
        return 2;
      case 'S':
        return 3;
      case 'Z':
        return 4;
      case 'J':
        return 5;
      case 'L':
        return 6;
    }
    return 0;
  }

  bool _collides(int nx, int ny, int rot) {
    final shape = _tetrominoes[_currentType]![rot];
    for (final p in shape) {
      final gx = nx + p.x;
      final gy = ny + p.y;
      if (gx < 0 || gx >= gridWidth) return true;
      if (gy >= gridHeight) return true;
      if (gy >= 0 && _grid[gy][gx] != -1) return true;
    }
    return false;
  }

  void _fixToGrid() {
    final shape = _tetrominoes[_currentType]![_currentRot];
    for (final p in shape) {
      final gx = _currentX + p.x;
      final gy = _currentY + p.y;
      if (gy >= 0 && gy < gridHeight && gx >= 0 && gx < gridWidth) {
        _grid[gy][gx] = _currentColorIndex;
      }
    }
    _clearLines();
    _spawnNewPiece();
    setState(() {});
  }

  void _clearLines() {
    int cleared = 0;
    for (int y = gridHeight - 1; y >= 0; y--) {
      if (_grid[y].every((v) => v != -1)) {
        cleared++;
        // move all above down
        for (int ty = y; ty > 0; ty--) {
          _grid[ty] = List<int>.from(_grid[ty - 1]);
        }
        _grid[0] = List<int>.filled(gridWidth, -1);
        y++; // re-check same row after shift
      }
    }
    if (cleared > 0) {
      _linesCleared += cleared;
      // Basic scoring
      int add = 0;
      switch (cleared) {
        case 1:
          add = 100;
          break;
        case 2:
          add = 300;
          break;
        case 3:
          add = 500;
          break;
        case 4:
          add = 800;
          break;
      }
      _score += add;
      // Speed up slightly
      if (_tickMs > 200) {
        _tickMs = max(200, _tickMs - 20);
        if (_isRunning) {
          _timer?.cancel();
          _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) {
            _stepDown();
          });
        }
      }
    }
  }

  void _stepDown() {
    if (_isGameOver) return;
    final ny = _currentY + 1;
    if (!_collides(_currentX, ny, _currentRot)) {
      setState(() {
        _currentY = ny;
      });
    } else {
      _fixToGrid();
    }
  }

  void _move(int dx) {
    if (_isGameOver) return;
    final nx = _currentX + dx;
    if (!_collides(nx, _currentY, _currentRot)) {
      setState(() {
        _currentX = nx;
      });
    }
  }

  void _rotate() {
    if (_isGameOver) return;
    final nr = (_currentRot + 1) % 4;
    // Simple wall kick: try offsets
    for (final ox in [0, -1, 1, -2, 2]) {
      if (!_collides(_currentX + ox, _currentY, nr)) {
        setState(() {
          _currentRot = nr;
          _currentX += ox;
        });
        return;
      }
    }
  }

  void _softDrop() {
    if (_isGameOver) return;
    _stepDown();
    _score += 1;
  }

  void _hardDrop() {
    if (_isGameOver) return;
    int steps = 0;
    while (!_collides(_currentX, _currentY + 1, _currentRot)) {
      _currentY++;
      steps++;
    }
    _score += steps * 2;
    setState(() {});
    _fixToGrid();
  }

  Future<void> _saveProfile(UserProfile profile) async {
    try {
      await UserService.updateCurrentUserProfile(profile);
      await UserService.logActivity(
        activityType: 'tetris_completed',
        data: {
          'score': _score,
          'linesCleared': _linesCleared,
        },
      );
    } catch (e) {
      print('Tetris profil kaydetme hatası: $e');
    }
  }

  void _gameOver() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isGameOver = true;
    });

    // Güncel profili Firestore'dan çek
    UserProfile? currentProfile;
    try {
      currentProfile = await UserService.getCurrentUserProfile();
    } catch (e) {
      print('Güncel profil çekme hatası: $e');
      currentProfile = widget.profile; // Fallback
    }

    final gained = max(0, _score);
    final baseProfile = currentProfile ?? widget.profile;
    final updated = baseProfile.copyWith(
      points: baseProfile.points + gained,
      totalGamePoints: (baseProfile.totalGamePoints ?? 0) + gained,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oyun Bitti 🎮'),
        content: Text('Skor: $_score\nTemizlenen Satır: $_linesCleared'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveProfile(updated);
              Navigator.pop(context, updated);
            },
            child: const Text('Ana Menü'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _tickMs = 600;
              });
              _resetGrid();
              _startGame();
            },
            child: const Text('Yeniden Oyna'),
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
            Colors.black87,
            Colors.indigo.shade900,
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
                  '🧱 Tetris',
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
                    'Kurallar:\n\n• Düşen blokları sola/sağa hareket ettir ve döndür.\n• Tam dolu satırlar temizlenir ve puan kazanılır.\n• Parça yer bulamazsa oyun biter.',
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
                    'Puanlama:\n\n• 1 Satır: +100\n• 2 Satır: +300\n• 3 Satır: +500\n• 4 Satır: +800\n• Soft/Hard Drop: küçük bonus',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.indigo.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: gridWidth / gridHeight,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: CustomPaint(
                      painter: _TetrisPainter(
                        grid: _grid,
                        ghost: _ghostCells(),
                        currentCells: _currentCells(),
                        colors: _colors,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildControls(),
            const SizedBox(height: 12),
          ],
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
          Expanded(
            child: Column(
              children: [
                const Text(
                  '🧱 Tetris',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Skor: $_score  •  Satır: $_linesCleared',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _pauseResume,
            icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Point<int>> _currentCells() {
    final shape = _tetrominoes[_currentType]![_currentRot];
    return shape.map((p) => Point(_currentX + p.x, _currentY + p.y)).toList();
  }

  List<Point<int>> _ghostCells() {
    int gy = _currentY;
    while (!_collides(_currentX, gy + 1, _currentRot)) {
      gy++;
    }
    final shape = _tetrominoes[_currentType]![_currentRot];
    return shape.map((p) => Point(_currentX + p.x, gy + p.y)).toList();
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ctrlBtn(
            Icons.arrow_left,
            () => _move(-1),
            emphasized: true,
            bgColor: Colors.blueAccent,
            fgColor: Colors.white,
          ),
          _ctrlBtn(
            Icons.rotate_right,
            _rotate,
            emphasized: true,
            bgColor: Colors.orangeAccent,
            fgColor: Colors.white,
          ),
          _ctrlBtn(
            Icons.arrow_right,
            () => _move(1),
            emphasized: true,
            bgColor: Colors.green,
            fgColor: Colors.white,
          ),
          _ctrlBtn(
            Icons.arrow_downward,
            _softDrop,
            bgColor: Colors.purpleAccent,
            fgColor: Colors.white,
          ),
          _ctrlBtn(
            Icons.keyboard_double_arrow_down,
            _hardDrop,
            bgColor: Colors.redAccent,
            fgColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap, {bool emphasized = false, Color? bgColor, Color? fgColor}) {
    final double vPad = emphasized ? 16 : 12;
    final Color bg = bgColor ?? (emphasized ? Colors.white : Colors.white.withOpacity(0.9));
    final Color fg = fgColor ?? (emphasized ? Colors.indigo : Colors.indigo.shade700);
    final double iconSize = emphasized ? 28 : 24;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: EdgeInsets.symmetric(vertical: vPad),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white24, width: 1),
            ),
            elevation: emphasized ? 4 : 2,
          ),
          child: Icon(icon, size: iconSize),
        ),
      ),
    );
  }
}

class _TetrisPainter extends CustomPainter {
  final List<List<int>> grid;
  final List<Point<int>> ghost;
  final List<Point<int>> currentCells;
  final List<Color> colors;

  _TetrisPainter({
    required this.grid,
    required this.ghost,
    required this.currentCells,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / _TetrisGameScreenState.gridWidth;
    final cellH = size.height / _TetrisGameScreenState.gridHeight;

    final bgPaint = Paint()..color = Colors.white.withOpacity(0.06);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // draw ghost
    final ghostPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white24;
    for (final p in ghost) {
      if (p.y < 0) continue;
      final r = Rect.fromLTWH(p.x * cellW, p.y * cellH, cellW - 1, cellH - 1);
      canvas.drawRect(r, ghostPaint);
    }

    // draw fixed grid
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        final v = grid[y][x];
        if (v >= 0) {
          final paint = Paint()
            ..style = PaintingStyle.fill
            ..color = colors[v].withOpacity(0.9);
          final r = Rect.fromLTWH(x * cellW, y * cellH, cellW - 1, cellH - 1);
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(3)),
            paint,
          );
        }
      }
    }

    // draw current piece
    final curPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    for (final p in currentCells) {
      if (p.y < 0) continue;
      final r = Rect.fromLTWH(p.x * cellW, p.y * cellH, cellW - 1, cellH - 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        curPaint,
      );
    }

    // grid lines
    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (int x = 0; x <= _TetrisGameScreenState.gridWidth; x++) {
      canvas.drawLine(
        Offset(x * cellW, 0),
        Offset(x * cellW, size.height),
        linePaint,
      );
    }
    for (int y = 0; y <= _TetrisGameScreenState.gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * cellH),
        Offset(size.width, y * cellH),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TetrisPainter oldDelegate) {
    return oldDelegate.grid != grid || oldDelegate.currentCells != currentCells || oldDelegate.ghost != ghost;
  }
}
