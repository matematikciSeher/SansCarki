import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user_profile.dart';

class PuzzleGameScreen extends StatefulWidget {
  final UserProfile profile;

  const PuzzleGameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _tileAnimationController;
  late Animation<double> _tileScaleAnimation;

  final List<int> _solution = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  List<int> _currentBoard = [];
  int _moves = 0;
  int _score = 0;
  Timer? _gameTimer;
  int _elapsedTime = 0;
  bool _isGameComplete = false;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGame();
    _startTimer();
  }

  void _startNewGame() {
    setState(() {
      _showInfo = false;
    });
  }

  void _initializeAnimations() {
    _tileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tileScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tileAnimationController,
      curve: Curves.elasticOut,
    ));

    _tileAnimationController.forward();
  }

  void _initializeGame() {
    _currentBoard = List.from(_solution);
    _shuffleBoard();
    _moves = 0;
    _score = 0;
    _elapsedTime = 0;
    _isGameComplete = false;
  }

  void _shuffleBoard() {
    final random = Random();
    for (int i = 0; i < 100; i++) {
      final emptyIndex = _currentBoard.indexOf(0);
      final possibleMoves = _getPossibleMoves(emptyIndex);
      if (possibleMoves.isNotEmpty) {
        final randomMove = possibleMoves[random.nextInt(possibleMoves.length)];
        _swapTiles(emptyIndex, randomMove);
      }
    }
  }

  List<int> _getPossibleMoves(int emptyIndex) {
    final List<int> moves = [];
    final row = emptyIndex ~/ 3;
    final col = emptyIndex % 3;

    if (row > 0) moves.add(emptyIndex - 3); // Üst
    if (row < 2) moves.add(emptyIndex + 3); // Alt
    if (col > 0) moves.add(emptyIndex - 1); // Sol
    if (col < 2) moves.add(emptyIndex + 1); // Sağ

    return moves;
  }

  void _swapTiles(int index1, int index2) {
    final temp = _currentBoard[index1];
    _currentBoard[index1] = _currentBoard[index2];
    _currentBoard[index2] = temp;
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameComplete) {
        setState(() {
          _elapsedTime++;
        });
      }
    });
  }

  void _onTileTap(int index) {
    if (_isGameComplete) return;

    final emptyIndex = _currentBoard.indexOf(0);
    if (_getPossibleMoves(emptyIndex).contains(index)) {
      setState(() {
        _swapTiles(index, emptyIndex);
        _moves++;
      });

      if (_checkWin()) {
        _endGame();
      }
    }
  }

  bool _checkWin() {
    for (int i = 0; i < _currentBoard.length; i++) {
      if (_currentBoard[i] != _solution[i]) return false;
    }
    return true;
  }

  void _endGame() {
    _isGameComplete = true;
    _gameTimer?.cancel();

    // Puan hesaplama
    _score = 1000 - (_moves * 10) - (_elapsedTime * 2);
    _score = _score.clamp(100, 1000);

    // Profil güncelleme
    final updatedProfile = widget.profile.copyWith(
      points: widget.profile.points + _score,
    );

    _showGameCompleteDialog(updatedProfile);
  }

  void _showGameCompleteDialog(UserProfile updatedProfile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sayı bulmacasını çözdün!'),
            const SizedBox(height: 16),
            _buildResultRow('⏱️ Süre', '${_elapsedTime} saniye'),
            _buildResultRow('🔄 Hamle', '$_moves'),
            _buildResultRow('⭐ Puan', '$_score'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Puanlar ana sisteme eklendi!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
              _restartGame();
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _restartGame() {
    _initializeGame();
    _startTimer();
  }

  @override
  void dispose() {
    _tileAnimationController.dispose();
    _gameTimer?.cancel();
    super.dispose();
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
            Colors.green.shade900,
            Colors.green.shade400,
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
                  '🧩 Sayı Bulmaca',
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
                    'Kurallar:\n\n• Sayıları doğru sıraya dizerek bulmacayı çöz.\n• Her doğru hamle puan kazandırır.\n',
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
                    'Puanlama:\n\n• Her doğru hamle: +10 puan\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startNewGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
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
            Colors.green.shade900,
            Colors.green.shade700,
            Colors.green.shade500,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Oyun bilgileri
            _buildGameInfo(),

            // Bulmaca tahtası
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPuzzleBoard(),
                ),
              ),
            ),
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
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '🧩 Sayı Bulmaca',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Sayıları doğru sıraya diz!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_score',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('⏱️', 'Süre', '${_elapsedTime}s'),
          _buildInfoItem('🔄', 'Hamle', '$_moves'),
          _buildInfoItem('🎯', 'Hedef', '1-8 sırala'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleBoard() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final value = _currentBoard[index];
          return _buildTile(index, value);
        },
      ),
    );
  }

  Widget _buildTile(int index, int value) {
    if (value == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return ScaleTransition(
      scale: _tileScaleAnimation,
      child: GestureDetector(
        onTap: () => _onTileTap(index),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
