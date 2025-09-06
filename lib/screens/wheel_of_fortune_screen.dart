import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:characters/characters.dart';
import '../models/user_profile.dart';

class GameLogic {
  final List<String> players;
  final String secretWord; // Uppercase, Turkish supported
  final List<int> scores;
  final Set<String> revealed; // set of revealed uppercase letters
  int currentPlayerIndex;
  String? lastSpin; // e.g. '+100', 'İflas', 'Pas'
  late final List<bool> jokerUsed;

  GameLogic({
    required this.players,
    required this.secretWord,
  })  : scores = List<int>.filled(players.length, 0),
        revealed = {},
        currentPlayerIndex = 0 {
    jokerUsed = List<bool>.filled(players.length, false);
  }

  bool get isSolved {
    for (final ch in secretWord.characters) {
      if (_isLetter(ch) && !revealed.contains(_normalize(ch))) return false;
    }
    return true;
  }

  static bool _isLetter(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        'ÇĞİÖŞÜçğıöşü'.contains(ch);
  }

  static String _normalize(String ch) => ch.toUpperCase();

  static const Set<String> vowels = {'A', 'E', 'I', 'İ', 'O', 'Ö', 'U', 'Ü'};
  static bool isVowel(String ch) => vowels.contains(_normalize(ch));

  int revealLetter(String letter) {
    final up = _normalize(letter);
    int count = 0;
    for (final ch in secretWord.characters) {
      if (_isLetter(ch) && _normalize(ch) == up) {
        if (!revealed.contains(up)) {
          // count all occurrences; reveal stays by letter set
        }
        count++;
      }
    }
    if (count > 0) revealed.add(up);
    return count;
  }

  void applySpinResult(String result) {
    lastSpin = result;
    if (result == 'İflas') {
      scores[currentPlayerIndex] = 0;
      _nextPlayer();
    } else if (result == 'Pas') {
      _nextPlayer();
    }
  }

  void rewardForGuess(int perLetterPoints, int count) {
    scores[currentPlayerIndex] += perLetterPoints * count;
  }

  void _nextPlayer() {
    if (players.length <= 1) return; // Tek oyuncuda sıra değişmez
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  void switchTurn() => _nextPlayer();

  int buyVowel(String letter) {
    final up = _normalize(letter);
    if (!isVowel(up)) return 0;
    if (scores[currentPlayerIndex] < 200) return -1;
    scores[currentPlayerIndex] -= 200;
    final count = revealLetter(up);
    return count;
  }

  String? useJoker(Random random) {
    if (jokerUsed[currentPlayerIndex]) return null;
    final allLetters = <String>{};
    for (final ch in secretWord.characters) {
      if (_isLetter(ch)) allLetters.add(_normalize(ch));
    }
    final hidden = allLetters.difference(revealed);
    if (hidden.isEmpty) return null;
    final consonants = hidden.where((c) => !isVowel(c)).toList();
    final pool = consonants.isNotEmpty ? consonants : hidden.toList();
    final pick = pool[random.nextInt(pool.length)];
    revealLetter(pick);
    jokerUsed[currentPlayerIndex] = true;
    return pick;
  }
}

class WheelOfFortuneScreen extends StatefulWidget {
  final UserProfile profile;
  const WheelOfFortuneScreen({super.key, required this.profile});

