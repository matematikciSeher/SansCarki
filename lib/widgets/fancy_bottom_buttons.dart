import 'package:flutter/material.dart';

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
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Row(
          children: [
            _FancyButton(
              label: 'Çark',
              icon: Icons.casino,
              colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
              onTap: onWheelTap,
            ),
            const SizedBox(width: 4),
            _FancyButton(
              label: 'Oyun',
              icon: Icons.sports_esports,
              colors: [Colors.lightBlueAccent, Colors.blueAccent],
              onTap: onGamesTap,
            ),
            const SizedBox(width: 4),
            _FancyButton(
              label: 'Quiz',
              icon: Icons.psychology,
              colors: [Colors.orangeAccent, Colors.deepOrange],
              onTap: onQuizTap,
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

  const _FancyButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
