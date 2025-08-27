import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import '../models/user_profile.dart';

enum LogicDifficulty { easy, medium, hard }

class LogicPuzzle {
  final String id;
  final LogicDifficulty difficulty;
  final List<String> inputs; // e.g., ['A','B']
  final String description; // human readable description of circuit
  final bool Function(Map<String, bool> values) evaluate; // returns output

  const LogicPuzzle({
    required this.id,
    required this.difficulty,
    required this.inputs,
    required this.description,
    required this.evaluate,
  });
}

class LogicGatesPuzzleScreen extends StatefulWidget {
  final UserProfile profile;

  const LogicGatesPuzzleScreen({super.key, required this.profile});

  @override
  State<LogicGatesPuzzleScreen> createState() => _LogicGatesPuzzleScreenState();
}

class _LogicGatesPuzzleScreenState extends State<LogicGatesPuzzleScreen>
    with TickerProviderStateMixin {
  late List<LogicPuzzle> _puzzles;
  int _level = 1; // 1..9 (1-3 easy, 4-6 medium, 7-9 hard)
  int _score = 0;
  int _streak = 0;
  bool _showInfo = true;
  bool _isTimed = false;
  int _timeLeft = 30;
  Ticker? _ticker;
  Map<String, bool> _values = {};

  @override
  void initState() {
    super.initState();
    _puzzles = _buildPuzzles();
    _loadPuzzleState();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  List<LogicPuzzle> _buildPuzzles() {
    return [
      // Easy (2-3 gates conceptually)
      LogicPuzzle(
        id: 'E1',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A AND B',
        evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E2',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A OR B',
        evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E3',
        difficulty: LogicDifficulty.easy,
        inputs: ['A'],
        description: 'Çıkış = NOT A',
        evaluate: (v) => !(v['A'] ?? false),
      ),

      // Medium (4-5 gates equivalent)
      LogicPuzzle(
        id: 'M1',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A AND B) OR C',
        evaluate: (v) =>
            ((v['A'] ?? false) && (v['B'] ?? false)) || (v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M2',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A OR B) AND (NOT C)',
        evaluate: (v) =>
            ((v['A'] ?? false) || (v['B'] ?? false)) && !(v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M3',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT(A AND (B OR C))',
        evaluate: (v) =>
            !((v['A'] ?? false) && ((v['B'] ?? false) || (v['C'] ?? false))),
      ),

      // Hard (with decoys + timer)
      LogicPuzzle(
        id: 'H1',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A XOR B) AND (NOT C)  [XOR = A!=B]',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          final xor = (a && !b) || (!a && b);
          return xor && !c;
        },
      ),
      LogicPuzzle(
        id: 'H2',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT((A OR C) AND (B XOR C))',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          final xor = (b && !c) || (!b && c);
          return !(((a || c)) && xor);
        },
      ),
      LogicPuzzle(
        id: 'H3',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (NOT A AND B) OR (A AND NOT C)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return ((!a && b) || (a && !c));
        },
      ),
    ];
  }

  LogicDifficulty get _currentDifficulty {
    if (_level <= 3) return LogicDifficulty.easy;
    if (_level <= 6) return LogicDifficulty.medium;
    return LogicDifficulty.hard;
  }

  int _pointsForDifficulty(LogicDifficulty d) {
    switch (d) {
      case LogicDifficulty.easy:
        return 50;
      case LogicDifficulty.medium:
        return 100;
      case LogicDifficulty.hard:
        return 150;
    }
  }

  void _loadPuzzleState() {
    final puzzlesOfLevel =
        _puzzles.where((p) => p.difficulty == _currentDifficulty).toList();
    final idxInTier = ((_level - 1) % 3);
    final puzzle = puzzlesOfLevel[idxInTier];
    _values = {for (final k in puzzle.inputs) k: false};
    _isTimed = puzzle.difficulty == LogicDifficulty.hard;
    _timeLeft = 30;
    _ticker?.dispose();
    if (_isTimed) {
      _ticker = createTicker((elapsed) {
        final secs = 30 - elapsed.inSeconds;
        if (mounted) {
          setState(() => _timeLeft = secs.clamp(0, 30));
          if (_timeLeft <= 0) {
            _ticker?.stop();
            _showFailDialog(timeout: true);
          }
        }
      })
        ..start();
    }
  }

  void _startGame() {
    setState(() => _showInfo = false);
  }

  void _toggleInput(String key) {
    setState(() => _values[key] = !(_values[key] ?? false));
  }

  LogicPuzzle get _currentPuzzle {
    final puzzlesOfLevel =
        _puzzles.where((p) => p.difficulty == _currentDifficulty).toList();
    final idxInTier = ((_level - 1) % 3);
    return puzzlesOfLevel[idxInTier];
  }

  void _submit() {
    final ok = _currentPuzzle.evaluate(_values);
    if (ok) {
      _streak++;
      final pts = _pointsForDifficulty(_currentDifficulty);
      _score += pts;
      final gotWheel = _streak % 3 == 0;
      _ticker?.stop();
      _showSuccessDialog(points: pts, extraWheel: gotWheel);
    } else {
      _streak = 0;
      _ticker?.stop();
      _showFailDialog();
    }
  }

  void _showSuccessDialog({required int points, required bool extraWheel}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚡ Enerji Ulaştı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Kazanılan Puan: +$points'),
            if (extraWheel)
              const Text('3 başarı üst üste! Ekstra çark hakkı 🎡'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_level >= 9) {
                _showEndDialog();
              } else {
                setState(() {
                  _level++;
                });
                _loadPuzzleState();
              }
            },
            child: const Text('Sonraki Devre'),
          ),
        ],
      ),
    );
  }

  void _showFailDialog({bool timeout = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(timeout ? '⏰ Süre Doldu' : '❌ Enerji Ulaşmadı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Skor: $_score'),
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
                _values = {for (final k in _currentPuzzle.inputs) k: false};
              });
              _loadPuzzleState();
            },
            child: const Text('Yeniden Dene'),
          ),
        ],
      ),
    );
  }

  void _showEndDialog() {
    final updated =
        widget.profile.copyWith(points: widget.profile.points + _score);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏁 Tüm Devreler Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Skor: $_score'),
            const SizedBox(height: 8),
            const Text('Günün en hızlısı bonusu ileride eklenecek.'),
          ],
        ),
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
              setState(() {
                _level = 1;
                _score = 0;
                _streak = 0;
              });
              _loadPuzzleState();
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
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade600,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '🔌 Mantık Kapıları',
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
                    'Kurallar:\n\n• Giriş anahtarlarını A/B/C aç-kapat.\n• Devredeki kapılar çıktıyı belirler.\n• Amaç: enerjiyi çıkışa ulaştır (çıktı = true).\n• Zor seviyede süre sınırlıdır.\n\nKapılar:\n• AND: Her iki giriş de açık olursa çıkış açık.\n• OR: Girişlerden en az biri açık olursa çıkış açık.\n• NOT: Giriş terslenir (açık → kapalı, kapalı → açık).\n• XOR: Girişler farklıysa çıkış açık (biri açık biri kapalı).\n',
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
                    'Puanlama:\n\n• Kolay: +50 | Orta: +100 | Zor: +150\n• 3 doğru üst üste: ekstra çark hakkı 🎡\n',
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
    final puzzle = _currentPuzzle;
    final difficultyText = () {
      switch (puzzle.difficulty) {
        case LogicDifficulty.easy:
          return 'Kolay';
        case LogicDifficulty.medium:
          return 'Orta';
        case LogicDifficulty.hard:
          return 'Zor';
      }
    }();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade600,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Seviye: $_level ($difficultyText)',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('Skor: $_score',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (_isTimed)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Süre: $_timeLeft sn',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        puzzle.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: puzzle.inputs
                            .map(
                              (k) => FilterChip(
                                selected: _values[k] ?? false,
                                onSelected: (_) => _toggleInput(k),
                                label: Text(
                                    '$k: ${(_values[k] ?? false) ? 'Açık' : 'Kapalı'}'),
                                selectedColor: Colors.lightGreen,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.bolt),
                          label: const Text('Enerjiyi Gönder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              '🔌 Mantık Kapıları',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
