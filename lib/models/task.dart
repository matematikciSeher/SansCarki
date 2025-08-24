import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final int basePoints;
  final String? specialBadge;
  final String emoji;
  final bool isCompleted;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.basePoints,
    this.specialBadge,
    required this.emoji,
    this.isCompleted = false,
    this.completedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    TaskDifficulty? difficulty,
    int? basePoints,
    String? specialBadge,
    String? emoji,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      basePoints: basePoints ?? this.basePoints,
      specialBadge: specialBadge ?? this.specialBadge,
      emoji: emoji ?? this.emoji,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'difficulty': difficulty.toString(),
      'basePoints': basePoints,
      'specialBadge': specialBadge,
      'emoji': emoji,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: TaskCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => TaskCategory.other,
      ),
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => TaskDifficulty.easy,
      ),
      basePoints: json['basePoints'] ?? 10,
      specialBadge: json['specialBadge'],
      emoji: json['emoji'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

enum TaskCategory {
  kitap,
  yazma,
  matematik,
  fen,
  spor,
  sanat,
  muzik,
  teknoloji,
  iyilik,
  ev,
  oyun,
  zihin,
  other,
}

enum TaskDifficulty {
  easy, // 5-10 puan
  medium, // 15-25 puan
  hard, // 30-50 puan
  expert // 75-100 puan + direkt rozet
}

extension TaskDifficultyExtension on TaskDifficulty {
  String get displayName {
    switch (this) {
      case TaskDifficulty.easy:
        return 'Kolay';
      case TaskDifficulty.medium:
        return 'Orta';
      case TaskDifficulty.hard:
        return 'Zor';
      case TaskDifficulty.expert:
        return 'Uzman';
    }
  }

  Color get color {
    switch (this) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.expert:
        return Colors.purple;
    }
  }

  int get minPoints {
    switch (this) {
      case TaskDifficulty.easy:
        return 5;
      case TaskDifficulty.medium:
        return 15;
      case TaskDifficulty.hard:
        return 30;
      case TaskDifficulty.expert:
        return 75;
    }
  }

  int get maxPoints {
    switch (this) {
      case TaskDifficulty.easy:
        return 10;
      case TaskDifficulty.medium:
        return 25;
      case TaskDifficulty.hard:
        return 50;
      case TaskDifficulty.expert:
        return 100;
    }
  }
}

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.kitap:
        return 'Kitap & Okuma';
      case TaskCategory.yazma:
        return 'Yazma & Günlük';
      case TaskCategory.matematik:
        return 'Matematik';
      case TaskCategory.fen:
        return 'Fen Bilimleri';
      case TaskCategory.spor:
        return 'Spor & Hareket';
      case TaskCategory.sanat:
        return 'Sanat & Yaratıcılık';
      case TaskCategory.muzik:
        return 'Müzik';
      case TaskCategory.teknoloji:
        return 'Teknoloji';
      case TaskCategory.iyilik:
        return 'İyilik & Sosyal';
      case TaskCategory.ev:
        return 'Ev & Günlük Yaşam';
      case TaskCategory.oyun:
        return 'Eğlenceli Oyun';
      case TaskCategory.zihin:
        return 'Zihin Egzersizi';
      case TaskCategory.other:
        return 'Diğer';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.kitap:
        return Color(0xFFEF476F);
      case TaskCategory.yazma:
        return Color(0xFF06D6A0);
      case TaskCategory.matematik:
        return Color(0xFFFFD166);
      case TaskCategory.fen:
        return Color(0xFF118AB2);
      case TaskCategory.spor:
        return Color(0xFFFB5607);
      case TaskCategory.sanat:
        return Color(0xFF8338EC);
      case TaskCategory.muzik:
        return Color(0xFF3A86FF);
      case TaskCategory.teknoloji:
        return Color(0xFF00B4D8);
      case TaskCategory.iyilik:
        return Color(0xFFFF006E);
      case TaskCategory.ev:
        return Color(0xFF9D0208);
      case TaskCategory.oyun:
        return Color(0xFFFB8500);
      case TaskCategory.zihin:
        return Color(0xFF43AA8B);
      case TaskCategory.other:
        return Colors.grey;
    }
  }
}
