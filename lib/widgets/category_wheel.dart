import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../models/category.dart';

class CategoryWheel extends StatefulWidget {
  final Function(Category) onCategorySelected;
  final bool canSpin;
  final Set<String>? eligibleCategoryIds;

  const CategoryWheel({
    super.key,
    required this.onCategorySelected,
    required this.canSpin,
    this.eligibleCategoryIds,
  });

  @override
  State<CategoryWheel> createState() => _CategoryWheelState();
}

class _CategoryWheelState extends State<CategoryWheel>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late StreamController<int> _selectedController;
  bool _isSpinning = false;
  int _currentSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedController = StreamController<int>();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Sürekli glow animasyonu
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _selectedController.close();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning || !widget.canSpin) return;

    setState(() {
      _isSpinning = true;
    });

    final categories = CategoryData.getAllCategories(); // 12 kategori

    // Uygun kategoriler arasından rastgele seçim (cooldown'a saygılı)
    final eligible = widget.eligibleCategoryIds;
    List<int> eligibleIndexes = [];
    for (int i = 0; i < categories.length; i++) {
      if (eligible == null ||
          eligible.isEmpty ||
          eligible.contains(categories[i].id)) {
        eligibleIndexes.add(i);
      }
    }
    if (eligibleIndexes.isEmpty) {
      eligibleIndexes = List<int>.generate(categories.length, (i) => i);
    }
    _currentSelectedIndex =
        eligibleIndexes[Random().nextInt(eligibleIndexes.length)];

    _selectedController.add(_currentSelectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        CategoryData.getAllCategories(); // Sadece 12 kategori, tekrar yok

    // Ekran boyutuna göre çark boyutu (piksel taşmalarını azaltmak için kısıtla)
    final screenWidth = MediaQuery.of(context).size.width;
    final double wheelSize = () {
      final proposed = screenWidth * 0.8;
      if (proposed < 220) return 220.0;
      if (proposed > 340) return 340.0;
      return proposed.toDouble();
    }();

    return Column(
      children: [
        // Ana çark container'ı
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(200),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dış glow efekti
              Transform.scale(
                scale: 1.1 + (_glowAnimation.value * 0.1),
                child: Container(
                  width: wheelSize + 20,
                  height: wheelSize + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.3),
                        Colors.purple.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Ana çark (paket ile)
              Transform.scale(
                scale: _bounceAnimation.value,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(wheelSize / 2),
                  child: SizedBox(
                    width: wheelSize,
                    height: wheelSize,
                    child: FortuneWheel(
                      animateFirst: false,
                      selected: _selectedController.stream,
                      duration: const Duration(milliseconds: 7000),
                      curve: Curves.easeOutQuint,
                      onAnimationEnd: () {
                        setState(() {
                          _isSpinning = false;
                        });
                        final categories = CategoryData.getAllCategories();
                        widget.onCategorySelected(
                            categories[_currentSelectedIndex]);
                        _bounceController
                            .forward()
                            .then((_) => _bounceController.reverse());
                      },
                      indicators: const <FortuneIndicator>[
                        FortuneIndicator(
                          alignment: Alignment.topCenter,
                          child: TriangleIndicator(color: Colors.white),
                        ),
                      ],
                      items: [
                        for (final category in categories)
                          FortuneItem(
                            style: FortuneItemStyle(
                              color: category.color,
                              borderColor: Colors.white,
                              borderWidth: 2,
                              textAlign: TextAlign.center,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(category.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black,
                                            offset: Offset(1, 1),
                                            blurRadius: 2),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Gösterge Fury paketinden geldiği için manuel ok kaldırıldı
            ],
          ),
        ).animate().fadeIn(duration: 800.ms).scale(
              begin: const Offset(0.3, 0.3),
              duration: 800.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 1),

        // Spin butonu
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.canSpin
                  ? [const Color(0xFFFF6B35), const Color(0xFF8B5CF6)]
                  : [
                      Colors.grey.withValues(alpha: 0.5),
                      Colors.grey.withValues(alpha: 0.3),
                    ],
            ),
            boxShadow: widget.canSpin
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: widget.canSpin && !_isSpinning ? _spinWheel : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSpinning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.casino, size: 24),
                const SizedBox(width: 22),
                Text(
                  _isSpinning ? 'Çeviriliyor...' : 'Kategori Seç! 🎯',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms)
            .slideY(begin: 0.5, duration: 700.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 5),

        // Bilgi kartı
      ],
    );
  }
}

// Kategori dilimi çizimi için CustomPainter
class CategorySlicePainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;

  CategorySlicePainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
