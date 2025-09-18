import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'dart:math';

class _Cell {
  bool top;
  bool right;
  bool bottom;
  bool left;
  bool visited;
  _Cell(
      {this.top = true,
      this.right = true,
      this.bottom = true,
      this.left = true,
      this.visited = false});
}

class MazeGameScreen extends StatefulWidget {
  final UserProfile profile;

  const MazeGameScreen({super.key, required this.profile});

  @override
  State<MazeGameScreen> createState() => _MazeGameScreenState();
}

class _MazeGameScreenState extends State<MazeGameScreen> {
  final int _rows = 15;
  final int _cols = 15;
  late List<List<_Cell>> _maze;
  int _playerR = 0;
  int _playerC = 0;
  late int _goalR;
  late int _goalC;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _generateMaze();
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
    });
  }

  void _reset() {
    _playerR = 0;
    _playerC = 0;
    _goalR = _rows - 1;
    _goalC = _cols - 1;
  }

  void _generateMaze() {
    _maze = List.generate(
      _rows,
      (r) => List.generate(
        _cols,
        (c) => _Cell(),
      ),
    );
    _carveWithDFS(0, 0);
    _reset();
    setState(() {});
  }

  void _carveWithDFS(int sr, int sc) {
    final rand = Random();
    void carve(int r, int c) {
      _maze[r][c].visited = true;
      final dirs = [
        const Offset(0, -1), // up
        const Offset(1, 0), // right
        const Offset(0, 1), // down
        const Offset(-1, 0), // left
      ]..shuffle(rand);
      for (final d in dirs) {
        final nr = r + d.dy.toInt();
        final nc = c + d.dx.toInt();
        if (nr < 0 || nc < 0 || nr >= _rows || nc >= _cols) continue;
        if (_maze[nr][nc].visited) continue;
        if (d.dy == -1) {
          _maze[r][c].top = false;
          _maze[nr][nc].bottom = false;
        } else if (d.dx == 1) {
          _maze[r][c].right = false;
          _maze[nr][nc].left = false;
        } else if (d.dy == 1) {
          _maze[r][c].bottom = false;
          _maze[nr][nc].top = false;
        } else if (d.dx == -1) {
          _maze[r][c].left = false;
          _maze[nr][nc].right = false;
        }
        carve(nr, nc);
      }
    }

    carve(sr, sc);

    for (final row in _maze) {
      for (final cell in row) {
        cell.visited = false;
      }
    }
  }

  bool _canStep(int r, int c, int dr, int dc) {
    if (dr == -1) return !_maze[r][c].top;
    if (dr == 1) return !_maze[r][c].bottom;
    if (dc == -1) return !_maze[r][c].left;
    if (dc == 1) return !_maze[r][c].right;
    return false;
  }

  bool _isStraightCorridor(int r, int c, int dr, int dc) {
    final openUp = !_maze[r][c].top;
    final openRight = !_maze[r][c].right;
    final openDown = !_maze[r][c].bottom;
    final openLeft = !_maze[r][c].left;
    final degree = (openUp ? 1 : 0) +
        (openRight ? 1 : 0) +
        (openDown ? 1 : 0) +
        (openLeft ? 1 : 0);
    if (degree != 2) return false;
    if (dr != 0) {
      // moving vertically: only up/down should be open
      return openUp && openDown && !openLeft && !openRight;
    } else {
      // moving horizontally: only left/right should be open
      return openLeft && openRight && !openUp && !openDown;
    }
  }

  void _moveAuto(int dr, int dc) {
    int r = _playerR;
    int c = _playerC;
    // first step if possible
    if (_canStep(r, c, dr, dc)) {
      r += dr;
      c += dc;
      // keep going while corridor is straight and next step is possible
      while (_isStraightCorridor(r, c, dr, dc) && _canStep(r, c, dr, dc)) {
        r += dr;
        c += dc;
      }
      setState(() {
        _playerR = r;
        _playerC = c;
      });
      if (_playerR == _goalR && _playerC == _goalC) {
        _showWin();
      }
    }
  }

  void _showWin() {
    final earned = 80 + (_rows + _cols); // daha yüksek puan
    final updated = widget.profile.copyWith(
        points: widget.profile.points + earned,
        totalGamePoints: (widget.profile.totalGamePoints ?? 0) + earned);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Text('Labirentin çıkışını buldun!\nKazanılan Puan: $earned'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, updated);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateMaze();
            },
            child: const Text('Tekrar Oyna'),
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
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade700,
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
                  '🌀 Labirent',
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
                    'Kurallar:\n\n• Labirentte çıkışı bulmak için ok tuşlarıyla veya butonlarla hareket et.\n• Duvarlara çarpmadan en kısa sürede çıkışı bulmaya çalış.\n',
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
                    'Puanlama:\n\n• Her tamamlanan labirent: +100 puan\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueGrey,
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
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade700,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildMazeView(),
            const SizedBox(height: 8),
            _buildControls(),
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
          const Expanded(
            child: Text(
              '🌀 Labirent',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMazeView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _MazePainter(_maze, _playerR, _playerC, _goalR, _goalC),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              IconButton(
                onPressed: () => _moveAuto(-1, 0),
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                iconSize: 48,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _moveAuto(0, -1),
                    icon: const Icon(Icons.keyboard_arrow_left,
                        color: Colors.white),
                    iconSize: 48,
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: () => _moveAuto(0, 1),
                    icon: const Icon(Icons.keyboard_arrow_right,
                        color: Colors.white),
                    iconSize: 48,
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _moveAuto(1, 0),
                icon:
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                iconSize: 48,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _generateMaze,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueGrey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Yenile'),
          )
        ],
      ),
    );
  }
}

class _MazePainter extends CustomPainter {
  final List<List<_Cell>> maze;
  final int playerR;
  final int playerC;
  final int goalR;
  final int goalC;
  _MazePainter(this.maze, this.playerR, this.playerC, this.goalR, this.goalC);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = maze.length;
    final cols = maze.first.length;
    final paintWall = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 2;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * cellW;
        final y = r * cellH;
        final cell = maze[r][c];
        if (cell.top)
          canvas.drawLine(Offset(x, y), Offset(x + cellW, y), paintWall);
        if (cell.right)
          canvas.drawLine(
              Offset(x + cellW, y), Offset(x + cellW, y + cellH), paintWall);
        if (cell.bottom)
          canvas.drawLine(
              Offset(x, y + cellH), Offset(x + cellW, y + cellH), paintWall);
        if (cell.left)
          canvas.drawLine(Offset(x, y), Offset(x, y + cellH), paintWall);
      }
    }

    final goalRect = Rect.fromLTWH(
        goalC * cellW + 4, goalR * cellH + 4, cellW - 8, cellH - 8);
    final playerRect = Rect.fromLTWH(
        playerC * cellW + 6, playerR * cellH + 6, cellW - 12, cellH - 12);
    final goalPaint = Paint()..color = const Color(0x884CAF50);
    final playerPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawRRect(
        RRect.fromRectAndRadius(goalRect, const Radius.circular(6)), goalPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(playerRect, const Radius.circular(6)),
        playerPaint);
  }

  @override
  bool shouldRepaint(covariant _MazePainter oldDelegate) {
    return oldDelegate.playerR != playerR ||
        oldDelegate.playerC != playerC ||
        oldDelegate.maze != maze;
  }
}