  @override
  State<WheelOfFortuneScreen> createState() => _WheelOfFortuneScreenState();
}

class _WheelOfFortuneScreenState extends State<WheelOfFortuneScreen>
    with SingleTickerProviderStateMixin {
  late GameLogic _logic;
  String? _hintCategory;
  String? _hintText;
  late AnimationController _controller;
  late Animation<double> _rotation;
  final Random _random = Random();
  bool _spinning = false;
  bool _singlePlayer = false;
  List<Map<String, String>> _singleItems = [];
  List<Map<String, String>> _multiItems = [];
  bool _loading = true;
  final Set<String> _usedWords = {};
  int _lastTickIndex = -1;

  final List<String> _segments = const [
    '+100',
    '+200',
    'Pas',
    '+300',
    '+150',
    'İflas',
    '+250',
    '+400'
  ];

  String _normalizeTr(String input) {
    var t = input.trim();
    t = t.replaceAll('i', 'İ').replaceAll('ı', 'I');
    return t.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadWords();
      final initial = _pickFromAssets();
      setState(() {
        final hints = (json.decode(initial['hints']!) as List).cast<Map>();
        _hintCategory = '${hints.first['category']}';
        _hintText = '${hints.first['text']}';
        _logic = GameLogic(
          players: ['Oyuncu 1', 'Oyuncu 2'],
          secretWord: initial['word']!,
        );
        _usedWords.add(initial['word']!);
        _loading = false;
      });
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _rotation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )
      ..addListener(() {
        // Tick sound on segment change
        final perSlice = 2 * pi / _segments.length;
        final norm = (_rotation.value + pi / 2) % (2 * pi);
        final idx = (norm / perSlice).floor() % _segments.length;
        if (idx != _lastTickIndex) {
          _lastTickIndex = idx;
          SystemSound.play(SystemSoundType.click);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _spinning = false);
          final result = _resultFromAngle(_rotation.value);
          _logic.applySpinResult(result);
          if (result == 'İflas' || result == 'Pas') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result == 'İflas'
                      ? 'İflas! Puan sıfırlandı.'
                      : (_logic.players.length <= 1
                          ? 'Pas! Tur boşa geçti.'
                          : 'Pas! Sıra diğer oyuncuda.'),
                ),
              ),
            );
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final jsonStr = await DefaultAssetBundle.of(context)
        .loadString('assets/words_hints.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _singleItems = (data['single'] as List)
        .map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'word': '${m['word']}',
            // Flatten first hint by default; we will also keep full list in memory
            'hints': json.encode(m['hints']),
            'difficulty': '${m['difficulty'] ?? 'medium'}'
          };
        })
        .cast<Map<String, String>>()
        .toList();
    _multiItems = (data['multi'] as List)
        .map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'word': '${m['word']}',
            'hints': json.encode(m['hints']),
            'difficulty': '${m['difficulty'] ?? 'medium'}'
          };
        })
        .cast<Map<String, String>>()
        .toList();
  }

  Map<String, String> _pickFromAssets() {
    final list = _singlePlayer ? _singleItems : _multiItems;
    String targetDifficulty = 'medium';
    final grade = widget.profile.grade;
    if (grade != null) {
      if (grade <= 4)
        targetDifficulty = 'easy';
      else if (grade <= 8)
        targetDifficulty = 'medium';
      else
        targetDifficulty = 'hard';
    }
    final filtered = list
        .where((m) =>
            (m['difficulty'] == targetDifficulty) || m['difficulty'] == null)
        .toList();
    final pool = filtered.isNotEmpty ? filtered : list;
    // Prefer words not used in this session
    final fresh = pool.where((m) => !_usedWords.contains(m['word'])).toList();
    final selectionPool = fresh.isNotEmpty ? fresh : pool;
    if (list.isEmpty) {
      return {
        'word': 'FLUTTER',
        'hints': json.encode([
          {'category': 'İpucu', 'text': 'Google’ın UI aracı'}
        ])
      };
    }
    return selectionPool[_random.nextInt(selectionPool.length)];
  }

  void _spinWheel() {
    if (_spinning) return;
    setState(() => _spinning = true);
    final spins = 5 + _random.nextInt(4); // 5-8 tam tur
    final targetIndex = _random.nextInt(_segments.length);
    final perSlice = 2 * pi / _segments.length;
    // Pointer üstte olduğu için (pi/2) ofsetini hesaba kat
    final targetAngle =
        spins * 2 * pi + targetIndex * perSlice - (pi / 2) + perSlice / 2;
    _rotation = Tween<double>(
            begin: _rotation.value % (2 * pi), end: targetAngle)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  String _resultFromAngle(double angle) {
    // Çarkın tepesindeki göstergeye göre sonuç
    final norm = (angle + pi / 2) % (2 * pi);
    final perSlice = 2 * pi / _segments.length;
    final index = (norm / perSlice).floor() % _segments.length;
    return _segments[index];
  }

  void _guessLetter() async {
    final last = _logic.lastSpin;
    if (last == null || last == 'İflas' || last == 'Pas') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce çarkı çevir ve sayı gelmeli.')),
      );
      return;
    }

    final letter = await _askForLetter();
    if (letter == null || letter.isEmpty) return;
    if (GameLogic.isVowel(letter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesli harf satın alınır (200 puan).')),
      );
      return;
    }
    final count = _logic.revealLetter(letter[0]);
    final value = int.tryParse(last.replaceAll('+', '')) ?? 0;
    if (count > 0) {
      _logic.rewardForGuess(value, count);
      final total = value * count;
      final ch = letter[0].toUpperCase();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doğru: $ch x $count = +$total puan'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
      if (_logic.isSolved) {
        _showWinDialog();
      }
    } else {
      setState(() {
        _logic.switchTurn();
      });
    }
    // Her harf denemesinden sonra tekrar spin zorunlu olsun
    _logic.lastSpin = null;
  }

  void _buyVowel() async {
    final controller = TextEditingController();
    final letter = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sesli Harf Satın Al (200)'),
        content: TextField(
          controller: controller,
          maxLength: 1,
          decoration:
              const InputDecoration(hintText: 'Bir sesli harf gir (AEIİOÖUÜ)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Satın Al'),
          ),
        ],
      ),
    );
    if (letter == null || letter.isEmpty) return;
    if (!GameLogic.isVowel(letter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu bir sesli harf değil.')),
      );
      return;
    }
    final result = _logic.buyVowel(letter);
    if (result == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetersiz puan (200 gerekli).')),
      );
      return;
    }
    if (result > 0) {
      setState(() {});
      if (_logic.isSolved) _showWinDialog();
    } else {
      setState(() => _logic.switchTurn());
    }
  }

  void _useJoker() {
    final letter = _logic.useJoker(_random);
    if (letter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joker kullanılamıyor.')),
      );
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joker açtı: $letter')),
    );
    if (_logic.isSolved) _showWinDialog();
  }

  Future<String?> _askForLetter() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Harf Tahmini'),
        content: TextField(
          controller: controller,
          maxLength: 1,
          decoration: const InputDecoration(hintText: 'Bir harf gir'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _guessWord() async {
    final controller = TextEditingController();
    final guess = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kelime Tahmini'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tüm kelimeyi yaz'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tahmin Et'),
          ),
        ],
      ),
    );
    if (guess == null || guess.isEmpty) return;
    if (_normalizeTr(guess) == _normalizeTr(_logic.secretWord)) {
      setState(() {
        for (final ch in _logic.secretWord.characters) {
          if (GameLogic._isLetter(ch))
            _logic.revealed.add(GameLogic._normalize(ch));
        }
      });
      _showWinDialog();
    } else {
      setState(() => _logic.switchTurn());
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Text(
            '${_logic.players[_logic.currentPlayerIndex]} kelimeyi bildi!\n\nKelime: ${_logic.secretWord}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              _startNextWord();
            },
            child: const Text('Devam Et'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // exit game screen
            },
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }

  void _startNextWord() {
    final picked = _pickFromAssets();
    final newLogic = GameLogic(
      players: List<String>.from(_logic.players),
      secretWord: picked['word']!,
    );
    // Carry over scores
    for (int i = 0; i < _logic.scores.length; i++) {
      newLogic.scores[i] = _logic.scores[i];
    }
    final hints = (json.decode(picked['hints']!) as List).cast<Map>();
    setState(() {
      _logic = newLogic;
      _hintCategory = '${hints.first['category']}';
      _hintText = '${hints.first['text']}';
      _logic.lastSpin = null;
      _spinning = false;
      _usedWords.add(picked['word']!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Difficulty by grade: choose pool based on user's grade (if provided via route)
    // We expect profile passed into widget; use its grade to bias selection size implicitly via asset lists order.
    final wheel = SizedBox(
      height: min(300, MediaQuery.of(context).size.width * 0.7),
      width: min(300, MediaQuery.of(context).size.width * 0.7),
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotation.value,
            child: CustomPaint(
              painter: _WheelPainter(segments: _segments),
            ),
          );
        },
      ),
    );

    final pointer = Positioned(
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 28),
      ),
    );

    final wordBoxes = SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _logic.secretWord.characters.map((ch) {
            final isLetter = GameLogic._isLetter(ch);
            final show =
                !isLetter || _logic.revealed.contains(GameLogic._normalize(ch));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 36,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  show ? ch.toUpperCase() : '_',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    final scoreboard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Puan Tablosu',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (int i = 0; i < _logic.players.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: i == _logic.currentPlayerIndex
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_logic.players[i],
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${_logic.scores[i]}'),
              ],
            ),
          ),
      ],
    );

    final bool canGuessLetter =
        _logic.lastSpin != null && _logic.lastSpin!.startsWith('+');
    final controls = Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _spinning ? null : _spinWheel,
          icon: const Icon(Icons.casino),
          label: const Text('Çarkı Çevir'),
        ),
        ElevatedButton.icon(
          onPressed: canGuessLetter ? _guessLetter : null,
          icon: const Icon(Icons.font_download),
          label: const Text('Harf Tahmin Et'),
        ),
        OutlinedButton(
          onPressed: _guessWord,
          child: const Text('Kelimeyi Tahmin Et'),
        ),
        OutlinedButton.icon(
          onPressed: _buyVowel,
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Sesli (200)'),
        ),
        OutlinedButton.icon(
          onPressed: _useJoker,
          icon: const Icon(Icons.stars),
          label: const Text('Joker'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎡 ÇARKIGO!'),
        backgroundColor: Colors.deepPurple,
        actions: const [],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          final centerBody = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      selected: _singlePlayer,
                      label: const Text('Tek Kişilik'),
                      onSelected: (v) {
                        if (v) {
                          setState(() {
                            _singlePlayer = true;
                            final p = _pickFromAssets();
                            final hints =
                                (json.decode(p['hints']!) as List).cast<Map>();
                            _hintCategory = '${hints.first['category']}';
                            _hintText = '${hints.first['text']}';
                            _logic = GameLogic(
                              players: ['Oyuncu'],
                              secretWord: p['word']!,
                            );
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      selected: !_singlePlayer,
                      label: const Text('Çift Kişilik'),
                      onSelected: (v) {
                        if (v) {
                          setState(() {
                            _singlePlayer = false;
                            final p = _pickFromAssets();
                            final hints =
                                (json.decode(p['hints']!) as List).cast<Map>();
                            _hintCategory = '${hints.first['category']}';
                            _hintText = '${hints.first['text']}';
                            _logic = GameLogic(
                              players: ['Oyuncu 1', 'Oyuncu 2'],
                              secretWord: p['word']!,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              wordBoxes,
              const SizedBox(height: 8),
              if (_hintText != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      if (_hintCategory != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hintCategory!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Column(
                        children: [
                          Text(
                            _hintText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'İpucu: ${_hintCategory ?? 'Genel'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          // Cost for next hint scales with grade: ilkokul 50, ortaokul 100, lise 150
                          int cost = 100;
                          final grade = widget.profile.grade;
                          if (grade != null) {
                            if (grade <= 4)
                              cost = 50;
                            else if (grade <= 8)
                              cost = 100;
                            else
                              cost = 150;
                          }
                          // Deduct locally from current player's score if possible; else do nothing
                          if (_logic.scores[_logic.currentPlayerIndex] < cost) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Yetersiz puan: $cost gerekir')),
                            );
                            return;
                          }
                          setState(() {
                            _logic.scores[_logic.currentPlayerIndex] -= cost;
                          });
                          final list =
                              _singlePlayer ? _singleItems : _multiItems;
                          final current = list.firstWhere(
                            (e) => e['word'] == _logic.secretWord,
                            orElse: () => {
                              'word': _logic.secretWord,
                              'hints':
                                  '[{"category":"İpucu","text":"İpucu yok"}]'
                            },
                          );
                          final hints = (json.decode(current['hints']!) as List)
                              .cast<Map>();
                          // rotate hint
                          final next = hints.length <= 1
                              ? hints.first
                              : hints[(hints.indexWhere(
                                          (h) => '${h['text']}' == _hintText) +
                                      1) %
                                  hints.length];
                          setState(() {
                            _hintCategory = '${next['category']}';
                            _hintText = '${next['text']}';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'İpucu açıldı (-$cost). Yeni skor: ${_logic.scores[_logic.currentPlayerIndex]}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tips_and_updates_outlined),
                        label: const Text('Başka ipucu (puan düşer)'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              const SizedBox(height: 20),
              SizedBox(
                height: min(320, MediaQuery.of(context).size.width * 0.75),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    wheel,
                    pointer,
                  ],
                ),
              ),
              const SizedBox(height: 16),
              controls,
              const SizedBox(height: 16),
              if (_logic.lastSpin != null)
                Text('Sonuç: ${_logic.lastSpin!}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Center(
                        child: SingleChildScrollView(child: centerBody))),
                Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  child: scoreboard,
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  centerBody,
                  const SizedBox(height: 12),
                  scoreboard,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> segments;
  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final per = 2 * pi / segments.length;
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < segments.length; i++) {
      paint.color = i.isEven ? Colors.orange : Colors.amber;
      final start = i * per;
      canvas.drawArc(rect, start, per, true, paint);
      // Label
      final angle = start + per / 2;
      final offset = Offset(center.dx + (radius * 0.6) * cos(angle),
          center.dy + (radius * 0.6) * sin(angle));
      textPainter.text = TextSpan(
        text: segments[i],
        style: const TextStyle(
            fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(offset.dx - textPainter.width / 2,
          offset.dy - textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
    // Outer ring
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.brown;
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}
