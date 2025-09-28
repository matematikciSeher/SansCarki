import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedLoginWheel extends StatefulWidget {
  final double size;
  final Duration entryDuration; // used for slice assembly
  final Duration spinDuration;
  final bool enableIdleSpin;
  final Duration idlePeriod; // one revolution duration for idle rotation
  final List<String>? labels; // optional per-slice labels (<= 8)
  final List<IconData>? icons; // optional per-slice icons (<= 8)
  final TextStyle? labelStyle;
  final double labelRadiusFactor; // distance from center for labels/icons
  final double iconSize;
  final Duration idleRampDuration; // smooth transition into idle speed
  final Duration iconDropDuration; // total duration for sequential icon drops

  const AnimatedLoginWheel({
    super.key,
    this.size = 220,
    this.entryDuration = const Duration(milliseconds: 1200),
    this.spinDuration = const Duration(milliseconds: 1400),
    this.enableIdleSpin = true,
    this.idlePeriod = const Duration(seconds: 18),
    this.labels,
    this.icons,
    this.labelStyle,
    this.labelRadiusFactor = 0.62,
    this.iconSize = 18,
    this.idleRampDuration = const Duration(milliseconds: 800),
    this.iconDropDuration = const Duration(milliseconds: 1600),
  });

  @override
  State<AnimatedLoginWheel> createState() => _AnimatedLoginWheelState();
}

