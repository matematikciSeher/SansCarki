import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SudokuGameScreen extends StatefulWidget {
  final UserProfile profile;

  const SudokuGameScreen({super.key, required this.profile});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  late List<List<int>> _board; // 0 boş
  late List<List<bool>> _fixed;
  int? _selectedRow;
  int? _selectedCol;
  final int _size = 9;
  late List<List<int>> _solution;
  late List<List<int>> _puzzle;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _generateNewSudoku();
  }

  void _generateNewSudoku() {
    _solution = _generateSudokuSolution(_size);
    _puzzle = _generateSudokuPuzzle(_solution, _size);
    _fixed = List.generate(
        _size, (i) => List.generate(_size, (j) => _puzzle[i][j] != 0));
    _board = _puzzle.map((row) => List<int>.from(row)).toList();
    setState(() {});
  }

  List<List<int>> _generateSudokuSolution(int size) {
    // Basit backtracking ile random çözüm üret
    List<List<int>> board = List.generate(size, (_) => List.filled(size, 0));
    bool _fill(int row, int col) {
      if (row == size) return true;
      int nextRow = col == size - 1 ? row + 1 : row;
      int nextCol = col == size - 1 ? 0 : col + 1;
      List<int> nums = List.generate(size, (i) => i + 1)..shuffle();
      for (int num in nums) {
        if (_isSafe(board, row, col, num)) {
          board[row][col] = num;
          if (_fill(nextRow, nextCol)) return true;
          board[row][col] = 0;
        }
      }
      return false;
    }

    _fill(0, 0);
    return board;
  }

  bool _isSafe(List<List<int>> board, int row, int col, int num) {
    for (int i = 0; i < _size; i++) {
      if (board[row][i] == num || board[i][col] == num) return false;
    }
    int boxRow = row - row % 3;
    int boxCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[boxRow + i][boxCol + j] == num) return false;
      }
    }
    return true;
  }

  List<List<int>> _generateSudokuPuzzle(List<List<int>> solution, int size) {
    // Çözümden rastgele hücreleri silerek puzzle üret (grade tabanlı zorluk)
    List<List<int>> puzzle =
        solution.map((row) => List<int>.from(row)).toList();

    final g = widget.profile.grade;
    int holes;
    if (g != null && g >= 1 && g <= 4) {
      holes = 20 + Random().nextInt(7); // 20-26 (daha kolay)
    } else if (g != null && g >= 5 && g <= 8) {
      holes = 30 + Random().nextInt(7); // 30-36 (orta)
    } else {
      holes = 40 + Random().nextInt(11); // 40-50 (zor)
    }

    while (holes > 0) {
      int i = Random().nextInt(size);
      int j = Random().nextInt(size);
      if (puzzle[i][j] != 0) {
        puzzle[i][j] = 0;
        holes--;
      }
    }
    return puzzle;
  }

  void _restartGame() {
    _generateNewSudoku();
  }

  void _selectCell(int row, int col) {
    if (_fixed[row][col]) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _inputNumber(int n) {
    if (_selectedRow == null || _selectedCol == null) return;
    final r = _selectedRow!;
    final c = _selectedCol!;
    if (_fixed[r][c]) return;
    setState(() {
      _board[r][c] = n;
    });
    if (_isComplete() && _isBoardValid()) {
      _showWinDialog();
    }
  }

  void _clearCell() {
    if (_selectedRow == null || _selectedCol == null) return;
    final r = _selectedRow!;
    final c = _selectedCol!;
    if (_fixed[r][c]) return;
    setState(() {
      _board[r][c] = 0;
    });
  }

  bool _isRowValid(int row) {
    final seen = <int>{};
    for (int c = 0; c < _size; c++) {
      final v = _board[row][c];
      if (v == 0) continue;
      if (seen.contains(v)) return false;
      if (v < 1 || v > _size) return false;
      seen.add(v);
    }
    return true;
  }

  bool _isColValid(int col) {
    final seen = <int>{};
    for (int r = 0; r < _size; r++) {
      final v = _board[r][col];
      if (v == 0) continue;
      if (seen.contains(v)) return false;
      if (v < 1 || v > _size) return false;
      seen.add(v);
    }
    return true;
  }

  bool _isCellValid(int row, int col) {
    // Farklı boyutlar için satır/sütun kuralı
    return _isRowValid(row) && _isColValid(col);
  }

  bool _isBoardValid() {
    for (int i = 0; i < _size; i++) {
      if (!_isRowValid(i) || !_isColValid(i)) return false;
    }
    return true;
  }

  bool _isComplete() {
    for (final row in _board) {
      for (final v in row) {
        if (v == 0) return false;
      }
    }
    return true;
  }

  Future<void> _saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }

  void _showWinDialog() {
    final updated = widget.profile.copyWith(
        points: widget.profile.points + 100,
        totalGamePoints: (widget.profile.totalGamePoints ?? 0) + 100);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tebrikler! 🧩'),
        content: const Text('Sudoku tamamlandı! Kazanılan Puan: 100'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveProfile(updated);
              Navigator.pop(context, updated);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateNewSudoku();
            },
            child: const Text('Yeni Oyun'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
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
            Colors.indigo.shade900,
            Colors.indigo.shade700,
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
                  '🧩 Sudoku',
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
                    'Kurallar:\n\n• 9x9 Sudoku tahtasında her satır, sütun ve 3x3 kutuda 1-9 arası rakamlar bir kez yer almalı.\n• Boş hücrelere dokunup rakamları girerek bulmacayı tamamla.\n',
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
                    'Puanlama:\n\n• Her tamamlanan Sudoku: +100 puan\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
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
            Colors.indigo.shade900,
            Colors.indigo.shade700,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildGrid(),
            const SizedBox(height: 12),
            _buildKeypad(),
            const SizedBox(height: 12),
            _buildActions(),
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
              '🧩 Sudoku 9x9',
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

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: List.generate(_size, (r) => _buildGridRow(r)),
          ),
        ),
      ),
    );
  }

  Widget _buildGridRow(int r) {
    return Expanded(
      child: Row(
        children: List.generate(_size, (c) => _buildCell(r, c)),
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    final value = _board[r][c];
    final isSelected = _selectedRow == r && _selectedCol == c;
    final isFixed = _fixed[r][c];
    final isValid = _isCellValid(r, c);

    Color bg = Colors.white.withOpacity(0.04);
    if (isSelected) {
      bg = Colors.blueAccent.withOpacity(0.35);
    } else if (!isValid && value != 0) {
      bg = Colors.redAccent.withOpacity(0.3);
    } else if (value != 0) {
      bg = Colors.green.withOpacity(0.2);
    }

    BorderSide thin = BorderSide(color: Colors.white24, width: 1);
    BorderSide thick = BorderSide(color: Colors.white54, width: 2.5);

    // 3x3 kutu sınırlarını belirginleştir
    bool thickTop = r % 3 == 0;
    bool thickLeft = c % 3 == 0;
    bool thickRight = c == 8;
    bool thickBottom = r == 8;

    return Expanded(
      child: InkWell(
        onTap: () => _selectCell(r, c),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: thickTop ? thick : thin,
              left: thickLeft ? thick : thin,
              right: thickRight ? thick : thin,
              bottom: thickBottom ? thick : thin,
            ),
          ),
          child: Center(
            child: Text(
              value == 0 ? '' : '$value',
              style: TextStyle(
                color: Colors.white,
                fontSize: isFixed ? 20 : 20,
                fontWeight: isFixed ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_size, (i) => _buildKey(i + 1)),
      ),
    );
  }

  Widget _buildKey(int value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _inputNumber(value),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('$value', style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearCell,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Sil'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _generateNewSudoku,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Yeni Oyun'),
            ),
          ),
        ],
      ),
    );
  }
}
