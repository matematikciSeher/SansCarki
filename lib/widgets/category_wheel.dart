import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/category.dart';
import '../data/category_tasks.dart';

class CategoryWheel extends StatefulWidget {
  final Function(Category) onCategorySelected;
  final bool canSpin;

  const CategoryWheel({
    super.key,
    required this.onCategorySelected,
    required this.canSpin,
  });

  @override
  State<CategoryWheel> createState() => _CategoryWheelState();
}

class _CategoryWheelState extends State<CategoryWheel>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  bool _isSpinning = false;
  double _currentRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOutCubic),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _rotationController.addListener(() {
      setState(() {
        _currentRotation = _rotationAnimation.value * 720 + _currentRotation;
      });
    });

    _rotationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });

        // Rastgele kategori seç
        final categories = CategoryData.getAllCategories();
        final random =
            DateTime.now().millisecondsSinceEpoch % categories.length;
        final selectedCategory = categories[random];
        widget.onCategorySelected(selectedCategory);
      }
    });

    // Sürekli glow animasyonu
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning || !widget.canSpin) return;

    setState(() {
      _isSpinning = true;
    });

    _rotationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryData.getAllCategories();

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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dış glow efekti
                  Transform.scale(
                    scale: 1.1 + (_glowAnimation.value * 0.1),
                    child: Container(
                      width: 320,
                      height: 320,
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

                  // Ana çark
                  Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Transform.rotate(
                      angle: _currentRotation * 3.14159 / 180,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Kategori dilimleri
                            ...List.generate(categories.length, (index) {
                              final category = categories[index];
                              final angle =
                                  (index * (360 / categories.length)) *
                                  3.14159 /
                                  180;
                              final sliceAngle =
                                  (360 / categories.length) * 3.14159 / 180;

                              return Transform.rotate(
                                angle: angle,
                                child: CustomPaint(
                                  size: const Size(300, 300),
                                  painter: CategorySlicePainter(
                                    color: category.color,
                                    startAngle: 0,
                                    sweepAngle: sliceAngle,
                                  ),
                                ),
                              );
                            }),

                            // İç halka
                            Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Color(0xFFF3F4F6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Merkez ikonu
                            Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF6B35),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.category,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),

                            // Kategori etiketleri
                            ...List.generate(categories.length, (index) {
                              final category = categories[index];
                              final angle =
                                  (index * (360 / categories.length) +
                                      (360 / categories.length / 2)) *
                                  3.14159 /
                                  180;
                              final radius = 120.0;

                              return Transform.rotate(
                                angle: angle,
                                child: Positioned(
                                  top: 150 - radius * 0.5,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Transform.rotate(
                                      angle: -angle,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            category.emoji,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            category.name,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Ok işareti
                  Positioned(
                    top: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 0,
                        height: 0,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.white, width: 0),
                            right: BorderSide(color: Colors.white, width: 0),
                            bottom: BorderSide(color: Colors.white, width: 25),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Ok gölgesi
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 0,
                        height: 0,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.black.withValues(alpha: 0.3),
                              width: 0,
                            ),
                            right: BorderSide(
                              color: Colors.black.withValues(alpha: 0.3),
                              width: 0,
                            ),
                            bottom: BorderSide(
                              color: Colors.black.withValues(alpha: 0.3),
                              width: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(
              begin: const Offset(0.3, 0.3),
              duration: 800.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 40),

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
                    borderRadius: BorderRadius.circular(30),
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
                    const SizedBox(width: 12),
                    Text(
                      _isSpinning ? 'Çeviriliyor...' : 'Kategori Seç! 🎯',
                      style: const TextStyle(
                        fontSize: 18,
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

        const SizedBox(height: 25),

        // Bilgi kartı
        Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: widget.canSpin
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.canSpin
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.canSpin ? Colors.blue : Colors.grey)
                        .withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.canSpin ? Icons.category : Icons.schedule,
                    color: widget.canSpin ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.canSpin
                          ? 'Önce bir kategori seç, sonra görev çarkını çevir! 🎯'
                          : 'Bugün kategori seçimi yapıldı! Yarın tekrar dene! ⏰',
                      style: TextStyle(
                        fontSize: 15,
                        color: widget.canSpin ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 700.ms)
            .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
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