class _AnimatedLoginWheelState extends State<AnimatedLoginWheel>
    with TickerProviderStateMixin {
  static const int _sliceCount = 8;
  late final AnimationController _assembleController;
  late final Ticker _ticker;
  double _angle = 0.0;
  double _omega = 0.0; // current angular velocity (rad/s)
  double _idleOmega = 0.0; // target idle angular velocity (rad/s)
  double _startOmega = 0.0; // starting angular velocity for deceleration
  double _decelElapsed = 0.0; // seconds since decel start
  Duration _lastTick = Duration.zero;
  bool _decelStarted = false;
  late final List<Animation<double>> _sliceProgress;
  late final Animation<double> _capOpacity;
  late final AnimationController _iconDropController;
  List<Animation<double>> _iconDropProgress = [];

  @override
  void initState() {
    super.initState();
    _assembleController = AnimationController(
      vsync: this,
      duration: widget.entryDuration,
    );
    _ticker = createTicker(_onTick);
    _iconDropController = AnimationController(
      vsync: this,
      duration: widget.iconDropDuration,
    );

    // Staggered slice assembly animations (corners first, then edges)
    final List<int> order = const <int>[0, 2, 5, 7, 1, 3, 4, 6];
    final double span = 0.9; // use first 90% for staggering
    final double perSliceStartGap =
        _sliceCount > 1 ? span / (_sliceCount - 1) : 0.0;
    _sliceProgress = List<Animation<double>>.generate(_sliceCount, (int i) {
      final int pos = order.indexOf(i);
      final double start = (pos * perSliceStartGap).clamp(0.0, 1.0);
      final double end = min(1.0, start + 0.25); // each slice animates 25%
      return CurvedAnimation(
        parent: _assembleController,
        curve: Interval(start, end, curve: Curves.elasticOut),
      );
    });

    _capOpacity = CurvedAnimation(
      parent: _assembleController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    _assembleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _idleOmega = (2 * pi) / (widget.idlePeriod.inMilliseconds / 1000.0);
        // High initial speed proportional to requested spinDuration
        _startOmega =
            (2 * pi * 1.8) / (widget.spinDuration.inMilliseconds / 1000.0);
        _omega = _startOmega;
        _decelElapsed = 0.0;
        _decelStarted = true;
        _lastTick = Duration.zero;
        _ticker.start();
        if ((widget.icons?.isNotEmpty ?? false) ||
            (widget.labels?.isNotEmpty ?? false)) {
          _iconDropController.forward(from: 0);
        }
      }
    });
    _assembleController.forward();
  }

  @override
  void dispose() {
    _assembleController.dispose();
    _ticker.dispose();
    _iconDropController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    if (_decelStarted) {
      final double rampSeconds =
          widget.idleRampDuration.inMilliseconds / 1000.0;
      _decelElapsed += dt;
      final double t = (_decelElapsed / rampSeconds).clamp(0.0, 1.0);
      final double k = Curves.easeOutCubic.transform(t);
      _omega = _startOmega + (_idleOmega - _startOmega) * k;
    }

    _angle += _omega * dt;
    if (_angle > 2 * pi) _angle -= 2 * pi;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final double radius = size / 2;
    return Semantics(
      label: 'Giriş çarkı animasyonu',
      child: SizedBox(
        height: size,
        width: size,
        child: AnimatedBuilder(
          animation: _assembleController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _angle,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Subtle background glow
                  CustomPaint(
                    size: Size(size, size),
                    painter: _GlowPainter(),
                  ),
                  // 8 slices arriving from outside and assembling
                  for (int i = 0; i < _sliceCount; i++) _buildSlice(i, radius),
                  // Outer ring and center cap fade in near the end
                  Opacity(
                    opacity: _capOpacity.value,
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _RingAndCapPainter(),
                    ),
                  ),
                  // Optional overlays (labels/icons)
                  if ((widget.labels?.isNotEmpty ?? false) ||
                      (widget.icons?.isNotEmpty ?? false))
                    ..._buildOverlays(radius),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlice(int sliceIndex, double radius) {
    final double sweep = 2 * pi / _sliceCount;
    final double startAngle = sliceIndex * sweep;
    final double progress = _sliceProgress[sliceIndex].value.clamp(0.0, 1.0);

    // Motion path: each slice comes from different screen directions
    // Directions mapped to corners/edges: TL, Top, TR, Left, Right, BL, Bottom, BR
    Offset entryDir = _entryDirectionFor(sliceIndex);
    final double mag =
        sqrt(entryDir.dx * entryDir.dx + entryDir.dy * entryDir.dy);
    if (mag != 0) entryDir = Offset(entryDir.dx / mag, entryDir.dy / mag);

    // Travel distance large enough to start outside widget bounds
    final double travel = radius * 2.6;
    // Slight curved drift using perpendicular to entry direction
    final Offset perp = Offset(-entryDir.dy, entryDir.dx);
    final double drift =
        sin(progress * pi) * radius * 0.28 * (sliceIndex.isEven ? 1.0 : -1.0);
    final Offset offset = entryDir * ((1 - progress) * travel) + perp * drift;

    // A stronger wobble rotation as it arrives
    final double wobbleSign = sliceIndex.isEven ? 1.0 : -1.0;
    final double wobble = (1 - progress) * 0.6 * wobbleSign;

    // Scale and opacity for a more organic arrival
    final double scale = 0.8 + 0.25 * progress;
    final double opacity = progress;

    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: wobble,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              size: Size(radius * 2, radius * 2),
              painter: _SlicePainter(
                startAngle: startAngle,
                sweepAngle: sweep,
                color: _sliceColor(sliceIndex),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _entryDirectionFor(int i) {
    switch (i % _sliceCount) {
      case 0:
        return const Offset(-1, -1); // top-left
      case 1:
        return const Offset(0, -1); // top
      case 2:
        return const Offset(1, -1); // top-right
      case 3:
        return const Offset(-1, 0); // left
      case 4:
        return const Offset(1, 0); // right
      case 5:
        return const Offset(-1, 1); // bottom-left
      case 6:
        return const Offset(0, 1); // bottom
      default:
        return const Offset(1, 1); // bottom-right
    }
  }

  List<Widget> _buildOverlays(double radius) {
    final List<Widget> widgets = <Widget>[];
    final int count = _sliceCount;
    final double sweep = 2 * pi / count;
    final double r = radius * widget.labelRadiusFactor;
    // prepare per-slice drop animations with equal spacing
    _iconDropProgress = _iconDropProgress.isNotEmpty
        ? _iconDropProgress
        : List<Animation<double>>.generate(count, (int i) {
            final double gap = 1.0 / count;
            final double start = i * gap;
            final double end = (start + gap * 0.8).clamp(0.0, 1.0);
            return CurvedAnimation(
              parent: _iconDropController,
              curve: Interval(start, end, curve: Curves.easeInCubic),
            );
          });
    for (int i = 0; i < count; i++) {
      final double angle = i * sweep + sweep / 2;
      final Offset pos = Offset(cos(angle) * r, sin(angle) * r);

      final String? label = (widget.labels != null && i < widget.labels!.length)
          ? widget.labels![i]
          : null;
      final IconData? icon = (widget.icons != null && i < widget.icons!.length)
          ? widget.icons![i]
          : null;
      if (label == null && icon == null) continue;

      final double p =
          (_iconDropProgress.isNotEmpty ? _iconDropProgress[i].value : 0.0)
              .clamp(0.0, 1.0);
      // gravity-like easing for vertical fall
      final double fall = Curves.easeInCubic.transform(p);
      // start higher for sky-like effect
      final Offset dropOffset = Offset(
        pos.dx,
        lerpDouble(-radius * 2.2, pos.dy, fall)!,
      );
      // slight rotation that settles as it lands
      final double dropRot = (1.0 - p) * 0.6 * (i.isEven ? 1.0 : -1.0);
      widgets.add(
        Transform.translate(
          offset: dropOffset,
          child: Opacity(
            opacity: p,
            child: Transform.rotate(
              angle: angle + pi / 2 + dropRot,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    Icon(icon, size: widget.iconSize, color: Colors.white),
                  if (label != null)
                    Text(
                      label,
                      style: widget.labelStyle ??
                          const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 2)
                            ],
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Color _sliceColor(int i) {
    const List<Color> colors = <Color>[
      Color(0xFFF44336), // red
      Color(0xFFFF9800), // orange
      Color(0xFFFFEB3B), // yellow
      Color(0xFF8BC34A), // green
      Color(0xFF00BCD4), // cyan
      Color(0xFF3F51B5), // indigo
      Color(0xFFE91E63), // pink
      Color(0xFF9C27B0), // purple
    ];
    return colors[i % colors.length];
  }
}

class _SlicePainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final Color color;

  _SlicePainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = min(size.width, size.height) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawArc(rect, startAngle, sweepAngle, true, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SlicePainter oldDelegate) {
    return oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.color != color;
  }
}

class _RingAndCapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = min(size.width, size.height) / 2;

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..color = Colors.black.withOpacity(0.15);
    canvas.drawCircle(center, radius * 0.98, ring);

    final Rect capRect = Rect.fromCircle(center: center, radius: radius * 0.18);
    final Paint inner = Paint()
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF7C4DFF), // Deep purple accent
          Color(0xFFE040FB), // Purple A200
          Color(0xFFFF80AB), // Pink A100
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(capRect);
    canvas.drawCircle(center, radius * 0.18, inner);
  }

  @override
  bool shouldRepaint(covariant _RingAndCapPainter oldDelegate) => false;
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = min(size.width, size.height) / 2;
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.deepPurple.withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.25));
    canvas.drawCircle(center, radius * 1.15, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => false;
}
