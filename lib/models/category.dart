import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String description;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
  });
}

class CategoryData {
  static List<Category> getAllCategories() {
    return [
      const Category(
        id: 'beden_egitimi',
        name: 'Beden Eğitimi',
        emoji: '🏃‍♂️',
        color: Color(0xFF10B981),
        description: 'Hareket ve spor aktiviteleri',
      ),
      const Category(
        id: 'muzik',
        name: 'Müzik',
        emoji: '🎵',
        color: Color(0xFF3B82F6),
        description: 'Müzik ve ses aktiviteleri',
      ),
      const Category(
        id: 'eglence',
        name: 'Eğlence',
        emoji: '🎭',
        color: Color(0xFFEC4899),
        description: 'Eğlenceli ve komik aktiviteler',
      ),
      const Category(
        id: 'yaraticilik',
        name: 'Yaratıcılık',
        emoji: '🎨',
        color: Color(0xFF8B5CF6),
        description: 'Sanat ve yaratıcı aktiviteler',
      ),
      const Category(
        id: 'sosyal',
        name: 'Sosyal',
        emoji: '🤝',
        color: Color(0xFFF59E0B),
        description: 'Sosyal etkileşim aktiviteleri',
      ),
      const Category(
        id: 'bilim',
        name: 'Bilim',
        emoji: '🔬',
        color: Color(0xFFEF4444),
        description: 'Bilimsel ve keşif aktiviteleri',
      ),
    ];
  }

  static Category getCategoryById(String id) {
    return getAllCategories().firstWhere((category) => category.id == id);
  }
}
