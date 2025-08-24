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
        id: 'kitap',
        name: 'Kitap & Okuma',
        emoji: '📚',
        color: Color(0xFFEF476F), // canlı pembe
        description: 'Kitap okuma ve hikaye görevleri',
      ),
      const Category(
        id: 'yazma',
        name: 'Yazma & Günlük',
        emoji: '✍️',
        color: Color(0xFF06D6A0), // canlı yeşil
        description: 'Yazma, günlük ve hikaye görevleri',
      ),
      const Category(
        id: 'matematik',
        name: 'Matematik',
        emoji: '🔢',
        color: Color(0xFFFFD166), // canlı sarı
        description: 'Matematik ve sayı görevleri',
      ),
      const Category(
        id: 'fen',
        name: 'Fen Bilimleri',
        emoji: '🌍',
        color: Color(0xFF118AB2), // canlı mavi
        description: 'Fen ve doğa gözlemleri',
      ),
      const Category(
        id: 'spor',
        name: 'Spor & Hareket',
        emoji: '🏃‍♀️',
        color: Color(0xFFFB5607), // canlı turuncu
        description: 'Spor ve hareket görevleri',
      ),
      const Category(
        id: 'sanat',
        name: 'Sanat & Yaratıcılık',
        emoji: '🎨',
        color: Color(0xFF8338EC), // canlı mor
        description: 'Sanat ve yaratıcı görevler',
      ),
      const Category(
        id: 'muzik',
        name: 'Müzik',
        emoji: '🎵',
        color: Color(0xFF3A86FF), // canlı mavi
        description: 'Müzik ve ritim görevleri',
      ),
      const Category(
        id: 'teknoloji',
        name: 'Teknoloji',
        emoji: '💻',
        color: Color(0xFF00B4D8), // canlı camgöbeği
        description: 'Teknoloji ve dijital görevler',
      ),
      const Category(
        id: 'iyilik',
        name: 'İyilik & Sosyal',
        emoji: '❤️',
        color: Color(0xFFFF006E), // canlı kırmızı
        description: 'İyilik ve sosyal sorumluluk',
      ),
      const Category(
        id: 'ev',
        name: 'Ev & Günlük Yaşam',
        emoji: '🏡',
        color: Color(0xFF9D0208), // canlı koyu kırmızı
        description: 'Ev ve günlük yaşam görevleri',
      ),
      const Category(
        id: 'oyun',
        name: 'Eğlenceli Oyun',
        emoji: '🎲',
        color: Color(0xFFFB8500), // canlı turuncu
        description: 'Oyun ve eğlenceli görevler',
      ),
      const Category(
        id: 'zihin',
        name: 'Zihin Egzersizi',
        emoji: '🧘',
        color: Color(0xFF43AA8B), // canlı yeşil
        description: 'Düşünme ve zihin egzersizleri',
      ),
    ];
  }

  static Category getCategoryById(String id) {
    return getAllCategories().firstWhere((category) => category.id == id);
  }
}
