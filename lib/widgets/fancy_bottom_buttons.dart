import 'package:flutter/material.dart';

import '../services/pixel_service.dart';

class FancyBottomButtons extends StatelessWidget {
  final VoidCallback onWheelTap;
  final VoidCallback onGamesTap;
  final VoidCallback onQuizTap;
  final bool isTaskActive;

  const FancyBottomButtons({
    super.key,
    required this.onWheelTap,
    required this.onGamesTap,
    required this.onQuizTap,
    this.isTaskActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = PixelService.instance.isCompactWidth(context);

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 6, compact ? 6 : 8, 8),
        child: Row(
          children: [
            _FancyButton(
              label: 'Çark',
              icon: Icons.casino,
              colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
              onTap: onWheelTap,
              compact: compact,
            ),
            SizedBox(width: compact ? 6 : 8),
            _FancyButton(
              label: 'Oyun',
              icon: Icons.sports_esports,
              colors: [Colors.lightBlueAccent, Colors.blueAccent],
              onTap: onGamesTap,
              compact: compact,
            ),
            SizedBox(width: compact ? 6 : 8),
            _FancyButton(
              label: 'Quiz',
              icon: Icons.psychology,
              colors: [Colors.orangeAccent, Colors.deepOrange],
              onTap: onQuizTap,
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _FancyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool compact;

  const _FancyButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: compact ? 46 : 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: compact ? 18 : 20),
                      SizedBox(width: compact ? 6 : 8),
                      Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
