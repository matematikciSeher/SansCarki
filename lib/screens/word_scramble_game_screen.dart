import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/user_profile.dart';

class WordBombGameScreen extends StatefulWidget {
  final UserProfile profile;

  const WordBombGameScreen({
    super.key,
    required this.profile,
  });

  @override
  State<WordBombGameScreen> createState() => _WordBombGameScreenState();
}

class _WordBombGameScreenState extends State<WordBombGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _balloonAnimationController;
  late AnimationController _explosionController;
  late Animation<double> _explosionScaleAnimation;

  final List<WordPair> _allWords = [
    // Meyveler (15 kelime)
    WordPair(english: 'apple', turkish: 'elma', emoji: '🍎'),
    WordPair(english: 'banana', turkish: 'muz', emoji: '🍌'),
    WordPair(english: 'orange', turkish: 'portakal', emoji: '🍊'),
    WordPair(english: 'grape', turkish: 'üzüm', emoji: '🍇'),
    WordPair(english: 'pear', turkish: 'armut', emoji: '🍐'),
    WordPair(english: 'kiwi', turkish: 'kivi', emoji: '🥝'),
    WordPair(english: 'strawberry', turkish: 'çilek', emoji: '🍓'),
    WordPair(english: 'watermelon', turkish: 'karpuz', emoji: '🍉'),
    WordPair(english: 'pineapple', turkish: 'ananas', emoji: '🍍'),
    WordPair(english: 'cherry', turkish: 'kiraz', emoji: '🍒'),
    WordPair(english: 'lemon', turkish: 'limon', emoji: '🍋'),
    WordPair(english: 'peach', turkish: 'şeftali', emoji: '🍑'),
    WordPair(english: 'plum', turkish: 'erik', emoji: '🫐'),
    WordPair(english: 'apricot', turkish: 'kayısı', emoji: '🍑'),
    WordPair(english: 'fig', turkish: 'incir', emoji: '🫒'),

    // Hayvanlar (15 kelime)
    WordPair(english: 'dog', turkish: 'köpek', emoji: '🐶'),
    WordPair(english: 'cat', turkish: 'kedi', emoji: '🐱'),
    WordPair(english: 'bird', turkish: 'kuş', emoji: '🐦'),
    WordPair(english: 'fish', turkish: 'balık', emoji: '🐠'),
    WordPair(english: 'rabbit', turkish: 'tavşan', emoji: '🐰'),
    WordPair(english: 'horse', turkish: 'at', emoji: '🐴'),
    WordPair(english: 'cow', turkish: 'inek', emoji: '🐮'),
    WordPair(english: 'pig', turkish: 'domuz', emoji: '🐷'),
    WordPair(english: 'sheep', turkish: 'koyun', emoji: '🐑'),
    WordPair(english: 'chicken', turkish: 'tavuk', emoji: '🐔'),
    WordPair(english: 'duck', turkish: 'ördek', emoji: '🦆'),
    WordPair(english: 'goose', turkish: 'kaz', emoji: '🦢'),
    WordPair(english: 'turkey', turkish: 'hindi', emoji: '🦃'),
    WordPair(english: 'goat', turkish: 'keçi', emoji: '🐐'),
    WordPair(english: 'donkey', turkish: 'eşek', emoji: '🦙'),

    // Ev ve Ulaşım (15 kelime)
    WordPair(english: 'house', turkish: 'ev', emoji: '🏠'),
    WordPair(english: 'car', turkish: 'araba', emoji: '🚗'),
    WordPair(english: 'tree', turkish: 'ağaç', emoji: '🌳'),
    WordPair(english: 'flower', turkish: 'çiçek', emoji: '🌸'),
    WordPair(english: 'sun', turkish: 'güneş', emoji: '☀️'),
    WordPair(english: 'moon', turkish: 'ay', emoji: '🌙'),
    WordPair(english: 'star', turkish: 'yıldız', emoji: '⭐'),
    WordPair(english: 'cloud', turkish: 'bulut', emoji: '☁️'),
    WordPair(english: 'rain', turkish: 'yağmur', emoji: '🌧️'),
    WordPair(english: 'snow', turkish: 'kar', emoji: '❄️'),
    WordPair(english: 'bus', turkish: 'otobüs', emoji: '🚌'),
    WordPair(english: 'train', turkish: 'tren', emoji: '🚂'),
    WordPair(english: 'bicycle', turkish: 'bisiklet', emoji: '🚲'),
    WordPair(english: 'boat', turkish: 'tekne', emoji: '🚢'),
    WordPair(english: 'airplane', turkish: 'uçak', emoji: '✈️'),

    // Okul ve Eğitim (15 kelime)
    WordPair(english: 'book', turkish: 'kitap', emoji: '📚'),
    WordPair(english: 'pencil', turkish: 'kalem', emoji: '✏️'),
    WordPair(english: 'school', turkish: 'okul', emoji: '🏫'),
    WordPair(english: 'teacher', turkish: 'öğretmen', emoji: '👨‍🏫'),
    WordPair(english: 'student', turkish: 'öğrenci', emoji: '👨‍🎓'),
    WordPair(english: 'friend', turkish: 'arkadaş', emoji: '👥'),
    WordPair(english: 'family', turkish: 'aile', emoji: '👨‍👩‍👧‍👦'),
    WordPair(english: 'mother', turkish: 'anne', emoji: '👩'),
    WordPair(english: 'father', turkish: 'baba', emoji: '👨'),
    WordPair(english: 'baby', turkish: 'bebek', emoji: '👶'),
    WordPair(english: 'sister', turkish: 'kız kardeş', emoji: '👧'),
    WordPair(english: 'brother', turkish: 'erkek kardeş', emoji: '👦'),
    WordPair(english: 'grandmother', turkish: 'büyükanne', emoji: '👵'),
    WordPair(english: 'grandfather', turkish: 'büyükbaba', emoji: '👴'),
    WordPair(english: 'uncle', turkish: 'amca', emoji: '👨'),

    // Renkler ve Sıfatlar (15 kelime)
    WordPair(english: 'red', turkish: 'kırmızı', emoji: '🔴'),
    WordPair(english: 'blue', turkish: 'mavi', emoji: '🔵'),
    WordPair(english: 'green', turkish: 'yeşil', emoji: '🟢'),
    WordPair(english: 'yellow', turkish: 'sarı', emoji: '🟡'),
    WordPair(english: 'black', turkish: 'siyah', emoji: '⚫'),
    WordPair(english: 'white', turkish: 'beyaz', emoji: '⚪'),
    WordPair(english: 'big', turkish: 'büyük', emoji: '🔴'),
    WordPair(english: 'small', turkish: 'küçük', emoji: '🔵'),
    WordPair(english: 'hot', turkish: 'sıcak', emoji: '🔥'),
    WordPair(english: 'cold', turkish: 'soğuk', emoji: '❄️'),
    WordPair(english: 'long', turkish: 'uzun', emoji: '📏'),
    WordPair(english: 'short', turkish: 'kısa', emoji: '📐'),
    WordPair(english: 'new', turkish: 'yeni', emoji: '🆕'),
    WordPair(english: 'old', turkish: 'eski', emoji: '🆖'),
    WordPair(english: 'beautiful', turkish: 'güzel', emoji: '✨'),

    // Duygular ve Değerler (15 kelime)
    WordPair(english: 'happy', turkish: 'mutlu', emoji: '😊'),
    WordPair(english: 'sad', turkish: 'üzgün', emoji: '😢'),
    WordPair(english: 'good', turkish: 'iyi', emoji: '👍'),
    WordPair(english: 'bad', turkish: 'kötü', emoji: '👎'),
    WordPair(english: 'love', turkish: 'aşk', emoji: '❤️'),
    WordPair(english: 'hate', turkish: 'nefret', emoji: '💔'),
    WordPair(english: 'angry', turkish: 'kızgın', emoji: '😠'),
    WordPair(english: 'excited', turkish: 'heyecanlı', emoji: '🤩'),
    WordPair(english: 'tired', turkish: 'yorgun', emoji: '😴'),
    WordPair(english: 'strong', turkish: 'güçlü', emoji: '💪'),
    WordPair(english: 'weak', turkish: 'zayıf', emoji: '😰'),
    WordPair(english: 'brave', turkish: 'cesur', emoji: '😤'),
    WordPair(english: 'scared', turkish: 'korkmuş', emoji: '😨'),
    WordPair(english: 'surprised', turkish: 'şaşkın', emoji: '😲'),
    WordPair(english: 'confused', turkish: 'karışık', emoji: '😵'),

    // Yiyecek ve İçecek (15 kelime)
    WordPair(english: 'bread', turkish: 'ekmek', emoji: '🍞'),
    WordPair(english: 'milk', turkish: 'süt', emoji: '🥛'),
    WordPair(english: 'cheese', turkish: 'peynir', emoji: '🧀'),
    WordPair(english: 'egg', turkish: 'yumurta', emoji: '🥚'),
    WordPair(english: 'rice', turkish: 'pirinç', emoji: '🍚'),
    WordPair(english: 'meat', turkish: 'et', emoji: '🥩'),
    WordPair(english: 'soup', turkish: 'çorba', emoji: '🍲'),
    WordPair(english: 'cake', turkish: 'pasta', emoji: '🍰'),
    WordPair(english: 'ice cream', turkish: 'dondurma', emoji: '🍦'),
    WordPair(english: 'juice', turkish: 'meyve suyu', emoji: '🧃'),
    WordPair(english: 'water', turkish: 'su', emoji: '💧'),
    WordPair(english: 'tea', turkish: 'çay', emoji: '🫖'),
    WordPair(english: 'coffee', turkish: 'kahve', emoji: '☕'),
    WordPair(english: 'chocolate', turkish: 'çikolata', emoji: '🍫'),
    WordPair(english: 'candy', turkish: 'şeker', emoji: '🍬'),

    // Meslekler (15 kelime)
    WordPair(english: 'doctor', turkish: 'doktor', emoji: '👨‍⚕️'),
    WordPair(english: 'nurse', turkish: 'hemşire', emoji: '👩‍⚕️'),
    WordPair(english: 'police', turkish: 'polis', emoji: '👮'),
    WordPair(english: 'fireman', turkish: 'itfaiyeci', emoji: '👨‍🚒'),
    WordPair(english: 'cook', turkish: 'aşçı', emoji: '👨‍🍳'),
    WordPair(english: 'driver', turkish: 'şoför', emoji: '🚗'),
    WordPair(english: 'pilot', turkish: 'pilot', emoji: '✈️'),
    WordPair(english: 'soldier', turkish: 'asker', emoji: '🎖️'),
    WordPair(english: 'farmer', turkish: 'çiftçi', emoji: '👨‍🌾'),
    WordPair(english: 'artist', turkish: 'sanatçı', emoji: '🎨'),
    WordPair(english: 'teacher', turkish: 'öğretmen', emoji: '👨‍🏫'),
    WordPair(english: 'engineer', turkish: 'mühendis', emoji: '👷'),
    WordPair(english: 'lawyer', turkish: 'avukat', emoji: '👨‍💼'),
    WordPair(english: 'dentist', turkish: 'diş hekimi', emoji: '👨‍⚕️'),
    WordPair(english: 'veterinarian', turkish: 'veteriner', emoji: '👨‍⚕️'),

    // Spor ve Oyun (15 kelime)
    WordPair(english: 'football', turkish: 'futbol', emoji: '⚽'),
    WordPair(english: 'basketball', turkish: 'basketbol', emoji: '🏀'),
    WordPair(english: 'tennis', turkish: 'tenis', emoji: '🎾'),
    WordPair(english: 'swimming', turkish: 'yüzme', emoji: '🏊'),
    WordPair(english: 'running', turkish: 'koşu', emoji: '🏃'),
    WordPair(english: 'dancing', turkish: 'dans', emoji: '💃'),
    WordPair(english: 'singing', turkish: 'şarkı', emoji: '🎤'),
    WordPair(english: 'painting', turkish: 'resim', emoji: '🎨'),
    WordPair(english: 'reading', turkish: 'okuma', emoji: '📖'),
    WordPair(english: 'writing', turkish: 'yazma', emoji: '✍️'),
    WordPair(english: 'cycling', turkish: 'bisiklet', emoji: '🚴'),
    WordPair(english: 'hiking', turkish: 'yürüyüş', emoji: '🥾'),
    WordPair(english: 'fishing', turkish: 'balık tutma', emoji: '🎣'),
    WordPair(english: 'camping', turkish: 'kamp', emoji: '⛺'),
    WordPair(english: 'gardening', turkish: 'bahçıvanlık', emoji: '🌱'),

    // Vücut ve Sağlık (15 kelime)
    WordPair(english: 'head', turkish: 'baş', emoji: '👤'),
    WordPair(english: 'hand', turkish: 'el', emoji: '✋'),
    WordPair(english: 'leg', turkish: 'bacak', emoji: '🦵'),
    WordPair(english: 'eye', turkish: 'göz', emoji: '👁️'),
    WordPair(english: 'ear', turkish: 'kulak', emoji: '👂'),
    WordPair(english: 'mouth', turkish: 'ağız', emoji: '👄'),
    WordPair(english: 'nose', turkish: 'burun', emoji: '👃'),
    WordPair(english: 'hair', turkish: 'saç', emoji: '💇'),
    WordPair(english: 'tooth', turkish: 'diş', emoji: '🦷'),
    WordPair(english: 'finger', turkish: 'parmak', emoji: '👆'),
    WordPair(english: 'foot', turkish: 'ayak', emoji: '🦶'),
    WordPair(english: 'arm', turkish: 'kol', emoji: '💪'),
    WordPair(english: 'back', turkish: 'sırt', emoji: '🫂'),
    WordPair(english: 'heart', turkish: 'kalp', emoji: '❤️'),
    WordPair(english: 'brain', turkish: 'beyin', emoji: '🧠'),

    // Sayılar ve Matematik (15 kelime)
    WordPair(english: 'one', turkish: 'bir', emoji: '1️⃣'),
    WordPair(english: 'two', turkish: 'iki', emoji: '2️⃣'),
    WordPair(english: 'three', turkish: 'üç', emoji: '3️⃣'),
    WordPair(english: 'four', turkish: 'dört', emoji: '4️⃣'),
    WordPair(english: 'five', turkish: 'beş', emoji: '5️⃣'),
    WordPair(english: 'six', turkish: 'altı', emoji: '6️⃣'),
    WordPair(english: 'seven', turkish: 'yedi', emoji: '7️⃣'),
    WordPair(english: 'eight', turkish: 'sekiz', emoji: '8️⃣'),
    WordPair(english: 'nine', turkish: 'dokuz', emoji: '9️⃣'),
    WordPair(english: 'ten', turkish: 'on', emoji: '🔟'),
    WordPair(english: 'plus', turkish: 'artı', emoji: '➕'),
    WordPair(english: 'minus', turkish: 'eksi', emoji: '➖'),
    WordPair(english: 'equal', turkish: 'eşit', emoji: '🟰'),
    WordPair(english: 'circle', turkish: 'daire', emoji: '⭕'),
    WordPair(english: 'square', turkish: 'kare', emoji: '⬜'),
  ];

  WordPair? _currentWord;
  List<BalloonAnswer> _balloons = [];
  int _score = 0;
  int _bombCount = 0;
  int _round = 1;
  int _wordsCompleted = 0; // Tamamlanan kelime sayısı
  int _currentStage = 1; // Mevcut etap (1-10)
  bool _isExploding = false;
  bool _showInfo = true;
  Timer? _balloonMovementTimer;

  // Patlama efekti için
  double _explosionX = 0;
  double _explosionY = 0;
  String _explodedWord = '';

  // Zorluk seviyelerine göre kelime havuzları
  late List<WordPair> _easyWords;
  late List<WordPair> _mediumWords;
  late List<WordPair> _hardWords;
  Set<WordPair> _usedWords = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Kolay: 5 harf ve altı, Orta: 6-7 harf, Zor: 8+ harf
    _easyWords = _allWords.where((w) => w.english.length <= 5).toList();
    _mediumWords = _allWords
        .where((w) => w.english.length > 5 && w.english.length <= 7)
        .toList();
    _hardWords = _allWords.where((w) => w.english.length > 7).toList();
    _startNewGame();
  }

  void _initializeAnimations() {
    _balloonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _explosionScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _explosionController,
      curve: Curves.elasticOut,
    ));
  }

  void _startNewGame() {
    setState(() {
      _score = 0;
      _bombCount = 0;
      _round = 1;
      _wordsCompleted = 0;
      _currentStage = 1;
      _isExploding = false;
      _showInfo = true;
      _usedWords.clear();
    });
  }

  void _startGame() {
    setState(() {
      _showInfo = false;
    });
    if (mounted) {
      _getRandomWord();
      _generateBalloonsInCenterSquare();
      _startBalloonMovement();
    }
  }

  void _startBalloonMovement() {
    _balloonMovementTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && !_isExploding) {
        _updateBalloonPositions();
      }
    });
  }

  void _updateBalloonPositions() {
    setState(() {
      const double balloonSize = 60.0;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height * 0.6;
      final squareSize =
          screenWidth < screenHeight ? screenWidth * 0.6 : screenHeight * 0.6;
      final squareLeft = (screenWidth - squareSize) / 2;
      final squareTop = (screenHeight - squareSize) / 2;
      for (int i = 0; i < _balloons.length; i++) {
        var balloon = _balloons[i];
        double oldX = balloon.x;
        double oldY = balloon.y;
        double newX = balloon.x + balloon.dx;
        double newY = balloon.y + balloon.dy;
        // Kare sınırlarında sektirme
        if (newX <= squareLeft) {
          newX = squareLeft;
          balloon.dx = -balloon.dx;
        } else if (newX >= squareLeft + squareSize - balloonSize) {
          newX = squareLeft + squareSize - balloonSize;
          balloon.dx = -balloon.dx;
        }
        if (newY <= squareTop) {
          newY = squareTop;
          balloon.dy = -balloon.dy;
        } else if (newY >= squareTop + squareSize - balloonSize) {
          newY = squareTop + squareSize - balloonSize;
          balloon.dy = -balloon.dy;
        }
        // Çakışma kontrolü
        bool hasCollision = false;
        for (int j = 0; j < _balloons.length; j++) {
          if (i == j) continue;
          var other = _balloons[j];
          double dist = _calculateDistance(newX, newY, other.x, other.y);
          if (dist < balloonSize + 4) {
            hasCollision = true;
            break;
          }
        }
        if (!hasCollision) {
          balloon.x = newX;
          balloon.y = newY;
        } else {
          balloon.dx = -balloon.dx;
          balloon.dy = -balloon.dy;
          balloon.x = oldX;
          balloon.y = oldY;
        }
      }
    });
  }

  void _getRandomWord() {
    final random = Random();
    List<WordPair> pool;
    // Zorluk: 1-3 kolay, 4-7 orta, 8-10 zor
    if (_currentStage <= 3) {
      pool = _easyWords.where((w) => !_usedWords.contains(w)).toList();
    } else if (_currentStage <= 7) {
      pool = _mediumWords.where((w) => !_usedWords.contains(w)).toList();
    } else {
      pool = _hardWords.where((w) => !_usedWords.contains(w)).toList();
    }
    // Eğer havuz biterse tüm kelimelerden seç
    if (pool.isEmpty) {
      pool = _allWords.where((w) => !_usedWords.contains(w)).toList();
    }
    if (pool.isEmpty) {
      // Tüm kelimeler kullanıldıysa sıfırla
      _usedWords.clear();
      pool = _allWords;
    }
    _currentWord = pool[random.nextInt(pool.length)];
    _usedWords.add(_currentWord!);
  }

  // 1. Balon oluşturma fonksiyonu (kullanım için örnek):
  BalloonAnswer createBalloon({
    required String word,
    required String emoji,
    required bool isCorrect,
    double? customDx,
    double? customDy,
  }) {
    final random = Random();
    return BalloonAnswer(
      word: word,
      emoji: emoji,
      isCorrect: isCorrect,
      x: 0.1 + random.nextDouble() * 0.8,
      y: 0.1 + random.nextDouble() * 0.8,
      dx: customDx ?? (random.nextDouble() - 0.5) * 0.04,
      dy: customDy ?? (random.nextDouble() - 0.5) * 0.04,
    );
  }

  // 2. _generateBalloons fonksiyonu:
  void _generateBalloonsInCenterSquare() {
    if (_currentWord == null) return;
    final random = Random();
    final wrongWords = List<WordPair>.from(_allWords);
    wrongWords.remove(_currentWord!);
    wrongWords.shuffle(random);
    _balloons.clear();
    List<BalloonAnswer> newBalloons = [];
    Set<String> usedWords = {_currentWord!.turkish};
    // 1 doğru + 3 farklı yanlış kelime
    List<WordPair> balloonWords = [_currentWord!];
    int i = 0;
    while (balloonWords.length < 4 && i < wrongWords.length) {
      if (!usedWords.contains(wrongWords[i].turkish)) {
        balloonWords.add(wrongWords[i]);
        usedWords.add(wrongWords[i].turkish);
      }
      i++;
    }
    // Kare alan boyutu
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height * 0.6;
    final squareSize =
        screenWidth < screenHeight ? screenWidth * 0.6 : screenHeight * 0.6;
    final squareLeft = (screenWidth - squareSize) / 2;
    final squareTop = (screenHeight - squareSize) / 2;
    const double balloonSize = 60.0;
    for (int idx = 0; idx < balloonWords.length; idx++) {
      final wordPair = balloonWords[idx];
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 1000) {
        attempts++;
        double x =
            squareLeft + random.nextDouble() * (squareSize - balloonSize);
        double y = squareTop + random.nextDouble() * (squareSize - balloonSize);
        double dx = (random.nextDouble() - 0.5) * 2.0;
        double dy = (random.nextDouble() - 0.5) * 2.0;
        bool isCorrect = idx == 0;
        bool hasCollision = false;
        for (var b in newBalloons) {
          double dist = _calculateDistance(x, y, b.x, b.y);
          if (dist < balloonSize + 8) {
            hasCollision = true;
            break;
          }
        }
        if (!hasCollision) {
          newBalloons.add(BalloonAnswer(
            word: wordPair.turkish,
            emoji: wordPair.emoji,
            isCorrect: isCorrect,
            x: x,
            y: y,
            dx: dx,
            dy: dy,
          ));
          placed = true;
        }
      }
      if (!placed) {
        newBalloons.add(BalloonAnswer(
          word: wordPair.turkish,
          emoji: wordPair.emoji,
          isCorrect: idx == 0,
          x: squareLeft + random.nextDouble() * (squareSize - balloonSize),
          y: squareTop + random.nextDouble() * (squareSize - balloonSize),
          dx: (random.nextDouble() - 0.5) * 2.0,
          dy: (random.nextDouble() - 0.5) * 2.0,
        ));
      }
    }
    _balloons = newBalloons;
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  }

  void _onBalloonTap(BalloonAnswer balloon) {
    if (_isExploding) return;

    if (balloon.isCorrect) {
      // Doğru cevap
      setState(() {
        _score += 100; // Sabit puan
        _wordsCompleted++;
        _round++;
      });

      // Etap kontrolü
      if (_wordsCompleted >= 10) {
        _showStageCompleteDialog();
      } else {
        // Yeni kelime ve balonlar
        _getRandomWord();
        _generateBalloonsInCenterSquare();
      }
    } else {
      // Yanlış cevap - bomba patlar
      _explodeBalloon(balloon);
    }
  }

  // 3. Yanlış balona basınca yeni yanlış balon ekleme:
  void _explodeBalloon(BalloonAnswer balloon) {
    // Patlama efekti başlat
    setState(() {
      _isExploding = true;
      _bombCount++;

      // Patlama pozisyonu (patlayan balon)
      _explosionX = balloon.x;
      _explosionY = balloon.y;
      _explodedWord = balloon.word;
    });

    _explosionController.forward();

    // Patlayan balonu kaldır
    _balloons.remove(balloon);

    // Yeni yanlış cevap ekle - kullanılmamış kelimelerden seç
    if (_balloons.length < 4) {
      final random = Random();
      final usedWords = _balloons.map((b) => b.word).toList();
      usedWords.add(_currentWord!.turkish);

      // Kullanılmamış kelimeleri bul
      final availableWords = _allWords
          .where((word) =>
              !usedWords.contains(word.turkish) && word != _currentWord)
          .toList();

      if (availableWords.isNotEmpty) {
        final selectedWord =
            availableWords[random.nextInt(availableWords.length)];

        // Hızları daha yüksek ver
        double fastDx = (random.nextDouble() - 0.5) * 3.0;
        double fastDy = (random.nextDouble() - 0.5) * 3.0;
        // Kare alanı hesapla
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height * 0.6;
        final squareSize =
            screenWidth < screenHeight ? screenWidth * 0.6 : screenHeight * 0.6;
        final squareLeft = (screenWidth - squareSize) / 2;
        final squareTop = (screenHeight - squareSize) / 2;
        const double balloonSize = 60.0;
        // Çakışmasız pozisyon bul
        bool placed = false;
        int attempts = 0;
        double x = squareLeft;
        double y = squareTop;
        while (!placed && attempts < 1000) {
          attempts++;
          x = squareLeft + random.nextDouble() * (squareSize - balloonSize);
          y = squareTop + random.nextDouble() * (squareSize - balloonSize);
          bool hasCollision = false;
          for (var b in _balloons) {
            double dist = _calculateDistance(x, y, b.x, b.y);
            if (dist < balloonSize + 8) {
              hasCollision = true;
              break;
            }
          }
          if (!hasCollision) placed = true;
        }
        _balloons.add(BalloonAnswer(
          word: selectedWord.turkish,
          emoji: selectedWord.emoji,
          isCorrect: false,
          x: x,
          y: y,
          dx: fastDx,
          dy: fastDy,
        ));
      }
    }

    // Patlama animasyonu bittikten sonra
    Timer(const Duration(milliseconds: 800), () {
      setState(() {
        _isExploding = false;
      });
      _explosionController.reset();
    });
  }

  void _showStageCompleteDialog() {
    final bool finishedAll = _currentStage >= 10;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(finishedAll
            ? '🎉 Tüm Seviyeler Tamamlandı!'
            : '🎉 Etap $_currentStage Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(finishedAll
                ? 'Tebrikler! Tüm etapları başarıyla tamamladın.'
                : 'Tebrikler! 10 kelimeyi başarıyla tamamladın.'),
            const SizedBox(height: 16),
            _buildResultRow('⭐ Toplam Puan', '$_score'),
            _buildResultRow('💣 Patlama', '$_bombCount'),
            _buildResultRow('🎯 Kelime Sayısı', '$_wordsCompleted'),
            _buildResultRow('📚 Tamamlanan Etap', '$_currentStage/10'),
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
                    finishedAll
                        ? 'Tüm etap bonusları eklendi!'
                        : 'Etap bonusu: +${_currentStage * 200} puan!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (finishedAll) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏆 Final İstatistikleri:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Toplam Tamamlanan Kelime: ${_currentStage * 10}'),
                    Text('Toplam Puan: $_score'),
                    Text('Toplam Patlama: $_bombCount'),
                    Text('Tamamlanan Etap: $_currentStage'),
                  ],
                ),
              ),
            ],
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
          if (!finishedAll)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startNextStage();
              },
              child: const Text('Sonraki Etap'),
            ),
        ],
      ),
    );
  }

  void _startNextStage() {
    setState(() {
      _currentStage++;
      _wordsCompleted = 0;
      _bombCount = 0;
      _round = 1;
    });
    _usedWords.clear();
    // Yeni kelime ve balonlar
    _getRandomWord();
    _generateBalloonsInCenterSquare();
  }

  void _endGame() {
    _balloonMovementTimer?.cancel();

    // Profil güncelleme
    final updatedProfile = widget.profile.copyWith(
      points: widget.profile.points + _score,
    );

    _showGameOverDialog(updatedProfile);
  }

  void _showGameOverDialog(UserProfile updatedProfile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('💣 Oyun Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bomba patladı!'),
            const SizedBox(height: 16),
            _buildResultRow('🎯 Tur', '$_round'),
            _buildResultRow('💣 Patlama', '$_bombCount'),
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
              _startNewGame();
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

  @override
  void dispose() {
    _balloonAnimationController.dispose();
    _explosionController.dispose();
    _balloonMovementTimer?.cancel();
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
            Colors.red.shade900,
            Colors.red.shade400,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Başlık
              const Text(
                '💣 Word Bomb',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İngilizce Öğrenme Oyunu',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 30),

              // Oyun Kuralları
              _buildInfoSection(
                '🎯 Oyun Kuralları',
                [
                  '• Üstteki İngilizce kelimenin Türkçe karşılığını bul',
                  '• Doğru balona tıkla, puan kazan',
                  '• Yanlış balona tıklarsan bomba patlar!',
                  '• Amaç: Bombayı patlatmadan tüm kelimeleri bil',
                ],
              ),

              const SizedBox(height: 20),

              // Puanlama Sistemi
              _buildInfoSection(
                '⭐ Puanlama Sistemi',
                [
                  '• Doğru cevap: +100 puan',
                  '• Her etap bonusu: +200 puan',
                  '• 10 kelime tamamlayınca etap biter',
                  '• Toplam 10 etap var',
                ],
              ),

              const SizedBox(height: 20),

              // İpuçları
              _buildInfoSection(
                '💡 İpuçları',
                [
                  '• Balonlar sürekli hareket eder',
                  '• Acele etme, doğru kelimeyi bul',
                  '• Emoji ipucu olarak kullanılabilir',
                  '• Yanlış cevap verince yeni balon eklenir',
                ],
              ),

              const SizedBox(height: 20),

              // Kelime Kategorileri
              _buildInfoSection(
                '📚 Kelime Kategorileri',
                [
                  '• Meyveler ve Yiyecekler',
                  '• Hayvanlar',
                  '• Ev ve Ulaşım',
                  '• Okul ve Eğitim',
                  '• Renkler ve Sıfatlar',
                  '• Duygular ve Değerler',
                  '• Meslekler',
                  '• Spor ve Oyun',
                  '• Vücut ve Sağlık',
                  '• Sayılar ve Matematik',
                ],
              ),

              const SizedBox(height: 30),

              // Başla Butonu
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '🎮 Oyunu Başlat',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
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
            Colors.indigo.shade500,
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

            // Ana oyun alanı
            Expanded(
              child: Stack(
                children: [
                  // Balonlar
                  if (_balloons.isNotEmpty)
                    ..._balloons.map((balloon) => _buildBalloon(balloon))
                  else
                    const Center(
                      child: Text(
                        'Yükleniyor...',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Patlama efekti
                  if (_isExploding)
                    Positioned(
                      left: _explosionX - 50,
                      top: _explosionY - 50,
                      child: ScaleTransition(
                        scale: _explosionScaleAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.red.shade600,
                                Colors.red.shade900,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.8),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _explodedWord,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bomba alanı
            _buildBombArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '💣 Word Bomb',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'İngilizce kelimeleri öğren, bombadan kaç!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
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

  Widget _buildGameInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('🎯', 'Tur', '$_round'),
          _buildInfoItem('💣', 'Patlama', '$_bombCount'),
          _buildInfoItem('⭐', 'Puan', '$_score'),
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

  // 4. Responsive balon konumlandırma:
  Widget _buildBalloon(BalloonAnswer balloon) {
    return Positioned(
      left: balloon.x,
      top: balloon.y,
      child: GestureDetector(
        onTap: () => _onBalloonTap(balloon),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.blue.shade300,
                Colors.blue.shade600,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              balloon.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBombArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // İngilizce kelime
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              _currentWord?.english.toUpperCase() ?? 'Yükleniyor...',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // Bomba
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.black,
                  Colors.red.shade900,
                  Colors.red.shade700,
                ],
                stops: [0.0, 0.7, 1.0],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.shade400,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.red,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class WordPair {
  final String english;
  final String turkish;
  final String emoji;

  WordPair({
    required this.english,
    required this.turkish,
    required this.emoji,
  });
}

class BalloonAnswer {
  final String word;
  final String emoji;
  final bool isCorrect;
  double x;
  double y;
  double dx;
  double dy;

  BalloonAnswer({
    required this.word,
    required this.emoji,
    required this.isCorrect,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
  });
}
