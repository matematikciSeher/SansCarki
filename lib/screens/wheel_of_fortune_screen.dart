import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:characters/characters.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static String _normalize(String ch) {
    if (ch == 'i') return 'İ';
    if (ch == 'ı') return 'I';
    return ch.toUpperCase();
  }

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
  List<Map<String, String>> _singleItems = [];
  bool _loading = true;
  final Set<String> _usedWords = {};
  int _lastTickIndex = -1;
  bool _showIntro = true;
  int? _pendingTargetIndex; // Seçilen dilim indeksi
  bool _sessionSaved = false;

  final List<String> _segments = const [
    '+100',
    '+200',
    '+300',
    '+400',
    '+500',
    '+700',
    '+900',
    '+1200',
    '+1500',
    '+2000',
    'Pas',
    'İflas'
  ];

  String _normalizeTr(String input) {
    final buffer = StringBuffer();
    for (final ch in input.trim().characters) {
      if (ch == 'i')
        buffer.write('İ');
      else if (ch == 'ı')
        buffer.write('I');
      else
        buffer.write(ch.toUpperCase());
    }
    return buffer.toString();
  }

  String _lettersOnlyUpper(String input) {
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      if (GameLogic._isLetter(ch)) {
        buffer.write(GameLogic._normalize(ch));
      }
    }
    return buffer.toString();
  }

  String _normalizeDifficulty(String? input) {
    var s = (input ?? '').trim();
    if (s.isEmpty) return 'medium';
    // Turkish lowercase nuances
    s = s.replaceAll('İ', 'i').replaceAll('ı', 'i').toLowerCase();
    if (s == 'easy' || s == 'kolay' || s == 'ilkokul' || s == '1-4') {
      return 'easy';
    }
    if (s == 'medium' || s == 'orta' || s == 'ortaokul' || s == '5-8') {
      return 'medium';
    }
    if (s == 'hard' || s == 'zor' || s == 'lise' || s == '9-12') {
      return 'hard';
    }
    return 'medium';
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
          players: ['Oyuncu'],
          secretWord: initial['word']!,
        );
        _usedWords.add(initial['word']!);
        _loading = false;
      });
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
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
          final result = (_pendingTargetIndex != null)
              ? _segments[_pendingTargetIndex!]
              : _resultFromAngle(_rotation.value);
          _pendingTargetIndex = null;
          _logic.applySpinResult(result);

          // Çark durduktan sonra popup aç
          _showActionPopup(result);

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
    // Eğer Bitir'e basmadan çıkılırsa, puanı kaybetme diye sessizce kaydet
    if (!_sessionSaved) {
      _saveSessionGamePoints();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final jsonStr = await DefaultAssetBundle.of(context)
        .loadString('assets/words_hints.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    List<Map<String, String>> collect = [];

    String normDiff(String tag) => _normalizeDifficulty(tag);
    List<Map<String, String>> mapWords(List words, String diffTag) {
      return words
          .map((e) {
            final m = e as Map<String, dynamic>;
            final raw = (m['word'] ?? m['kelime'] ?? '').toString();
            final hintText =
                (m['ipuç'] ?? m['ipucu'] ?? m['hint'] ?? m['hints'] ?? '')
                    .toString();
            final word = raw.toString();
            final hintsList = (m['hints'] is List)
                ? (m['hints'] as List)
                : [
                    {
                      'category': 'İpucu',
                      'text': hintText.isNotEmpty
                          ? hintText
                          : 'Kelime hakkında ipucu'
                    },
                    {'category': 'İpucu', 'text': 'Kategori: Kelime'},
                    {'category': 'İpucu', 'text': 'Seviye: $diffTag'},
                  ];
            return {
              'word': _normalizeTr(word.toString()),
              'hints': json.encode(hintsList),
              'difficulty': normDiff(diffTag),
            };
          })
          .cast<Map<String, String>>()
          .toList();
    }

    List<Map<String, String>> mapAtasozleri(
        List<dynamic> list, String diffTag) {
      return list
          .map((it) {
            if (it is String) {
              return {
                'word': _normalizeTr(it),
                'hints': json.encode([
                  {
                    'category': 'Atasözü',
                    'text': 'Geleneksel bir öğüt içerir.'
                  },
                  {'category': 'Atasözü', 'text': 'Günlük hayatta kullanılır.'},
                  {'category': 'Atasözü', 'text': 'Seviye: $diffTag'},
                ]),
                'difficulty': normDiff(diffTag),
              };
            } else {
              final m = it as Map<String, dynamic>;
              return {
                'word':
                    _normalizeTr((m['word'] ?? m['kelime'] ?? '').toString()),
                'hints': json.encode(m['hints'] ??
                    [
                      {
                        'category': 'Atasözü',
                        'text': 'Geleneksel bir öğüt içerir.'
                      },
                      {
                        'category': 'Atasözü',
                        'text': 'Günlük hayatta kullanılır.'
                      },
                      {'category': 'Atasözü', 'text': 'Seviye: $diffTag'},
                    ]),
                'difficulty': normDiff(diffTag),
              };
            }
          })
          .cast<Map<String, String>>()
          .toList();
    }

    if (data.containsKey('single')) {
      // Old schema
      _singleItems = (data['single'] as List)
          .map((e) {
            final m = e as Map<String, dynamic>;
            return {
              'word': '${m['word']}',
              'hints': json.encode(m['hints']),
              'difficulty': _normalizeDifficulty(m['difficulty']?.toString()),
            };
          })
          .cast<Map<String, String>>()
          .toList();
      final extra =
          mapAtasozleri((data['atasozleri'] as List?) ?? const [], 'medium');
      _singleItems.addAll(extra);
    } else if (data.containsKey('ilkokul') ||
        data.containsKey('ortaokul') ||
        data.containsKey('lise')) {
      // New schema
      final ilkokul = (data['ilkokul'] as Map<String, dynamic>?);
      final ortaokul = (data['ortaokul'] as Map<String, dynamic>?);
      final lise = (data['lise'] as Map<String, dynamic>?);

      if (ilkokul != null) {
        collect.addAll(
            mapWords((ilkokul['kelimeler'] as List?) ?? const [], 'easy'));
        collect.addAll(mapAtasozleri(
            (ilkokul['atasozleri'] as List?) ?? const [], 'easy'));
      }
      if (ortaokul != null) {
        collect.addAll(
            mapWords((ortaokul['kelimeler'] as List?) ?? const [], 'medium'));
        collect.addAll(mapAtasozleri(
            (ortaokul['atasozleri'] as List?) ?? const [], 'medium'));
      }
      if (lise != null) {
        collect
            .addAll(mapWords((lise['kelimeler'] as List?) ?? const [], 'hard'));
        collect.addAll(
            mapAtasozleri((lise['atasozleri'] as List?) ?? const [], 'hard'));
      }

      _singleItems = collect;
    } else {
      // Fallback minimal
      _singleItems = [
        {
          'word': 'FLUTTER',
          'hints': json.encode([
            {'category': 'İpucu', 'text': 'Google’ın UI aracı'}
          ]),
          'difficulty': 'medium',
        }
      ];
    }
  }

  Map<String, String> _pickFromAssets() {
    final list = _singleItems;
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
    final spins = 8 + _random.nextInt(5); // 8-12 tam tur, daha uzun
    final targetIndex = _random.nextInt(_segments.length);
    _pendingTargetIndex = targetIndex;
    final perSlice = 2 * pi / _segments.length;
    // Pointer üstte, tepe noktası -pi/2 yönünde. Dilim merkezini oraya hizala:
    // hedef açı = k*2π - (pi/2 + per/2) - index*per
    final targetAngle =
        spins * 2 * pi - (pi / 2 + perSlice / 2) - targetIndex * perSlice;
    _rotation = Tween<double>(
            begin: _rotation.value % (2 * pi), end: targetAngle)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward(from: 0);
  }

  String _resultFromAngle(double angle) {
    // Çarkın tepesindeki göstergeye göre sonuç
    final norm = (angle + pi / 2) % (2 * pi);
    final perSlice = 2 * pi / _segments.length;
    final index = ((norm + perSlice / 2) / perSlice).floor() % _segments.length;
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
      final ch = _normalizeTr(letter[0]);
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
    final g = _lettersOnlyUpper(guess);
    final target = _lettersOnlyUpper(_logic.secretWord);
    if (g == target) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${_logic.players[_logic.currentPlayerIndex]} kelimeyi bildi!'),
            const SizedBox(height: 8),
            Text('Kelime: ${_logic.secretWord}'),
            const SizedBox(height: 8),
            Text('Oturum Toplam Puanı: ' +
                (_logic.scores.isNotEmpty
                        ? _logic.scores.reduce((a, b) => a + b)
                        : 0)
                    .toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              // Her kelime tamamlandığında puanları kaydet
              await _saveSessionGamePoints();
              _startNextWord();
            },
            child: const Text('Devam Et'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await _saveSessionGamePoints();
              try {
                final prefs = await SharedPreferences.getInstance();
                final raw = prefs.getString('user_profile');
                if (raw != null) {
                  final profile = UserProfile.fromJson(json.decode(raw));
                  if (context.mounted) {
                    Navigator.pop(
                        context, profile); // exit with updated profile
                  }
                } else {
                  if (context.mounted) Navigator.pop(context);
                }
              } catch (_) {
                if (context.mounted) Navigator.pop(context);
              }
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
      height: min(260, MediaQuery.of(context).size.width * 0.6),
      width: min(260, MediaQuery.of(context).size.width * 0.6),
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
      child: Builder(builder: (context) {
        final hasSpaces = _logic.secretWord.contains(' ');
        final maxWordWidth =
            MediaQuery.of(context).size.width - 32; // padding payı
        if (!hasSpaces) {
          // Tek kelime: tek satırda ölçekleyerek göster
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _logic.secretWord.characters.map((ch) {
                final isLetter = GameLogic._isLetter(ch);
                final show = !isLetter ||
                    _logic.revealed.contains(GameLogic._normalize(ch));
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
                      show ? _normalizeTr(ch) : '_',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.5),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }
        // Çok kelimeli: kelimelere göre satır başı ile Wrap kullan
        final words = _logic.secretWord.split(' ');
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: words.map((word) {
            if (word.isEmpty) return const SizedBox(width: 0, height: 0);
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWordWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: word.characters.map((ch) {
                    final isLetter = GameLogic._isLetter(ch);
                    final show = !isLetter ||
                        _logic.revealed.contains(GameLogic._normalize(ch));
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 34,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          show ? _normalizeTr(ch) : '_',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );

    final scoreboard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Puan Tablosu',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snap) {
            final saved = (snap.data?.getString('user_profile'));
            int totalGame = 0;
            if (saved != null) {
              try {
                final map = json.decode(saved) as Map<String, dynamic>;
                totalGame = (map['totalGamePoints'] ?? 0) as int;
              } catch (_) {}
            }
            return Text('Kayıtlı Oyun Puanı: $totalGame',
                style: const TextStyle(fontSize: 12));
          },
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < _logic.players.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(6),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Bilgi',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çarkıfelek Bilgi'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Amaç: Gizli kelimeyi bul.'),
                        SizedBox(height: 6),
                        Text('• Adımlar:'),
                        Text('  1) Çarkı çevir. Sayı gelirse harf tahmin et.'),
                        Text(
                            '  2) Doğru harf sayısı × çarktaki puan kadar kazanırsın.'),
                        Text(
                            '  3) Pas gelirse sıra değişir (tek oyuncuda tur boşa geçer).'),
                        Text(
                            '  4) İflas gelirse puanın sıfırlanır ve sıra değişir.'),
                        SizedBox(height: 8),
                        Text('• Sesli Harf: 200 puana satın alınır.'),
                        Text(
                            '• Joker: Bir gizli harfi açar (her oyuncu 1 kez).'),
                        SizedBox(height: 8),
                        Text('• Puan Dilimleri: 100 – 2000 arasında değişir.'),
                        SizedBox(height: 8),
                        Text(
                            '• Çok kelimeli ifadeler (atasözleri) satır kırarak gösterilir.'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _showIntro
          ? _buildInfoPage()
          : LayoutBuilder(
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
                    else ...[
                      const SizedBox(height: 12),
                      wordBoxes,
                      const SizedBox(height: 8),
                    ],
                    if (!_loading && _hintText != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.4)),
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
                            const SizedBox(height: 2),
                            Column(
                              children: [
                                Text(
                                  _hintText!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'İpucu: ${_hintCategory ?? 'Genel'}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
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
                                if (_logic.scores[_logic.currentPlayerIndex] <
                                    cost) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Yetersiz puan: $cost gerekir')),
                                  );
                                  return;
                                }
                                setState(() {
                                  _logic.scores[_logic.currentPlayerIndex] -=
                                      cost;
                                });
                                final list = _singleItems;
                                final current = list.firstWhere(
                                  (e) => e['word'] == _logic.secretWord,
                                  orElse: () => {
                                    'word': _logic.secretWord,
                                    'hints':
                                        '[{"category":"İpucu","text":"İpucu yok"}]'
                                  },
                                );
                                final hints =
                                    (json.decode(current['hints']!) as List)
                                        .cast<Map>();
                                // rotate hint
                                final next = hints.length <= 1
                                    ? hints.first
                                    : hints[(hints.indexWhere((h) =>
                                                '${h['text']}' == _hintText) +
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
                    const SizedBox(height: 8),
                    const SizedBox(height: 12),
                    if (!_loading)
                      SizedBox(
                        height:
                            min(280, MediaQuery.of(context).size.width * 0.65),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            wheel,
                            pointer,
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!_loading) controls,
                    const SizedBox(height: 8),
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
                        child: !_loading ? scoreboard : const SizedBox(),
                      ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        if (!_loading) scoreboard,
                        const SizedBox(height: 8),
                        centerBody,
                      ],
                    ),
                  ),
                );
              },
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
            Colors.deepPurple.shade900,
            Colors.deepPurple.shade600,
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
                  '🎡 Çarkıfelek',
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
                    'Kurallar:\n\n• Çarkı çevir; sayı gelirse harf tahmin et.\n• Doğru harf sayısı × çark puanı kadar kazan.\n• Pas: (tek oyuncuda) tur boşa geçer.\n• İflas: puanın sıfırlanır.\n• İstersen tüm kelimeyi tahmin edebilirsin.\n• Sesli harf: 200 puan; Joker: bir harfi açar (1 kez).\n',
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
                    'Puanlama:\n\n• Dilimler: 100 – 2000\n• İpucu maliyeti: İlkokul 50 / Ortaokul 100 / Lise 150\n• Çok kelimeli ifadeler satır kırılarak gösterilir.\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => setState(() => _showIntro = false),
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

  Future<void> _saveSessionGamePoints() async {
    if (_sessionSaved) return;
    // Tek oyuncu olduğu için tüm skor toplamı oyuncunun skoru
    final earned =
        _logic.scores.isNotEmpty ? _logic.scores.reduce((a, b) => a + b) : 0;
    if (earned <= 0) {
      _sessionSaved = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_profile');
      if (raw != null) {
        final map = json.decode(raw) as Map<String, dynamic>;
        final profile = UserProfile.fromJson(map);
        final newTotal = (profile.totalGamePoints ?? 0) + earned;
        final updated = profile.copyWith(totalGamePoints: newTotal);
        await prefs.setString('user_profile', json.encode(updated.toJson()));

        // Puan kaydedildiğini bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('+$earned puan kaydedildi! Toplam: $newTotal'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      // yut
    }
    _sessionSaved = true;
  }

  // Çark durduktan sonra açılacak popup fonksiyonu
  void _showActionPopup(String result) {
    // Sadece sayı sonuçları için popup aç (İflas ve Pas için değil)
    if (result == 'İflas' || result == 'Pas') return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Flexible(
                child: Text(
                  '🎯 Çark Sonucu: $result',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ne yapmak istiyorsun?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _guessLetter();
                  },
                  icon: const Icon(Icons.font_download),
                  label: const Text('Harf Tahmin Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _guessWord();
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Kelime Tahmin Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _buyVowel();
                  },
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Sesli Harf Satın Al (200 puan)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _useJoker();
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Joker Kullan (1 kez)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mevcut Puan: ${_logic.scores[_logic.currentPlayerIndex]}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
          ],
        );
      },
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
      canvas.translate(offset.dx, offset.dy);
      // Dikey yazı: -90° döndür
      canvas.rotate(-pi / 2);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
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
