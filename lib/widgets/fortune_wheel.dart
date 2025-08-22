import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../data/task_data.dart';

class FortuneWheel extends StatefulWidget {
  final Function(Task) onTaskSelected;
  final bool canSpin;

  const FortuneWheel({
    super.key,
    required this.onTaskSelected,
    required this.canSpin,
  });

  @override
  State<FortuneWheel> createState() => _FortuneWheelState();
}

class _FortuneWheelState extends State<FortuneWheel>
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

        // Rastgele görev seç
        final selectedTask = TaskData.getRandomTask();
        widget.onTaskSelected(selectedTask);
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
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF6B35), // Parlak turuncu
                              Color(0xFF8B5CF6), // Canlı mor
                              Color(0xFFF59E0B), // Altın sarısı
                              Color(0xFFEC4899), // Pembe
                              Color(0xFF3B82F6), // Mavi
                              Color(0xFF10B981), // Yeşil
                            ],
                          ),
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
                            // Çark dilimleri
                            ...List.generate(6, (index) {
                              final angle = (index * 60) * 3.14159 / 180;
                              return Transform.rotate(
                                angle: angle,
                                child: Container(
                                  width: 150,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.9),
                                        Colors.white.withValues(alpha: 0.6),
                                        Colors.white.withValues(alpha: 0.3),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
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
                                  Icons.star,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),

                            // Dış halka süslemeleri
                            ...List.generate(12, (index) {
                              final angle = (index * 30) * 3.14159 / 180;
                              return Transform.rotate(
                                angle: angle,
                                child: Positioned(
                                  top: 5,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 3,
                                            spreadRadius: 1,
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
                      _isSpinning ? 'Çeviriliyor...' : 'Çarkı Çevir! 🎯',
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
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.canSpin
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.canSpin ? Colors.green : Colors.grey)
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
                    widget.canSpin ? Icons.celebration : Icons.schedule,
                    color: widget.canSpin ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.canSpin
                          ? 'Bugün henüz çarkı çevirmedin! Şansını dene! 🍀'
                          : 'Bugün çarkı zaten çevirdin! Yarın tekrar dene! ⏰',
                      style: TextStyle(
                        fontSize: 15,
                        color: widget.canSpin ? Colors.green : Colors.grey,
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

        const SizedBox(height: 20),

        // Parçacık efektleri
        if (widget.canSpin)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        const Color(0xFFFF6B35),
                        const Color(0xFF8B5CF6),
                        const Color(0xFFF59E0B),
                        const Color(0xFFEC4899),
                        const Color(0xFF3B82F6),
                      ][index],
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(
                    duration: Duration(milliseconds: 1000 + (index * 200)),
                  );
            }),
          ),
      ],
    );
  }
}
