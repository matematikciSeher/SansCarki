
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class Twenty48GameScreen extends StatefulWidget {
  final UserProfile profile;
  const Twenty48GameScreen({super.key, required this.profile});

  @override
  State<Twenty48GameScreen> createState() => _Twenty48GameScreenState();
}

class _Twenty48GameScreenState extends State<Twenty48GameScreen> {
  static const int size = 5;
  final Random _rand = Random();
  late List<List<int>> _grid;
  int _score = 0;
  int _bestScore = 0;
  int _moves = 0;
  bool _gameOver = false;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _newGame();
    _showInfo = true;
    _loadBestScore();
  }

  void _newGame() {
    _score = 0;
    _moves = 0;
    _gameOver = false;
    _grid = List.generate(size, (_) => List.filled(size, 0));
    _spawn();
    _spawn();
    setState(() {});
  }

  Future<void> _loadBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _bestScore = prefs.getInt('twenty48_best_score') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _saveBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('twenty48_best_score', _bestScore);
    } catch (_) {}
  }

  void _spawn() {
    final empty = <Point<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_grid[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final p = empty[_rand.nextInt(empty.length)];
    _grid[p.x][p.y] = _rand.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _canMove() {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final v = _grid[r][c];
        if (v == 0) return true;
        if (r + 1 < size && (_grid[r + 1][c] == 0 || _grid[r + 1][c] == v))
          return true;
        if (c + 1 < size && (_grid[r][c + 1] == 0 || _grid[r][c + 1] == v))
          return true;
      }
    }
    return false;
  }

  bool _moveLeft() {
    bool moved = false;
    for (int r = 0; r < size; r++) {
      final row = _grid[r];
      final merged = List<bool>.filled(size, false);
      for (int c = 1; c < size; c++) {
        if (row[c] == 0) continue;
        int k = c;
        while (k > 0 && row[k - 1] == 0) {
          row[k - 1] = row[k];
          row[k] = 0;
          k--;
          moved = true;
        }
        if (k > 0 && row[k - 1] == row[k] && !merged[k - 1]) {
          row[k - 1] *= 2;
          _score += row[k - 1];
          row[k] = 0;
          merged[k - 1] = true;
          moved = true;
        }
      }
    }
    return moved;
  }

  bool _moveRight() {
    _reverse();
    final moved = _moveLeft();
    _reverse();
    return moved;
  }

  bool _moveUp() {
    _transpose();
    final moved = _moveLeft();
    _transpose();
    return moved;
  }

  bool _moveDown() {
    _transpose();
    _reverse();
    final moved = _moveLeft();
    _reverse();
    _transpose();
    return moved;
  }

  void _reverse() {
    for (int r = 0; r < size; r++) {
      _grid[r] = _grid[r].reversed.toList();
    }
  }

  void _transpose() {
    final t = List.generate(size, (_) => List.filled(size, 0));
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        t[r][c] = _grid[c][r];
      }
    }
    _grid = t;
  }

  void _handleMove(String dir) {
    if (_gameOver) return;
    bool moved = false;
    switch (dir) {
      case 'left':
        moved = _moveLeft();
        break;
      case 'right':
        moved = _moveRight();
        break;
      case 'up':
        moved = _moveUp();
        break;
      case 'down':
        moved = _moveDown();
        break;
    }
    if (moved) {
      _moves++;
      _spawn();
      setState(() {});
      if (!_canMove()) {
        setState(() => _gameOver = true);
        _showGameOver();
      }
    }
  }

  void _showGameOver() {
    // Puanı profile ekle ve kaydet
    final int earned = _score; // Klasik 2048 puanı
    if (_score > _bestScore) {
      _bestScore = _score;
      _saveBestScore();
    }
    final updatedProfile = widget.profile.copyWith(
      points: widget.profile.points + earned,
      totalGamePoints: (widget.profile.totalGamePoints ?? 0) + earned,
    );
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'user_profile', jsonEncode(updatedProfile.toJson()));
      } catch (_) {}
    }();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oyun Bitti'),
        content: Text('Skor: $_score\nKazanılan Puan: $earned'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, updatedProfile);
            },
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _newGame();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F2027),
              const Color(0xFF203A43),
              const Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _showInfo
                    ? _buildInfoPage()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final boardPad = 16.0;
                          final w = constraints.maxWidth - boardPad * 2;
                          final h = constraints.maxHeight - boardPad * 2;
                          final boardSize = w < h ? w : h;
                          return Center(
                            child: GestureDetector(
                              onPanEnd: (d) {
                                final v = d.velocity.pixelsPerSecond;
                                if (v.distance < 50) return;
                                if (v.dx.abs() > v.dy.abs()) {
                                  _handleMove(v.dx > 0 ? 'right' : 'left');
                                } else {
                                  _handleMove(v.dy > 0 ? 'down' : 'up');
                                }
                              },
                              child: Container(
                                width: boardSize,
                                height: boardSize,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: _buildBoard(boardSize - 20),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (!_showInfo) _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📘 Nasıl Oynanır?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '• Ekranda 2 veya 4 sayı blokları belirir.\n'
                  '• Aynı sayıları birleştirerek daha büyük sayılar oluştur (2+2=4, 4+4=8, ...).\n'
                  '• Amaç 2048 sayısına ulaşmak.\n'
                  '• Parmağını kaydırarak (yukarı/aşağı/sağ/sol) tüm blokları hareket ettir.\n'
                  '• Her hamleden sonra boş bir hücreye yeni bir blok (2/4) eklenir.\n'
                  '• Hamle kalmazsa oyun biter.',
                  style:
                      TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                ),
                SizedBox(height: 14),
                Text(
                  'İpuçları',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '• Büyük sayıları bir köşede tutmaya çalış.\n'
                  '• Boş yerleri koru, gereksiz hareketlerden kaçın.\n'
                  '• Önceki hamlelerinin sonuçlarını düşünerek strateji kur.',
                  style:
                      TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showInfo = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('🎮 Oyuna Başla',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
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
          const Expanded(
            child: Text(
              '2048',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_score',
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text('Hamle: $_moves',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text('En İyi: $_bestScore',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          IconButton(
            onPressed: _newGame,
            tooltip: 'Yeni Oyun',
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(double s) {
    final tileGap = 8.0;
    return Column(
      children: [
        for (int r = 0; r < size; r++)
          Expanded(
            child: Row(
              children: [
                for (int c = 0; c < size; c++)
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(tileGap / 2),
                      decoration: BoxDecoration(
                        color: _tileColor(_grid[r][c]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: _grid[r][c] == 0
                          ? const SizedBox.shrink()
                          : Text(
                              '${_grid[r][c]}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _grid[r][c] <= 4
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Color _tileColor(int v) {
    switch (v) {
      case 0:
        return const Color(0x141A1F); // very dark transparent
      case 2:
        return const Color(0xFF29ABE2); // vivid blue
      case 4:
        return const Color(0xFFFF8A00); // orange
      case 8:
        return const Color(0xFFFF3D7F); // pink
      case 16:
        return const Color(0xFF01C853); // green
      case 32:
        return const Color(0xFF9C27B0); // purple
      case 64:
        return const Color(0xFFFFC107); // amber
      case 128:
        return const Color(0xFF00BFA5); // teal
      case 256:
        return const Color(0xFFFF5252); // red
      case 512:
        return const Color(0xFF3F51B5); // indigo
      case 1024:
        return const Color(0xFF7C4DFF); // deep purple accent
      case 2048:
        return const Color(0xFFFFD600); // bright yellow
      case 4096:
        return const Color(0xFF00E5FF); // cyan accent
      case 8192:
        return const Color(0xFFFF6E40); // deep orange accent
      default:
        return Colors.deepPurpleAccent; // fallback vibrant
    }
  }

  // Kontrol tuşları kaldırıldı
}
